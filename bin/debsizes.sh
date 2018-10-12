#!/bin/bash
dpkg-query --show --showformat='${Installed-Size} ${Package}\n' \
| sort -n
