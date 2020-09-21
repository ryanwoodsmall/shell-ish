#!/bin/bash

for p in 'curl' 'mlr' ; do
  if ! $(which ${p} >/dev/null 2>&1) ; then
    echo "${p} not found"
    exit 1
  fi
done

curl -kLs https://zipso.net/chromebooks/output/chromebooks-all-zipso.csv \
| sed 's#n/a#0#g;s#\*##g;s#,,$##g' \
| mlr \
    --icsvlite \
    --opprint \
    --barred \
      cut -f 'Brand,Name,Screen,Resolution,Touchscreen,CPU model,CPU speed,Cores,Memory,storage,Octane' \
      then \
        sort -nr Octane \
      then \
        cat
