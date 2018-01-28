#!/bin/bash

# useful on OS X as BSD time does not include '-f "fmt"' or verbose support

rtimetgz="http://ftp.gnu.org/gnu/time/time-1.7.tar.gz"
timetgz="$(basename ${rtimetgz})"
timedir="${timetgz//.tar.gz/}"

pushd /tmp
  rm -rf "${timedir}" "${timetgz}"
  curl -kLo "${timetgz}" "${rtimetgz}"
  tar zxf "${timetgz}"
  pushd "${timedir}"
    ./configure --prefix="${PWD}-built" && \
      make && \
      make install
  popd
  pushd "${timedir}-built/bin"
    cp -a time "${HOME}/bin/gnutime"
    ln -sf "${HOME}/bin/gnutime" "${HOME}/bin/gtime"
  popd
popd
