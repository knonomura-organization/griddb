ls

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
