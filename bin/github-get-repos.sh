#!/bin/bash

#
# used github api to list org or user repositories
#
# github, in their infinite wisdom, uses a "Link:" header to specify next/last page(s)
# bitbucket has isLastPage/nextPageStart in their api output
# why, github, why?
#
# docs:
# - https://developer.github.com/v3/repos/
# - https://developer.github.com/v3/auth/
# - https://help.github.com/en/articles/creating-a-personal-access-token-for-the-command-line
#
# reqs:
# - bash : https://www.gnu.org/software/bash
# - curl : https://curl.haxx.se and https://github.com/curl/curl
# - jq : https://stedolan.github.io/jq and https://github.com/stedolan/jq
# - dos2unix : http://waterlan.home.xs4all.nl/dos2unix.html (or busybox/toybox)
# - jo : https://jpmens.net/2016/03/05/a-shell-command-to-create-json-jo/ and https://github.com/jpmens/jo
#

set -eu

: ${gtoken:="${HOME}/.github/token"}

function usage() {
  echo "$(basename "${BASH_SOURCE[0]}") usage:" 1>&2
  echo "  please provide exactly zero or one arguments for reposity listing" 1>&2
  echo "    the argument form should be one of:" 1>&2
  echo "    - <empty> : list user-owned repos (requires token in ${gtoken})" 1>&2
  echo "    - user : users/username" 1>&2
  echo "    - organization : orgs/orgname" 1>&2
}

if [ ${#} -eq 0 ] ; then
  echo "no argument provided, default to user repos" 1>&2
  tocheck="user"
elif [ ${#} -eq 1 ] ; then
  tocheck="${1}"
else
  usage
  exit 1
fi

for p in curl jq jo dos2unix ; do
  hash "${p}" >/dev/null 2>&1 || {
    echo "program ${p} not found" 1>&2
    exit 1
  }
done

copts="-f -k -L -s"
if [ -e "${gtoken}" ] ; then
  copts+=" -H 'Authorization: token $(cat ${gtoken})'"
else
  if [[ "${tocheck}" =~ ^user$ ]] ; then
    echo "cannot list user-owned repos without a github token" 1>&2
    exit 1
  fi
  echo "github token ${gtoken} not found, continuing anonymously" 1>&2
fi
gdom="github.com"
gapi="https://api.${gdom}"
grepos="${gapi}/${tocheck}/repos"
header="$(eval curl -I ${copts} "${grepos}" | dos2unix | sed 's/: /=/' | jo 2>/dev/null)"
lastpage="1"
if ! $(echo "${header}" | jq -r .Link | grep -q '^null$') ; then
  lastpage="$(echo "${header}" | jq -r .Link | sed 's/\(<\|>\|,\|;\)/|/g' | tr -s '|' | tr '|' '\n' | grep -B1 'rel=.*last' | head -1 | awk -F= '{print $NF}')"
  if [[ ! ${lastpage} =~ ^[0-9]+$ ]] ; then
    echo "Link: header found but could not find last page" 1>&2
    exit 1
  fi
fi

pages=()
page="1"
while test "${page}" -le "${lastpage}" ; do
  i=$((${page}-1))
  pages[${i}]="$(eval curl ${copts} "${grepos}?page=${page}")"
  ((page=page+1))
done

for page in ${!pages[@]} ; do
  full_names=( $(echo "${pages[${page}]}" | jq -r '.[].full_name') )
  for full_name in ${full_names[@]} ; do
    echo "${pages[${page}]}" | jq -r '.[]|select(.full_name=="'"${full_name}"'")|.full_name,.name,.html_url,.clone_url,.ssh_url' | xargs echo | tr ' ' ','
  done
done
