# Get griddb version and set source code zip file name, ex "4.5.2" and "griddb-4.5.2.zip"
echo $(grep -Eo '[0-9\.]+' installer/SPECS/griddb.spec) > output.txt
export GRIDDB_VERSION=$(awk '{print $1}' output.txt)
rm output.txt

# Change file name to distinguish with CentOS package
mv installer/RPMS/x86_64/griddb-$GRIDDB_VERSION-linux.x86_64.rpm installer/RPMS/x86_64/griddb-$GRIDDB_VERSION-opensuse.x86_64.rpm
