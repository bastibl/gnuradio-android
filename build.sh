set -xe

#############################################################
### CONFIG
#############################################################
export TOOLCHAIN_ROOT=${HOME}/Android/Sdk/ndk/21.3.6528147
export HOST_ARCH=linux-x86_64

#############################################################
### DERIVED CONFIG
#############################################################
export SYS_ROOT=${TOOLCHAIN_ROOT}/sysroot
export TOOLCHAIN_BIN=${TOOLCHAIN_ROOT}/toolchains/llvm/prebuilt/${HOST_ARCH}/bin
export API_LEVEL=29
export CC="${TOOLCHAIN_BIN}/armv7a-linux-androideabi${API_LEVEL}-clang"
export CXX="${TOOLCHAIN_BIN}/armv7a-linux-androideabi${API_LEVEL}-clang++"
export LD=${TOOLCHAIN_BIN}/arm-linux-androideabi-ld
export AR=${TOOLCHAIN_BIN}/arm-linux-androideabi-ar
export RANLIB=${TOOLCHAIN_BIN}/arm-linux-androideabi-ranlib
export STRIP=${TOOLCHAIN_BIN}/arm-linux-androideabi-strip
export BUILD_ROOT=$(dirname $(readlink -f "$0"))
export PATH=${TOOLCHAIN_BIN}:${PATH}
export PREFIX=${BUILD_ROOT}/toolchain/armeabi-v7a
export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig
export NCORES=$(getconf _NPROCESSORS_ONLN)

mkdir -p ${PREFIX}

#############################################################
### BOOST
#############################################################
cd ${BUILD_ROOT}/Boost-for-Android
git clean -xdf

./build-android.sh --boost=1.69.0 --toolchain=llvm --prefix=$(dirname ${PREFIX}) --arch=armeabi-v7a --target-version=${API_LEVEL} ${TOOLCHAIN_ROOT}

#############################################################
### ZEROMQ
#############################################################
cd ${BUILD_ROOT}/libzmq
git clean -xdf

./autogen.sh
./configure --enable-static --disable-shared --host=arm-linux-androideabi --prefix=${PREFIX} LDFLAGS="-L${PREFIX}/lib" CPPFLAGS="-fPIC -I${PREFIX}/include" LIBS="-lgcc"

make -j ${NCORES}
make install

# CXX Header-Only Bindings
wget -O $PREFIX/include/zmq.hpp https://raw.githubusercontent.com/zeromq/cppzmq/master/zmq.hpp

#############################################################
### FFTW
#############################################################
cd ${BUILD_ROOT}/fftw3
git clean -xdf

./configure --enable-single --enable-static --enable-threads \
  --enable-float  --enable-neon --disable-doc \
  --host=arm-linux-androideabi \
  --prefix=$PREFIX

make -j ${NCORES}
make install

#############################################################
### OPENSSL
#############################################################
cd ${BUILD_ROOT}/openssl
git clean -xdf

export ANDROID_NDK_HOME=${TOOLCHAIN_ROOT}

./Configure android-arm -D__ARM_MAX_ARCH__=7 --prefix=${PREFIX} shared no-ssl3 no-comp
make -j ${NCORES}
make install

#############################################################
### THRIFT
#############################################################
cd ${BUILD_ROOT}/thrift
git clean -xdf
rm -rf ${PREFIX}/include/thrift

./bootstrap.sh

CPPFLAGS="-I${PREFIX}/include" \
CFLAGS="-fPIC" \
CXXFLAGS="-fPIC" \
LDFLAGS="-L${PREIX}/lib" \
./configure --prefix=${PREFIX}   --disable-tests --disable-tutorial --with-cpp \
 --without-python --without-qt4 --without-qt5 --without-py3 --without-go --without-nodejs --without-c_glib --without-php --without-csharp --without-java \
 --without-libevent --without-zlib \
 --with-boost=${PREFIX} --host=arm-linux-androideabi --build=x86_64-linux

sed -i '/malloc rpl_malloc/d' ./lib/cpp/src/thrift/config.h
sed -i '/realloc rpl_realloc/d' ./lib/cpp/src/thrift/config.h

make -j ${NCORES}
make install

sed -i '/malloc rpl_malloc/d' ${PREFIX}/include/thrift/config.h
sed -i '/realloc rpl_realloc/d' ${PREFIX}/include/thrift/config.h

#############################################################
### GMP
#############################################################
cd ${BUILD_ROOT}/libgmp
git clean -xdf

./.bootstrap
./configure --enable-maintainer-mode --prefix=${PREFIX} \
            --host=arm-linux-androideabi \
            --enable-cxx
make -j ${NCORES}
make install

#############################################################
### LIBUSB
#############################################################
cd ${BUILD_ROOT}/libusb/android/jni
git clean -xdf

export NDK=${TOOLCHAIN_ROOT}
${NDK}/ndk-build

