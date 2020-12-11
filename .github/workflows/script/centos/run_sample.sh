# Run sample
export CLASSPATH=${CLASSPATH}:/usr/share/java/gridstore.jar
mkdir gsSample
cp /usr/griddb-*/docs/sample/program/Sample1.java gsSample/.
javac gsSample/Sample1.java
java gsSample/Sample1 ${GRIDDB_NOTIFICATION_ADDRESS} ${GRIDDB_NOTIFICATION_PORT} ${GRIDDB_SERVER_NAME} ${GRIDDB_USERNAME} ${GRIDDB_PASSWORD}
