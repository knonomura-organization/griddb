#!/bin/sh -xe

#pull and run image docker centos7
docker pull centos:centos${CENTOS_VERSION}
docker run --name ${DOCKER_CONTAINER_NAME_CENTOS} -ti -d -v `pwd`:/griddb --env GS_LOG=/griddb/log --env GS_HOME=/griddb centos:centos${CENTOS_VERSION}

#install dependency, support for griddb sever
docker exec ${DOCKER_CONTAINER_NAME_CENTOS} /bin/bash -xec "yum install automake make gcc gcc-c++ libpng-devel java ant zlib-devel tcl.x86_64 -y"

#config sever
docker exec ${DOCKER_CONTAINER_NAME_CENTOS} /bin/bash -c "cd griddb \
&& ./bootstrap.sh \
&& ./configure \
&& make \
&& echo $(grep -Eo '[0-9\.]+' installer/SPECS/griddb.spec) >output.txt \
&& export griddb_version=$(awk '{print $1}' output.txt) \
&& export griddb_folder_name= griddb-$griddb_version   \
&& export griddb_zip_file = $griddb_folder_name.zip    \
&& rm output.txt    \
&& cd ../    \
&& cp -rf griddb/ $griddb_folder_name    \
&& zip -rf $griddb_zip_file $griddb_folder_name   \
&& mv $griddb_zip_file griddb/installer/SOURCES/  \
&& rm -rf $griddb_folder_name   \
&& cd griddb/installer   \
&& rpmbuild --define="_topdir `pwd`" -bb --clean SPECS/griddb.spec"