cp ${BUILD_ROOT}/libusb/android/libs/armeabi-v7a/* ${PREFIX}/lib
cp ${BUILD_ROOT}/libusb/libusb/libusb.h ${PREFIX}/include

#############################################################
### HACK RF
#############################################################
cd ${BUILD_ROOT}/hackrf/host/
git clean -xdf

mkdir build
cd build

cmake -DCMAKE_INSTALL_PREFIX=${PREFIX} \
  -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_ROOT}/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=armeabi-v7a -DANDROID_ARM_NEON=ON \
  -DANDROID_NATIVE_API_LEVEL=${API_LEVEL} \
  -DCMAKE_FIND_ROOT_PATH=${PREFIX} \
  ../

make -j ${NCORES}
make install

# #############################################################
# ### VOLK
#############################################################
cd ${BUILD_ROOT}/volk
git clean -xdf

mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=${PREFIX} \
  -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_ROOT}/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=armeabi-v7a -DANDROID_ARM_NEON=ON \
  -DANDROID_NATIVE_API_LEVEL=${API_LEVEL} \
  -DPYTHON_EXECUTABLE=/usr/bin/python3 \
  -DBOOST_ROOT=${PREFIX} \
  -DBoost_COMPILER=-clang \
  -DBoost_USE_STATIC_LIBS=ON \
  -DBoost_ARCHITECTURE=-a32 \
  -DENABLE_STATIC_LIBS=True \
  -DCMAKE_FIND_ROOT_PATH=${PREFIX} \
  ../
make -j ${NCORES}
make install

#############################################################
### GNU Radio
#############################################################
cd ${BUILD_ROOT}/gnuradio
git clean -xdf

mkdir build
cd build

cmake -DCMAKE_INSTALL_PREFIX=${PREFIX} \
  -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_ROOT}/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=armeabi-v7a -DANDROID_ARM_NEON=ON \
  -DANDROID_NATIVE_API_LEVEL=${API_LEVEL} \
  -DPYTHON_EXECUTABLE=/usr/bin/python3 \
  -DENABLE_INTERNAL_VOLK=OFF \
  -DBOOST_ROOT=${PREFIX} \
  -DBoost_COMPILER=-clang \
  -DBoost_USE_STATIC_LIBS=ON \
  -DBoost_ARCHITECTURE=-a32 \
  -DCMAKE_FIND_ROOT_PATH=${PREFIX} \
  -DENABLE_DOXYGEN=OFF \
  -DENABLE_SPHINX=OFF \
  -DENABLE_PYTHON=OFF \
  -DENABLE_TESTING=OFF \
  -DENABLE_GR_FEC=OFF \
  -DENABLE_GR_AUDIO=OFF \
  -DENABLE_GR_DTV=OFF \
  -DENABLE_GR_CHANNELS=OFF \
  -DENABLE_GR_VOCODER=OFF \
  -DENABLE_GR_TRELLIS=OFF \
  -DENABLE_GR_WAVELET=OFF \
  -DENABLE_GR_CTRLPORT=ON \
  -DENABLE_CTRLPORT_THRIFT=ON \
  ../
make -j ${NCORES}
make install

#############################################################
### GR OSMOSDR
#############################################################
cd ${BUILD_ROOT}/gr-osmosdr
git clean -xdf

mkdir build
cd build

cmake -DCMAKE_INSTALL_PREFIX=${PREFIX} \
  -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_ROOT}/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=armeabi-v7a -DANDROID_ARM_NEON=ON \
  -DANDROID_NATIVE_API_LEVEL=${API_LEVEL} \
  -DBOOST_ROOT=${PREFIX} \
  -DBoost_COMPILER=-clang \
  -DBoost_USE_STATIC_LIBS=ON \
  -DBoost_ARCHITECTURE=-a32 \
  -DGnuradio_DIR=${BUILD_ROOT}/toolchain/armeabi-v7a/lib/cmake/gnuradio \
  -DENABLE_REDPITAYA=OFF \
  -DENABLE_RFSPACE=OFF \
  -DCMAKE_FIND_ROOT_PATH=${PREFIX} \
  ../
make -j ${NCORES}
make install

#############################################################
### GR GRAND
#############################################################
cd ${BUILD_ROOT}/gr-grand
git clean -xdf

mkdir build
cd build

cmake -DCMAKE_INSTALL_PREFIX=${PREFIX} \
  -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_ROOT}/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=armeabi-v7a -DANDROID_ARM_NEON=ON \
  -DANDROID_NATIVE_API_LEVEL=${API_LEVEL} \
  -DBOOST_ROOT=${PREFIX} \
  -DBoost_COMPILER=-clang \
  -DBoost_USE_STATIC_LIBS=ON \
  -DBoost_ARCHITECTURE=-a32 \
  -DGnuradio_DIR=${BUILD_ROOT}/toolchain/armeabi-v7a/lib/cmake/gnuradio \
  -DCMAKE_FIND_ROOT_PATH=${PREFIX} \
  ../

make -j ${NCORES}
make install

#############################################################
### GR SCHED
#############################################################
cd ${BUILD_ROOT}/gr-sched
git clean -xdf

mkdir build
cd build

cmake -DCMAKE_INSTALL_PREFIX=${PREFIX} \
  -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_ROOT}/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=armeabi-v7a -DANDROID_ARM_NEON=ON \
  -DANDROID_NATIVE_API_LEVEL=${API_LEVEL} \
  -DBOOST_ROOT=${PREFIX} \
  -DBoost_COMPILER=-clang \
  -DBoost_USE_STATIC_LIBS=ON \
  -DBoost_ARCHITECTURE=-a32 \
  -DGnuradio_DIR=${BUILD_ROOT}/toolchain/armeabi-v7a/lib/cmake/gnuradio \
  -DCMAKE_FIND_ROOT_PATH=${PREFIX} \
  ../

make -j ${NCORES}
make install
