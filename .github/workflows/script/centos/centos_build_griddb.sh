# Check OS version
cat /etc/os-release

# Build griddb
cd griddb
./bootstrap.sh
./configure
make
cd ../
