#!/bin/bash

#
# combine a video and audio file into one,
# replacing the audio in the video with that of the audio file
#
# XXX - read vid from stdin, aud from stderr, output to stdout?
# XXX - determine audio type, convert to wav if
# XXX - need "-shortest" flag???
#

set -eu

if [ ${#} -lt 3 ] ; then
  echo "please privde a video file, a .wav audio file, and an ouput filename into which the two will be combined"
  exit 1
fi

# XXX - getopt these, -v/-a/-o, shift off and pass remaining "${@}" to ffmpeg before "${o}"
v="${1}"
a="${2}"
o="${3}"

ffmpeg \
  -i "${v}" \
  -i "${a}" \
  -c:v copy \
  -c:a aac \
  -strict experimental \
  -map 0:v:0 \
  -map 1:a:0 \
    "${o}"
