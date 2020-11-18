#!/bin/sh -xe

#pull and run image docker centos7
docker pull centos:centos${CENTOS_VERSION}
docker run --name ${DOCKER_CONTAINER_NAME_CENTOS} -ti -d -v `pwd`:/griddb --env GS_LOG=/griddb/log --env GS_HOME=/griddb centos:centos${CENTOS_VERSION}

#install dependency, support for griddb sever
docker exec ${DOCKER_CONTAINER_NAME_CENTOS} /bin/bash -xec "yum install automake make gcc gcc-c++ libpng-devel java ant zlib-devel tcl.x86_64 -y"

echo $(grep -Eo '[0-9\.]+' installer/SPECS/griddb.spec) >output.txt
export GRIDDB_VERSION=$(awk '{print $1}' output.txt)
echo $GRIDDB_VERSION
export GRIDDB_FOLDER_NAME="griddb-${GRIDDB_VERSION}"
echo $GRIDDB_FOLDER_NAME
export GRIDDB_ZIP_FILE="${GRIDDB_FOLDER_NAME}.zip"
echo $GRIDDB_ZIP_FILE
rm output.txt


#config sever
docker exec ${DOCKER_CONTAINER_NAME_CENTOS} /bin/bash -e GRIDDB_VERSION="$GRIDDB_VERSION" -e GRIDDB_FOLDER_NAME="$GRIDDB_FOLDER_NAME" -e  GRIDDB_ZIP_FILE="$GRIDDB_ZIP_FILE" -c "cd griddb \
&& ./bootstrap.sh \
&& ./configure \
&& make \
&& cd ../    \
&& cp -rf griddb/ ${GRIDDB_FOLDER_NAME}    \
&& zip -r ${GRIDDB_ZIP_FILE} ${GRIDDB_FOLDER_NAME}   \
&& mv ${GRIDDB_ZIP_FILE} griddb/installer/SOURCES/  \
&& rm -rf $GRIDDB_FOLDER_NAME   \
&& cd griddb/installer   \
&& rpmbuild --define=\"_topdir `pwd`\" -bb --clean SPECS/griddb.spec"

