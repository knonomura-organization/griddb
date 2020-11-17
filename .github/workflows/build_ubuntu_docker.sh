#!/bin/sh -xe

# Build package on ubuntu
apt-get install debhelper
dpkg-buildpackage -b
