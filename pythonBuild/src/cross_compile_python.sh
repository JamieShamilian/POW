# http://whatschrisdoing.com/blog/2006/10/06/howto-cross-compile-python-25/

if [ ! -f Python-2.5.2.tar.bz2 ]
then
wget http://www.python.org/ftp/python/2.5.2/Python-2.5.2.tar.bz2
fi
rm -rf Python-2.5.2
tar xjf Python-2.5.2.tar.bz2
cd Python-2.5.2


export CC=gcc
export CXX=g++

./configure
make python Parser/pgen || exit
mv python hostpython
mv Parser/pgen Parser/hostpgen
make distclean

patch -p1 <../python_2.5.2.patch

autoconf

. ../source_me.sh

./configure --disable-shared --without-threads --disable-ipv6 --host=powerpc-gekko
make HOSTPYTHON=./hostpython HOSTPGEN=./Parser/hostpgen CROSS_COMPILE=yes libpython2.5.a

cd ../PyOGC/
make

cd ../wiipy/
./autogen.sh
make -e
