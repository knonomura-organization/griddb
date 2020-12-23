#!/bin/sh

readonly UBUNTU=Ubuntu
readonly CENTOS=Centos
readonly OPENSUSE=Opensuse

check_file_exist() {
    local file_path=$1
    if [ ! -f "$file_path" ]; then
        echo "$file_path not found!"
    fi
}

get_version() {
    check_file_exist "installer/SPECS/griddb.spec"

    echo $(grep -Eo '[0-9\.]+' installer/SPECS/griddb.spec) > output.txt
    local griddb_version=$(awk '{print $1}' output.txt)
    rm output.txt
    echo $griddb_version
}

build_package() {
    local os=$1
    case $os in
        $CENTOS | $OPENSUSE)
            # Get griddb version and set source code zip file name,
            #   ex "4.5.2" and "griddb-4.5.2.zip"
            local griddb_version=$(get_version)
            local griddb_folder_name="griddb-${griddb_version}"
            local griddb_zip_file="${griddb_folder_name}.zip"

            # Create rpm file
            cd ..
            rsync -a --exclude=.git griddb/ $griddb_folder_name
            zip -r $griddb_zip_file $griddb_folder_name
            cp $griddb_zip_file griddb/installer/SOURCES/
            rm -rf $griddb_folder_name
            cd griddb/installer
            check_file_exist "SPECS/griddb.spec"
            rpmbuild --define="_topdir `pwd`" -bb --clean SPECS/griddb.spec
            cd ..
            ;;

        $UBUNTU)
            dpkg-buildpackage -b
            ;;

        *)
            echo "Unknown OS"
            ;;

    esac
    # Change package name of OPENSUSE version to distinguish with CENTOS version
    if [ $os == $OPENSUSE ]; then
        $(opensuse_change_package_name)
    fi
}

build_griddb() {
    local os=$1
    case $os in
        $CENTOS | $OPENSUSE)
            # Build GridDB server
            ./bootstrap.sh
            ./configure
            make
            ;;
        $UBUNTU)
            # No need to build before create Ubuntu package
            ;;
        *)
            echo "Unknown OS"
            ;;

    esac

}

install_griddb() {
    local package_path=$1
    check_file_exist "$package_path"

    local os=$2
    # Install package
    case $os in
        $CENTOS | $OPENSUSE)
            rpm -ivh $package_path
            ;;
        $UBUNTU)
            dpkg -i $package_path
            ;;
        *)
            echo "Unknown OS"
            ;;

    esac

}

run_sample() {
    # Run sample
    export CLASSPATH=${CLASSPATH}:/usr/share/java/gridstore.jar
    mkdir gsSample
    check_file_exist "/usr/griddb-*/docs/sample/program/Sample1.java"
    cp /usr/griddb-*/docs/sample/program/Sample1.java gsSample/.
    javac gsSample/Sample1.java
    local notification_host=$1
    local notification_port=$2
    local cluster_name=$3
    local username=$4
    local password=$5
    java gsSample/Sample1 $notification_host $notification_port \
        $cluster_name $username $password
}

opensuse_change_package_name() {
    local griddb_version=$(get_version)

    # Change file name to distinguish with CentOS package
    check_file_exist "installer/RPMS/x86_64/griddb-$griddb_version-linux.x86_64.rpm"
    mv "installer/RPMS/x86_64/griddb-$griddb_version-linux.x86_64.rpm" \
      "installer/RPMS/x86_64/griddb-$griddb_version-opensuse.x86_64.rpm"
}

config_griddb() {
    local username=$1
    local password=$2
    local cluster_name=$3
    su -l gsadm -c "gs_passwd $username -p $password"
    su -l gsadm -c "sed -i 's/\"clusterName\":\"\"/\"clusterName\":\"$cluster_name\"/g' /var/lib/gridstore/conf/gs_cluster.json"
}

start_griddb() {
    local username=$1
    local password=$2
    local cluster_name=$3
    su -l gsadm -c "gs_startnode -w -u $username/$password"
    su -l gsadm -c "gs_joincluster -c $cluster_name -u $username/$password -w"
}

stop_griddb() {
    local username=$1
    local password=$2
    su -l gsadm -c "gs_stopcluster -u  $username/$password -w"
    su -l gsadm -c "gs_stopnode -u  $username/$password -w"
}

check_package() {
    local package_path=$1
    check_file_exist "$package_path"

    local os=$2
    case $os in
        $CENTOS | $OPENSUSE)
            rpm -qip $package_path
            ;;
        $UBUNTU)
            dpkg-deb -I $package_path
            ;;
        *)
            echo "Unknown OS"
            ;;

    esac
}

uninstall_package() {
    local package_name=$1
    local os=$2
    case $os in
        $CENTOS | $OPENSUSE)
            rpm -e $package_name
            ;;
        $UBUNTU)
            dpkg -r $package_name
            ;;
        *)
            echo "Unknown OS"
            ;;
    esac
}

