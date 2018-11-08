#!/bin/sh

#
# via https://www.commandlinefu.com/commands/view/3584/remove-color-codes-special-characters-with-sed
#

sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g"
