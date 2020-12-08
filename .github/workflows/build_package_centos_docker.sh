#!/bin/sh -xe

# Pull and run image docker centos7
docker pull centos:centos${CENTOS_VERSION}
pwd
docker run --name ${DOCKER_CONTAINER_NAME_CENTOS} -ti -d -v `pwd`:/griddb --env GS_LOG=/griddb/log --env GS_HOME=/griddb centos:centos${CENTOS_VERSION}
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
dpkg-deb -I ../griddb_*_amd64.deb
docker exec -e GRIDDB_VERSION="$GRIDDB_VERSION" ${DOCKER_CONTAINER_NAME_CENTOS} /bin/bash  -c 
"rpm -qip griddb/installer/RPMS/x86_64/griddb-$GRIDDB_VERSION-linux.x86_64.rpm"

# Copy rpm file to host

docker cp ${DOCKER_CONTAINER_NAME_CENTOS}:/griddb/installer/RPMS/x86_64/griddb-$GRIDDB_VERSION-linux.x86_64.rpm .


