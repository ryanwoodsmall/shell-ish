#!/bin/bash

# XXX - this sucks

mkdir -p ~/Downloads/qemu
pushd ~/Downloads/qemu

sudo mkdir -p /opt/qemu
sudo chgrp wheel /opt/qemu
sudo chmod 2775 /opt/qemu

wget https://zlib.net/zlib-1.2.11.tar.gz
wget ftp://sourceware.org/pub/libffi/libffi-3.2.1.tar.gz
wget https://download.gnome.org/sources/glib/2.53/glib-2.53.3.tar.xz
wget http://download.qemu-project.org/qemu-2.9.0.tar.xz

tar -zxf zlib-1.2.11.tar.gz
pushd zlib-1.2.11
./configure \
  --prefix=${PWD}-built \
  --static \
  --64
make -j$(($(nproc)*2+1))
make install
popd

tar -zxf libffi-3.2.1.tar.gz
pushd libffi-3.2.1
./configure --prefix=${PWD}-built \
  --enable-static{,=yes} \
  --enable-shared=no \
  --disable-shared
make -j$(($(nproc)*2+1))
make install
popd

tar -Jxf glib-2.53.3.tar.xz
pushd glib-2.53.3
./configure \
  --prefix=${PWD}-built \
  --enable-static{,=yes} \
  --enable-shared=no \
  --disable-shared \
  --disable-libmount \
  --with-pcre=internal \
  LIBFFI_CFLAGS="$(env PKG_CONFIG_LIBDIR=${PWD}/../libffi-3.2.1-built/lib/pkgconfig pkg-config --cflags libffi)" \
  LIBFFI_LIBS="$(env PKG_CONFIG_LIBDIR=${PWD}/../libffi-3.2.1-built/lib/pkgconfig pkg-config --libs libffi)" \
  ZLIB_CFLAGS="$(env PKG_CONFIG_LIBDIR=${PWD}/../zlib-1.2.11-built/lib/pkgconfig pkg-config --cflags zlib)" \
  ZLIB_LIBS="$(env PKG_CONFIG_LIBDIR=${PWD}/../zlib-1.2.11-built/lib/pkgconfig pkg-config --libs zlib)"
make -j$(($(nproc)*2+1))
make install
popd

tar -Jxf qemu-2.9.0.tar.xz
pushd qemu-2.9.0
env PKG_CONFIG_LIBDIR=${PWD}/../glib-2.53.3-built/lib/pkgconfig:${PWD}/../libffi-3.2.1-built/lib/pkgconfig:${PWD}/../zlib-1.2.11-built/lib/pkgconfig \
  ./configure \
  --prefix=/opt/qemu/$(basename ${PWD}) \
  --interp-prefix=/opt/qemu/gnemul/qemu-%M \
  --static \
  --extra-ldflags="$(env PKG_CONFIG_LIBDIR=${PWD}/../glib-2.53.3-built/lib/pkgconfig:${PWD}/../libffi-3.2.1-built/lib/pkgconfig:${PWD}/../zlib-1.2.11-built/lib/pkgconfig pkg-config libffi zlib --libs-only-L)" \
  --extra-cflags="$(env PKG_CONFIG_LIBDIR=${PWD}/../glib-2.53.3-built/lib/pkgconfig:${PWD}/../libffi-3.2.1-built/lib/pkgconfig:${PWD}/../zlib-1.2.11-built/lib/pkgconfig pkg-config libffi zlib --cflags)" 2>&1 | tee configure.out
make -j$(($(nproc)*2+1))
make install
popd

popd

pushd /opt/qemu
test -e current && rm -f current
ln -sf qemu-2.9.0 current
popd
