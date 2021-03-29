#!/usr/bin/env bash

#
# dump some information for azul zulu java versions
#
# API stuff:
# - https://www.azul.com/downloads/zulu-community/api/
# - https://app.swaggerhub.com/apis-docs/azul/zulu-download-community/1.0
#

set -eu

for p in curl jq ; do
  which ${p} >/dev/null 2>&1 || { echo "${p} not found" ; exit 1 ; }
done

: ${java_versions:="8 11"}
: ${exts:="tar.gz"}
: ${oses:="linux"}
: ${bundle_types:="jdk"}
: ${release_statuses:="ga"}
: ${support_terms:="lts"}
: ${arch_query_strings:="arch=x86&hw_bitness=32 arch=x86&hw_bitness=64 arch=arm&hw_bitness=32&abi=hard_float arch=arm&hw_bitness=64"}

azul_zulu_api_url="https://api.azul.com/zulu/download/community/v1.0/bundles/latest/"

for java_version in ${java_versions} ; do
  for ext in ${exts} ; do
    for os in ${oses} ; do
      for bundle_type in ${bundle_types} ; do
        for release_status in ${release_statuses} ; do
          for support_term in ${support_terms} ; do
            for arch_query_string in ${arch_query_strings} ; do
              u="${azul_zulu_api_url}"
              u+="?jdk_version=${java_version}"
              u+="&ext=${ext}"
              u+="&os=${os}"
              u+="&bundle_type=${bundle_type}"
              u+="&release_status=${release_status}"
              u+="&support_term=${support_term}"
              u+="&${arch_query_string}"
              curl -kLs "${u}" | jq .
            done
          done
        done
      done
    done
  done
done

echo
