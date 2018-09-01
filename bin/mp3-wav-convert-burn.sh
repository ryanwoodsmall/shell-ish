#!/bin/bash

#
# welcome to 2003
#   - convert ./*.mp3 to .wav (removing spaces in the process)
#   - burn with cdrecord
#

# exit early
set -e

# find options
fopts="-mindepth 1 -maxdepth 1 -type f"

# cdrecord options
# XXX - may need -overburn
copts="-dao -pad -verbose"

# make sure we have necessary programs
for p in mpg123 cdrecord ; do
  which ${p} >/dev/null 2>&1
  if [ $? -ne 0 ] ; then
    echo "${p} not found"
    exit 1
  fi
done

# make sure there are some .mp3 files in .
find . ${fopts} | grep -qi '\.mp3$'
if [ $? -ne 0 ] ; then
  echo "no .mp3 files found"
  exit 1
fi

# for every .mp3, convert to .wav
#   i.e, "01 - Title.MP3" is converted to "01_-_Title.wav"
find . ${fopts} \
| grep -i '\.mp3$' \
| while IFS="$(printf '\n')" read -r f ; do
  # replace spaces with _
  n="${f// /_}"
  # get extension (.mp3, .MP3, ...}
  e="${n##*.}"
  # generate .wav file
  w="${n/%.${e}/.wav}"
  echo "converting '${f}' to '${w}'"
  mpg123 -w "${w}" "${f}"
done
echo

# make sure we have some .wav files
find . ${fopts} | grep -qi '\.wav$'
if [ $? -ne 0 ] ; then
  echo "no .wav files found"
  exit 1
fi

# burn
echo "burning these files:"
ls -lA *.wav
echo
cdrecord ${copts} *.wav
sync
