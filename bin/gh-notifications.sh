#!/usr/bin/env bash
#
# XXX - flags only unread/disable seen
# XXX - was gist: https://gist.github.com/ryanwoodsmall/45af848a73c017410bd8371816425321
#

for p in gh jq mlr ; do
  command -v ${p} &>/dev/null || {
    echo "${p} not found, exiting"
    exit 1
  }
done

gh auth status &>/dev/null || {
  echo "it looks like you might not be logged in - see 'gh auth --help' for info"
  exit 1
}

{
  echo 'name,version,url'
  gh api --paginate /notifications \
  | jq -Sr '.[]|["\(.repository.full_name)","\(.subject.title)","\(.subject.url)"]|@csv'
} | mlr --icsv --opprint cat
