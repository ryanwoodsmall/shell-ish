#!/bin/bash

#
# stupid bash indirection tricks
#

name="bluh"
nptr="name"

declare -A ${name}aa
# this works too:
#   declare -A ${!nptr}aa 

eval ${name}aa["one"]=1
eval ${name}aa["zero"]=0
eval ${name}aa["three"]=3

# all equivalent...
echo ${bluhaa[@]}
eval echo $(echo \${${name}aa[@]})
eval echo $(echo \${${!nptr}aa[@]})

echo ${!bluhaa[@]}
eval echo $(echo \${!${name}aa[@]})
eval echo $(echo \${!${!nptr}aa[@]})

source /dev/stdin <<EOF
function ${name}_source()
{
  echo "this is \${name}_source"
}
EOF

${name}_source
${!nptr}_source

eval "
function ${name}_eval()
{
  echo "this is \${name}_eval"
}
"

${name}_eval
${!nptr}_eval
