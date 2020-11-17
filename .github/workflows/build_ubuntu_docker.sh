#!/bin/sh -xe

# Build package on ubuntu
docker pull ubuntu:18.04
docker run --name ${DOCKER_CONTAINER_NAME_CENTOS} -ti -d -v `pwd`:/griddb --env GS_LOG=/griddb/log --env GS_HOME=/griddb centos:centos${CENTOS_VERSION}
#install dependency, support for griddb sever
docker exec ${DOCKER_CONTAINER_NAME_CENTOS} /bin/bash -xec "apt-get install debhelper"

#config sever
docker exec ${DOCKER_CONTAINER_NAME_CENTOS} /bin/bash -c "cd griddb \
&& dpkg-buildpackage -b"


