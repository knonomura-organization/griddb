# Get griddb version and set source code zip file name, ex "4.5.2" and "griddb-4.5.2.zip"
echo $(grep -Eo '[0-9\.]+' installer/SPECS/griddb.spec) > output.txt
export GRIDDB_VERSION=$(awk '{print $1}' output.txt)
rm output.txt

# Check package information
rpm -qip installer/RPMS/x86_64/griddb-$GRIDDB_VERSION-linux.x86_64.rpm
