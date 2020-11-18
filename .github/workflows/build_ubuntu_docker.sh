#!/bin/sh -xe

sudo apt-get install gcc-4.8
sudo apt-get install g++-4.8
sudo apt-get install tcl debhelper libz-dev libsqlite3-dev
export CC=gcc-4.8
export CC_FOR_BUILD=gcc-4.8
export CXX=g++-4.8
export CXX_FOR_BUILD=g++-4.8
dpkg-buildpackage -b

