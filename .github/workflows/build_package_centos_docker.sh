#!/bin/sh -xe

# Pull and run image docker centos7
docker pull centos:centos${CENTOS_VERSION}
pwd
docker run --name ${DOCKER_CONTAINER_NAME_CENTOS} -ti -d -v `pwd`:/griddb centos:centos${CENTOS_VERSION}
docker volume ls
# Install dependency, support for griddb sever
docker exec ${DOCKER_CONTAINER_NAME_CENTOS} /bin/bash -xec "yum install automake make gcc gcc-c++ libpng-devel java ant zlib-devel tcl.x86_64 zip unzip rpm-build -y"

# Build
docker exec ${DOCKER_CONTAINER_NAME_CENTOS} /bin/bash  -c "cd griddb \
&& ./bootstrap.sh \
&& ./configure \
&& make"

# Get griddb version and set source code zip file name, ex "4.5.2" and "griddb-4.5.2.zip"
echo $(grep -Eo '[0-9\.]+' installer/SPECS/griddb.spec) >output.txt
export GRIDDB_VERSION=$(awk '{print $1}' output.txt)
export GRIDDB_FOLDER_NAME="griddb-${GRIDDB_VERSION}"
export GRIDDB_ZIP_FILE="${GRIDDB_FOLDER_NAME}.zip"
rm output.txt

# Create rpm file
docker exec -e GRIDDB_VERSION="$GRIDDB_VERSION" -e GRIDDB_FOLDER_NAME="$GRIDDB_FOLDER_NAME" -e  GRIDDB_ZIP_FILE="$GRIDDB_ZIP_FILE" ${DOCKER_CONTAINER_NAME_CENTOS} /bin/bash  -c "cp -rf griddb/ $GRIDDB_FOLDER_NAME    \
&& rm -r $GRIDDB_FOLDER_NAME/.git    \
&& zip -r $GRIDDB_ZIP_FILE $GRIDDB_FOLDER_NAME    \
&& cp $GRIDDB_ZIP_FILE griddb/installer/SOURCES/    \
&& rm -rf $GRIDDB_FOLDER_NAME    \
&& cd griddb/installer   \
&& rpmbuild --define=\"_topdir /griddb/installer\" -bb --clean SPECS/griddb.spec"

# Check package information
docker exec -e GRIDDB_VERSION="$GRIDDB_VERSION" ${DOCKER_CONTAINER_NAME_CENTOS} /bin/bash  -c "rpm -qip griddb/installer/RPMS/x86_64/griddb-$GRIDDB_VERSION-linux.x86_64.rpm"

# Install package and config GridDB server
docker exec -e GRIDDB_VERSION="$GRIDDB_VERSION" ${DOCKER_CONTAINER_NAME_CENTOS} /bin/bash -c "rpm -ivh griddb/installer/RPMS/x86_64/griddb-$GRIDDB_VERSION-linux.x86_64.rpm"
docker exec -e GRIDDB_SERVER_NAME="$GRIDDB_SERVER_NAME" -e GRIDDB_PASSWORD="$GRIDDB_PASSWORD" ${DOCKER_CONTAINER_NAME_CENTOS} /bin/bash -c "su -l gsadm -c \"gs_passwd ${GRIDDB_USERNAME} -p ${GRIDDB_PASSWORD}\"    \
&& sed -i -e s/\"clusterName\":\"\"/\"clusterName\":\"${GRIDDB_SERVER_NAME}\"/g \
/var/lib/gridstore/conf/gs_cluster.json"

# Start server
docker exec -e GRIDDB_USERNAME="$GRIDDB_USERNAME" -e GRIDDB_PASSWORD="$GRIDDB_PASSWORD" ${DOCKER_CONTAINER_NAME_CENTOS} /bin/bash -c " su -l gsadm -c \"gs_startnode -w -u ${GRIDDB_USERNAME}/${GRIDDB_PASSWORD}\""

docker exec -e GRIDDB_SERVER_NAME="$GRIDDB_SERVER_NAME" -e GRIDDB_USERNAME="$GRIDDB_USERNAME" -e GRIDDB_PASSWORD="$GRIDDB_PASSWORD" ${DOCKER_CONTAINER_NAME_CENTOS} /bin/bash -c " su -l gsadm -c \"gs_joincluster -c ${GRIDDB_SERVER_NAME} -u ${GRIDDB_USERNAME}/${GRIDDB_PASSWORD} -w\""

# Run sample
docker exec -e GRIDDB_SERVER_NAME="$GRIDDB_SERVER_NAME" -e GRIDDB_NOTIFICATION_ADDRESS="$GRIDDB_NOTIFICATION_ADDRESS" -e GRIDDB_NOTIFICATION_PORT="$GRIDDB_NOTIFICATION_PORT" -e GRIDDB_USERNAME="$GRIDDB_USERNAME" -e GRIDDB_PASSWORD="$GRIDDB_PASSWORD" ${DOCKER_CONTAINER_NAME_CENTOS} /bin/bash -c "export CLASSPATH=${CLASSPATH}:/usr/share/java/gridstore.jar    \
&& mkdir gsSample    \
&& cp /usr/griddb-$GRIDDB_VERSION/docs/sample/program/Sample1.java gsSample/.    \
&& javac gsSample/Sample1.java    \
&& java gsSample/Sample1 ${GRIDDB_NOTIFICATION_ADDRESS} ${GRIDDB_NOTIFICATION_PORT} ${GRIDDB_SERVER_NAME} ${GRIDDB_USERNAME} ${GRIDDB_PASSWORD}"

# Stop server
docker exec -e GRIDDB_USERNAME="$GRIDDB_USERNAME" -e GRIDDB_PASSWORD="$GRIDDB_PASSWORD" ${DOCKER_CONTAINER_NAME_CENTOS} /bin/bash  -c "su -l gsadm -c \"gs_stopcluster -u ${GRIDDB_USERNAME}/${GRIDDB_PASSWORD} -w\""
docker exec -e GRIDDB_USERNAME="$GRIDDB_USERNAME" -e GRIDDB_PASSWORD="$GRIDDB_PASSWORD" ${DOCKER_CONTAINER_NAME_CENTOS} /bin/bash  -c "su -l gsadm -c \"gs_stopnode -u ${GRIDDB_USERNAME}/${GRIDDB_PASSWORD} -w\""

# Uninstall package
docker exec ${DOCKER_CONTAINER_NAME_CENTOS} -e GRIDDB_PACKAGE_NAME="$GRIDDB_PACKAGE_NAME" /bin/bash -xec "yum remove ${GRIDDB_PACKAGE_NAME}"

# Copy rpm file to host
docker cp ${DOCKER_CONTAINER_NAME_CENTOS}:/griddb/installer/RPMS/x86_64/griddb-$GRIDDB_VERSION-linux.x86_64.rpm .


