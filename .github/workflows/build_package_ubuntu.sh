#!/bin/sh -xe

# Install dependencies packages
sudo apt-get install gcc-4.8
sudo apt-get install g++-4.8
sudo apt-get install tcl debhelper libz-dev libsqlite3-dev default-jdk default-jre
export CC=gcc-4.8
export CC_FOR_BUILD=gcc-4.8
export CXX=g++-4.8
export CXX_FOR_BUILD=g++-4.8

# Build package
dpkg-buildpackage -b

# Install package and config GridDB server
sudo dpkg -i install ../griddb_*_amd64.deb
sudo env GRIDDB_PASSWORD="$GRIDDB_PASSWORD" su - gsadm -c "gs_passwd ${GRIDDB_USERNAME} -p ${GRIDDB_PASSWORD}"
sudo env GRIDDB_SERVER_NAME="$GRIDDB_SERVER_NAME" sed -i -e s/\"clusterName\":\"\"/\"clusterName\":\"${GRIDDB_SERVER_NAME}\"/g \
/var/lib/gridstore/conf/gs_cluster.json

# Start server
sudo env GRIDDB_SERVER_NAME="$GRIDDB_SERVER_NAME" GRIDDB_PASSWORD="$GRIDDB_PASSWORD" su - gsadm -c "gs_startnode -w -u ${GRIDDB_USERNAME}/${GRIDDB_PASSWORD}; gs_joincluster -c ${GRIDDB_SERVER_NAME} -u ${GRIDDB_USERNAME}/${GRIDDB_PASSWORD} -w"

# Get GridDB version
echo $(grep -Eo '[0-9\.]+' installer/SPECS/griddb.spec) > output.txt
export GRIDDB_VERSION=$(awk '{print $1}' output.txt)

# Run sample
export CLASSPATH=${CLASSPATH}:/usr/share/java/gridstore.jar
mkdir gsSample
cp /usr/griddb-$GRIDDB_VERSION/docs/sample/program/Sample1.java gsSample/.
javac gsSample/Sample1.java
java gsSample/Sample1 ${GRIDDB_NOTIFICATION_ADDRESS} ${GRIDDB_NOTIFICATION_PORT} ${GRIDDB_SERVER_NAME} ${GRIDDB_USERNAME} ${GRIDDB_PASSWORD}

# Stop server
sudo su - gsadm -c "gs_stopcluster -u ${GRIDDB_USERNAME}/${GRIDDB_PASSWORD} -w"
sudo su - gsadm -c "gs_stopnode -u ${GRIDDB_USERNAME}/${GRIDDB_PASSWORD} -w"
