#!/bin/sh -xe

sudo apt-get install gcc-4.8
sudo apt-get install g++-4.8
sudo apt-get install tcl debhelper libz-dev libsqlite3-dev default-jdk default-jre
export CC=gcc-4.8
export CC_FOR_BUILD=gcc-4.8
export CXX=g++-4.8
export CXX_FOR_BUILD=g++-4.8
dpkg-buildpackage -b

# Install package and set up env
sudo apt-get install ../griddb_*_amd64.deb

sudo env ADMIN_PASSWORD="$ADMIN_PASSWORD" su - gsadm -c "gs_passwd admin -p ${ADMIN_PASSWORD}"

sudo env GRIDDB_SERVER_NAME_UBUNTU="$GRIDDB_SERVER_NAME_UBUNTU" sed -i -e s/\"clusterName\":\"\"/\"clusterName\":\"${GRIDDB_SERVER_NAME_UBUNTU}\"/g \
/var/lib/gridstore/conf/gs_cluster.json

# Start server
sudo env GRIDDB_SERVER_NAME_UBUNTU="$GRIDDB_SERVER_NAME_UBUNTU" ADMIN_PASSWORD="$ADMIN_PASSWORD" su - gsadm -c "gs_startnode -w -u admin/admin; gs_joincluster -c ${GRIDDB_SERVER_NAME_UBUNTU} -u admin/${ADMIN_PASSWORD}"

# Get griddb version
echo $(grep -Eo '[0-9\.]+' installer/SPECS/griddb.spec) >output.txt
export GRIDDB_VERSION=$(awk '{print $1}' output.txt)

# Run sample
export CLASSPATH=${CLASSPATH}:/usr/share/java/gridstore.jar
mkdir gsSample
cp /usr/griddb-$GRIDDB_VERSION/docs/sample/program/Sample1.java gsSample/.
javac gsSample/Sample1.java
java gsSample/Sample1 239.0.0.1 31999 ${GRIDDB_SERVER_NAME_UBUNTU} admin ${ADMIN_PASSWORD}

# Stop server
