#!/bin/sh

get_version() {
    if [ ! -f installer/SPECS/griddb.spec ]; then
        echo "Spec file not found!"
    fi

    echo $(grep -Eo '[0-9\.]+' installer/SPECS/griddb.spec) > output.txt
    local griddb_version=$(awk '{print $1}' output.txt)
    rm output.txt
    echo $griddb_version
}

build_rpm() {
    # Get griddb version and set source code zip file name, ex "4.5.2" and "griddb-4.5.2.zip"
    local griddb_version=$(get_version)
    local griddb_folder_name="griddb-${griddb_version}"
    local griddb_zip_file="${griddb_folder_name}.zip"

    # Create rpm file
    cd ..
    cp -rf griddb/!(.git) $griddb_folder_name
    #rm -r $griddb_folder_name/.git
    zip -r $griddb_zip_file $GRIDDB_FOLDER_NAME
    cp $griddb_zip_file griddb/installer/SOURCES/
    rm -rf $griddb_folder_name
    cd griddb/installer
    rpmbuild --define="_topdir `pwd`" -bb --clean SPECS/griddb.spec
    cd ../..
}

build_griddb() {
    # Build GridDB server
    ./bootstrap.sh
    ./configure
    make
}

install_griddb() {
    local griddb_version=$(get_version)

    # Install package
    rpm -ivh installer/RPMS/x86_64/griddb-$griddb_version-linux.x86_64.rpm
}

run_sample() {
    # Run sample
    export CLASSPATH=${CLASSPATH}:/usr/share/java/gridstore.jar
    mkdir gsSample
    if [ ! -f /usr/griddb-*/docs/sample/program/Sample1.java ]; then
        echo "Sample1.java not found!"
    fi
    cp /usr/griddb-*/docs/sample/program/Sample1.java gsSample/.
    javac gsSample/Sample1.java
    local notification_host=$1
    local notification_port=$2
    local cluster_name=$3
    local username=$4
    local password=$5
    java gsSample/Sample1 $notification_host $notification_port $cluster_name $username $password
}

opensuse_change_package_name() {
    local griddb_version=$(get_version)

    # Change file name to distinguish with CentOS package
    if [ ! -f installer/RPMS/x86_64/griddb-$griddb_version-linux.x86_64.rpm ]; then
        echo "griddb-$griddb_version-linux.x86_64.rpm not found !"
    fi
    mv installer/RPMS/x86_64/griddb-$griddb_version-linux.x86_64.rpm installer/RPMS/x86_64/griddb-$GRIDDB_VERSION-opensuse.x86_64.rpm
}

