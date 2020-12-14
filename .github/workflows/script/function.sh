#!/bin/sh

function build_rpm {
    # Get griddb version and set source code zip file name, ex "4.5.2" and "griddb-4.5.2.zip"
    echo $(grep -Eo '[0-9\.]+' installer/SPECS/griddb.spec) > output.txt
    export GRIDDB_VERSION=$(awk '{print $1}' output.txt)
    echo $GRIDDB_VERSION
    export GRIDDB_FOLDER_NAME="griddb-${GRIDDB_VERSION}"
    echo $GRIDDB_FOLDER_NAME
    export GRIDDB_ZIP_FILE="${GRIDDB_FOLDER_NAME}.zip"
    echo $GRIDDB_ZIP_FILE
    rm output.txt

    # Create rpm file
    cd ..
    cp -rf griddb/ $GRIDDB_FOLDER_NAME
    rm -r $GRIDDB_FOLDER_NAME/.git
    zip -r $GRIDDB_ZIP_FILE $GRIDDB_FOLDER_NAME
    cp $GRIDDB_ZIP_FILE griddb/installer/SOURCES/
    rm -rf $GRIDDB_FOLDER_NAME
    cd griddb/installer
    rpmbuild --define="_topdir `pwd`" -bb --clean SPECS/griddb.spec
    cd ../..
}

function build_griddb {
    # Build GridDB server
    ./bootstrap.sh
    ./configure
    make
}

function install_griddb {
    # Get griddb version and set source code zip file name, ex "4.5.2" and "griddb-4.5.2.zip"
    echo $(grep -Eo '[0-9\.]+' installer/SPECS/griddb.spec) > output.txt
    export GRIDDB_VERSION=$(awk '{print $1}' output.txt)
    rm output.txt

    # Install package
    rpm -ivh installer/RPMS/x86_64/griddb-$GRIDDB_VERSION-linux.x86_64.rpm
}

function run_sample {
    # Run sample
    export CLASSPATH=${CLASSPATH}:/usr/share/java/gridstore.jar
    mkdir gsSample
    cp /usr/griddb-*/docs/sample/program/Sample1.java gsSample/.
    javac gsSample/Sample1.java
    local notification_host=$1
    local notification_port=$2
    local cluster_name=$3
    local username=$4
    local password=$5
    java gsSample/Sample1 $notification_host $notification_port $cluster_name $username $password
}

function opensuse_change_package_name {
    # Get griddb version and set source code zip file name, ex "4.5.2" and "griddb-4.5.2.zip"
    echo $(grep -Eo '[0-9\.]+' installer/SPECS/griddb.spec) > output.txt
    export GRIDDB_VERSION=$(awk '{print $1}' output.txt)
    rm output.txt

    # Change file name to distinguish with CentOS package
    mv installer/RPMS/x86_64/griddb-$GRIDDB_VERSION-linux.x86_64.rpm installer/RPMS/x86_64/griddb-$GRIDDB_VERSION-opensuse.x86_64.rpm
}

