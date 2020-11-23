#!/bin/sh -xe

sudo apt-get install gcc-4.8
sudo apt-get install g++-4.8
sudo apt-get install tcl debhelper libz-dev libsqlite3-dev
export CC=gcc-4.8
export CC_FOR_BUILD=gcc-4.8
export CXX=g++-4.8
export CXX_FOR_BUILD=g++-4.8
dpkg-buildpackage -b

# Install package
sudo apt-get install ../griddb_*_amd64.deb

su - gsadm -c "gs_passwd admin -p admin"

sed -i -e s/\"clusterName\":\"\"/\"clusterName\":\"dockerGridDB\"/g \
/var/lib/gridstore/conf/gs_cluster.json
su -c "gs_startnode -w -u admin/admin; gs_joincluster -c dockerGridDB -u admin/admin" - gsadm
