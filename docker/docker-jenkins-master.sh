#!/usr/bin/env bash

#
# jenkins master in docker with...
# - bind to host network
# - privileged container
# - a volume for jenkins home
# - docker group
# - docker socket volume mount
# - jenkins user docker access
#

set -eu

jenkins_home_vol="jenkins_home"
jenkins_home_mount="/var/jenkins_home"
jenkins_image="jenkins/jenkins:lts"
jenkins_name="jenkins"
jenkins_user="jenkins"

docker_url="https://get.docker.com/"
docker_script="/tmp/get-docker.sh"
docker_group="docker"
docker_gid="$(getent group ${docker_group} | cut -f3 -d:)"
docker_sock="/var/run/docker.sock"

sleep_time="30"

if ! $(docker volume inspect "${jenkins_home_vol}" >/dev/null 2>&1) ; then
  docker volume create "${jenkins_home_vol}"
fi

docker pull "${jenkins_image}"

docker run \
  --detach \
  --name "${jenkins_name}" \
  --env JENKINS_OPTS="--sessionEviction=-1 --sessionTimeout=$((366*24*60))" \
  --env JAVA_OPTS="-DexecutableWar.jetty.disableCustomSeesionIdCookieName=true -DexecutableWar.jetty.sessionIdCookieName=JSESSIONID.$(hostname -s)" \
  --network host \
  --privileged \
  --volume "${jenkins_home_vol}:${jenkins_home_mount}" \
  --volume "${docker_sock}:${docker_sock}" \
  --restart always \
    "${jenkins_image}"

echo "sleeping for ${sleep_time} seconds while jenkins starts"
sleep "${sleep_time}"

echo "installing some packages"
docker exec -it --user root "${jenkins_name}" apt-get update
docker exec -it --user root "${jenkins_name}" apt-get install -y file less lsof net-tools psmisc which

echo "installing docker and restarting jenkins"
docker exec -it --user root "${jenkins_name}" groupadd -g "${docker_gid}" "${docker_group}"
docker exec -it --user root "${jenkins_name}" usermod -a -G "${docker_group}" "${jenkins_user}"
docker exec -it --user root "${jenkins_name}" curl -kLo "${docker_script}" "${docker_url}"
docker exec -it --user root "${jenkins_name}" env CHANNEL=stable bash "${docker_script}"

if ! $(docker logs "${jenkins_name}" 2>&1 | grep -q "Jenkins initial setup is required") ; then
  if $(docker logs "${jenkins_name}" 2>&1 | grep -q "Jenkins is fully up and running") ; then
    echo "restarting ${jenkins_name}"
    docker restart "${jenkins_name}"
  fi
else
  echo "please configure jenkins and restart the ${jenkins_name} container to pick up the new docker installation"
fi
