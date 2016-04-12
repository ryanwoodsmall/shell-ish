#!/bin/bash

#
# builds a usable hash of instance info
#

# only displays output if in interactive or debug mode
# always exits nicely regardless of error

idurl="http://169.254.169.254/latest"
curlopts="-s -k -L"
curlget="curl ${curlopts}"
curlhead="curl ${curlopts} -I"
declare -A ec2instinfo

# we need curl
hash curl >/dev/null 2>&1 || {
    if [[ $- =~ i|x ]] ; then
        echo "${0}: need the 'curl' command, but it was not found" 1>&2
    fi
    # exit nicely regardless
    return 0
}

# make sure we don't get a 404 on meta-/user-data checking
${curlhead} ${idurl} | grep -q 404 && {
    if [[ $- =~ i|x ]] ; then
        echo "${0}: couldn't hit ${idurl} with curl" 1>&2
    fi
    return 0
}

# recurse paths if we end with a /
# otherwise, hash our value to the key
function getec2instinfo() {
    local tpath="${1}"
    local spath=''
    for spath in $(${curlget} ${idurl}/${tpath}) ; do
        if ! `${curlget} ${idurl}/${tpath}${spath} | grep -q 404` ; then
            if [[ ${spath} =~ .*/$ ]] ; then
                getec2instinfo "${tpath}${spath}"
            else
                ec2instinfo["${tpath}${spath}"]=$(${curlget} ${idurl}/${tpath}${spath} | sed 's/^/  /g')
            fi
        fi
    done
}

# call our ec2 instance info grabber function against all non-404 top-level URLs
for tl in $(${curlget} ${idurl}) ; do
    if ! `${curlhead} ${idurl}/${tl} | grep -q 404` ; then
        getec2instinfo "${tl}/"
    fi
done

# dump out our keys/vals if we're in debug
if [[ $- =~ x ]] ; then
    for instkey in "${!ec2instinfo[@]}" ; do
        echo ${instkey}
        echo "  ${ec2instinfo["${instkey}"]}"
        echo
    done
fi

export ec2instinfo

return 0
