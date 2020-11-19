#!/bin/sh -xe

#pull and run image docker opensuse
sudo apt-get update
docker pull opensuse/leap:${OPENSUSE_VERSION}
docker run --name ${DOCKER_CONTAINER_NAME_OPENSUSE} -ti -d -v `pwd`:/griddb --env GS_LOG=/griddb/log --env GS_HOME=/griddb opensuse/leap:${OPENSUSE_VERSION}

#install gcc-4.8 and g++-4.8
docker exec ${DOCKER_CONTAINER_NAME_OPENSUSE} /bin/bash -xec "zypper addrepo https://download.opensuse.org/repositories/devel:gcc/openSUSE_Leap_15.1/devel:gcc.repo \
&& zypper --non-interactive --no-gpg-checks --quiet ref \
&& zypper --non-interactive --no-gpg-checks --quiet install --auto-agree-with-licenses gcc48 \
&& zypper --non-interactive --no-gpg-checks --quiet install --auto-agree-with-licenses gcc48-c++"

#install dependency, support for griddb sever
docker exec ${DOCKER_CONTAINER_NAME_OPENSUSE} /bin/bash -xec "zypper install -y make automake autoconf libpng16-devel java-11-openjdk ant zlib-devel tcl net-tools python"

#Create softlink gcc g++
docker exec ${DOCKER_CONTAINER_NAME_OPENSUSE} /bin/bash -xec "ln -sf /usr/bin/g++-4.8 /usr/bin/g++ \
&& ln -sf /usr/bin/gcc-4.8 /usr/bin/gcc"

#config sever
docker exec ${DOCKER_CONTAINER_NAME_OPENSUSE} /bin/bash -c "cd griddb \
&& ./bootstrap.sh \
&& ./configure \
&& make"


# Get griddb version and set source code zip file name, ex "4.5.2" and "griddb-4.5.2.zip"
echo $(grep -Eo '[0-9\.]+' installer/SPECS/griddb.spec) >output.txt
export GRIDDB_VERSION=$(awk '{print $1}' output.txt)
echo $GRIDDB_VERSION
export GRIDDB_FOLDER_NAME="griddb-${GRIDDB_VERSION}"
echo $GRIDDB_FOLDER_NAME
export GRIDDB_ZIP_FILE="${GRIDDB_FOLDER_NAME}.zip"
echo $GRIDDB_ZIP_FILE
rm output.txt

# Create rpm file
docker exec -e GRIDDB_VERSION="$GRIDDB_VERSION" -e GRIDDB_FOLDER_NAME="$GRIDDB_FOLDER_NAME" -e  GRIDDB_ZIP_FILE="$GRIDDB_ZIP_FILE" ${DOCKER_CONTAINER_NAME_CENTOS} /bin/bash  -c "cp -rf griddb/ $GRIDDB_FOLDER_NAME    \
&& zip -r $GRIDDB_ZIP_FILE $GRIDDB_FOLDER_NAME    \
&& cp $GRIDDB_ZIP_FILE griddb/installer/SOURCES/    \
&& rm -rf $GRIDDB_FOLDER_NAME    \
&& cd griddb/installer   \
&& echo $PWD    \
&& pwd \
&& ls SOURCES  \
&& realpath  SOURCES/$GRIDDB_ZIP_FILE \
&& rpmbuild --define=\"_topdir /griddb/installer\" -bb --clean SPECS/griddb.spec"

# Copy rpm file to host
docker exec ${DOCKER_CONTAINER_NAME_OPENSUSE} /bin/bash  -c "ls"
docker exec ${DOCKER_CONTAINER_NAME_OPENSUSE} /bin/bash  -c "ls /griddb"

docker cp ${DOCKER_CONTAINER_NAME_OPENSUSE}:/griddb/installer/RPMS/x86_64/griddb-$GRIDDB_VERSION-opensuse.x86_64.rpm .
