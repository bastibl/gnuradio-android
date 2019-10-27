set -xe

#############################################################
### CONFIG
#############################################################
export TOOLCHAIN_ROOT=${HOME}/Android/Sdk/ndk/20.0.5594570
export HOST_ARCH=linux-x86_64

#############################################################
### DERIVED CONFIG
#############################################################
export SYS_ROOT=${TOOLCHAIN_ROOT}/sysroot
export TOOLCHAIN_BIN=${TOOLCHAIN_ROOT}/toolchains/llvm/prebuilt/${HOST_ARCH}/bin
export CC="${TOOLCHAIN_BIN}/aarch64-linux-android28-clang"
export CXX="${TOOLCHAIN_BIN}/aarch64-linux-android28-clang++"
export LD=${TOOLCHAIN_BIN}/aarch64-linux-android-ld
export AR=${TOOLCHAIN_BIN}/aarch64-linux-android-ar
export RANLIB=${TOOLCHAIN_BIN}/aarch64-linux-android-ranlib
export STRIP=${TOOLCHAIN_BIN}/aarch64-linux-android-strip
export BUILD_ROOT=$(dirname $(readlink -f "$0"))
export PATH=${TOOLCHAIN_BIN}:${PATH}
export PREFIX=${BUILD_ROOT}/toolchain/arm64-v8a
export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig
export NCORES=$(getconf _NPROCESSORS_ONLN)

mkdir -p ${PREFIX}

#############################################################
### BOOST
#############################################################
cd ${BUILD_ROOT}/Boost-for-Android
git clean -xdf

./build-android.sh --boost=1.69.0 --toolchain=llvm --prefix=$(dirname ${PREFIX}) --arch=arm64-v8a --target-version=28 ${TOOLCHAIN_ROOT}

#############################################################
### ZEROMQ
#############################################################
cd ${BUILD_ROOT}/libzmq
git clean -xdf

./autogen.sh
./configure --enable-static --disable-shared --host=aarch64-linux-android --prefix=${PREFIX} LDFLAGS="-L${PREFIX}/lib" CPPFLAGS="-fPIC -I${PREFIX}/include" LIBS="-lgcc"

make -j ${NCORES}
make install

# CXX Header-Only Bindings
wget -O $PREFIX/include/zmq.hpp https://raw.githubusercontent.com/zeromq/cppzmq/master/zmq.hpp

#############################################################
### FFTW
#############################################################
cd ${BUILD_ROOT}/fftw3
git clean -xdf

./bootstrap.sh --enable-single --enable-static --enable-threads \
  --enable-float  --enable-neon --disable-doc \
  --host=aarch64-linux-android \
  --prefix=$PREFIX

make -j ${NCORES}
make install

#############################################################
### OPENSSL
#############################################################
cd ${BUILD_ROOT}/openssl
git clean -xdf

export ANDROID_NDK_HOME=${TOOLCHAIN_ROOT}

./Configure android-arm64 -D__ARM_MAX_ARCH__=8 --prefix=${PREFIX} shared no-ssl3 no-comp
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
 --with-boost=${PREFIX} --host=aarch64-linux-android --build=x86_64-linux

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
            --host=aarch64-linux-android \
            --enable-cxx
make -j ${NCORES}
make install

#############################################################
### LIBUSB
#############################################################
cd ${BUILD_ROOT}/libusb/android/jni
git clean -xdf

export NDK=${TOOLCHAIN_ROOT}
${NDK}/ndk-build clean
${NDK}/ndk-build -B -r -R

cp ${BUILD_ROOT}/libusb/android/libs/arm64-v8a/* ${PREFIX}/lib
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
  -DANDROID_ABI=arm64-v8a -DANDROID_ARM_NEON=ON \
  -DANDROID_NATIVE_API_LEVEL=28 \
  -DANDROID_STL=c++_shared \
  -DCMAKE_FIND_ROOT_PATH=${PREFIX} \
  ../

make -j ${NCORES}
make install

#############################################################
### UHD
#############################################################
cd ${BUILD_ROOT}/uhd/host
git clean -xdf

mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=${PREFIX} \
  -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_ROOT}/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=arm64-v8a -DANDROID_ARM_NEON=ON \
  -DANDROID_NATIVE_API_LEVEL=28 \
  -DANDROID_STL=c++_shared \
  -DBOOST_ROOT=${PREFIX} \
  -DBoost_DEBUG=OFF \
  -DBoost_COMPILER=-clang \
  -DBoost_USE_STATIC_LIBS=ON \
  -DBoost_USE_DEBUG_LIBS=OFF \
  -DBoost_ARCHITECTURE=-a64 \
  -DENABLE_STATIC_LIBS=OFF \
  -DENABLE_EXAMPLES=OFF \
  -DENABLE_TESTS=OFF \
  -DENABLE_UTILS=OFF \
  -DENABLE_PYTHON_API=OFF \
  -DENABLE_MANUAL=OFF \
  -DENABLE_DOXYGEN=OFF \
  -DENABLE_MAN_PAGES=OFF \
  -DENABLE_OCTOCLOCK=OFF \
  -DENABLE_E300=OFF \
  -DENABLE_E320=OFF \
  -DENABLE_N300=OFF \
  -DENABLE_N320=OFF \
  -DENABLE_X300=OFF \
  -DENABLE_USRP2=OFF \
  -DENABLE_N230=OFF \
  -DENABLE_MPMD=OFF \
  -DENABLE_B100=OFF \
  -DENABLE_USRP1=OFF \
  -DCMAKE_FIND_ROOT_PATH=${PREFIX} \
  ../
make -j ${NCORES}
make install

#############################################################
### RTL SDR
#############################################################
cd ${BUILD_ROOT}/rtl-sdr
git clean -xdf

mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=${PREFIX} \
  -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_ROOT}/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=arm64-v8a -DANDROID_ARM_NEON=ON \
  -DANDROID_NATIVE_API_LEVEL=28 \
  -DANDROID_STL=c++_shared \
  -DDETACH_KERNEL_DRIVER=ON \
  -DCMAKE_FIND_ROOT_PATH=${PREFIX} \
  ../

make -j ${NCORES}
make install

#############################################################
### VOLK
#############################################################
cd ${BUILD_ROOT}/volk
git clean -xdf

mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=${PREFIX} \
  -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_ROOT}/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=arm64-v8a -DANDROID_ARM_NEON=ON \
  -DANDROID_NATIVE_API_LEVEL=28 \
  -DANDROID_STL=c++_shared \
  -DPYTHON_EXECUTABLE=/usr/bin/python \
  -DBOOST_ROOT=${PREFIX} \
  -DBoost_DEBUG=OFF \
  -DBoost_COMPILER=-clang \
  -DBoost_USE_STATIC_LIBS=ON \
  -DBoost_USE_DEBUG_LIBS=OFF \
  -DBoost_ARCHITECTURE=-a64 \
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
  -DANDROID_ABI=arm64-v8a -DANDROID_ARM_NEON=ON \
  -DANDROID_STL=c++_shared \
  -DANDROID_NATIVE_API_LEVEL=28 \
  -DPYTHON_EXECUTABLE=/usr/bin/python \
  -DENABLE_INTERNAL_VOLK=OFF \
  -DBOOST_ROOT=${PREFIX} \
  -DBoost_DEBUG=OFF \
  -DBoost_COMPILER=-clang \
  -DBoost_USE_STATIC_LIBS=ON \
  -DBoost_USE_DEBUG_LIBS=OFF \
  -DBoost_ARCHITECTURE=-a64 \
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
  -DANDROID_ABI=arm64-v8a -DANDROID_ARM_NEON=ON \
  -DANDROID_NATIVE_API_LEVEL=28 \
  -DANDROID_STL=c++_shared \
  -DBOOST_ROOT=${PREFIX} \
  -DBoost_DEBUG=OFF \
  -DBoost_COMPILER=-clang \
  -DBoost_USE_STATIC_LIBS=ON \
  -DBoost_USE_DEBUG_LIBS=OFF \
  -DBoost_ARCHITECTURE=-a64 \
  -DGnuradio_DIR=${BUILD_ROOT}/toolchain/arm64-v8a/lib/cmake/gnuradio \
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
  -DANDROID_ABI=arm64-v8a -DANDROID_ARM_NEON=ON \
  -DANDROID_NATIVE_API_LEVEL=28 \
  -DANDROID_STL=c++_shared \
  -DBOOST_ROOT=${PREFIX} \
  -DBoost_DEBUG=OFF \
  -DBoost_COMPILER=-clang \
  -DBoost_USE_STATIC_LIBS=ON \
  -DBoost_USE_DEBUG_LIBS=OFF \
  -DBoost_ARCHITECTURE=-a64 \
  -DGnuradio_DIR=${BUILD_ROOT}/toolchain/arm64-v8a/lib/cmake/gnuradio \
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
  -DANDROID_ABI=arm64-v8a -DANDROID_ARM_NEON=ON \
  -DANDROID_NATIVE_API_LEVEL=28 \
  -DANDROID_STL=c++_shared \
  -DBOOST_ROOT=${PREFIX} \
  -DBoost_DEBUG=OFF \
  -DBoost_COMPILER=-clang \
  -DBoost_USE_STATIC_LIBS=ON \
  -DBoost_USE_DEBUG_LIBS=OFF \
  -DBoost_ARCHITECTURE=-a64 \
  -DGnuradio_DIR=${BUILD_ROOT}/toolchain/arm64-v8a/lib/cmake/gnuradio \
  -DCMAKE_FIND_ROOT_PATH=${PREFIX} \
  ../

make -j ${NCORES}
make install

#############################################################
### GR IEEE 802.15.4
#############################################################
cd ${BUILD_ROOT}/gr-ieee802-15-4
git clean -xdf

mkdir build
cd build

cmake -DCMAKE_INSTALL_PREFIX=${PREFIX} \
  -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_ROOT}/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=arm64-v8a -DANDROID_ARM_NEON=ON \
  -DANDROID_NATIVE_API_LEVEL=28 \
  -DANDROID_STL=c++_shared \
  -DBOOST_ROOT=${PREFIX} \
  -DBoost_DEBUG=OFF \
  -DBoost_COMPILER=-clang \
  -DBoost_USE_STATIC_LIBS=ON \
  -DBoost_USE_DEBUG_LIBS=OFF \
  -DBoost_ARCHITECTURE=-a64 \
  -DGnuradio_DIR=${BUILD_ROOT}/toolchain/arm64-v8a/lib/cmake/gnuradio \
  -DCMAKE_FIND_ROOT_PATH=${PREFIX} \
  ../

make -j ${NCORES}
make install

#############################################################
### GR IEEE 802.15.4
#############################################################
cd ${BUILD_ROOT}/gr-ieee802-11
git clean -xdf

mkdir build
cd build

cmake -DCMAKE_INSTALL_PREFIX=${PREFIX} \
  -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_ROOT}/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=arm64-v8a -DANDROID_ARM_NEON=ON \
  -DANDROID_NATIVE_API_LEVEL=28 \
  -DANDROID_STL=c++_shared \
  -DBOOST_ROOT=${PREFIX} \
  -DBoost_DEBUG=OFF \
  -DBoost_COMPILER=-clang \
  -DBoost_USE_STATIC_LIBS=ON \
  -DBoost_USE_DEBUG_LIBS=OFF \
  -DBoost_ARCHITECTURE=-a64 \
  -DGnuradio_DIR=${BUILD_ROOT}/toolchain/arm64-v8a/lib/cmake/gnuradio \
  -DCMAKE_FIND_ROOT_PATH=${PREFIX} \
  ../

make -j ${NCORES}
make install

# #############################################################
# ### GR CLENABLED
# #############################################################
# cd ${BUILD_ROOT}/gr-clenabled
# git clean -xdf

# mkdir build
# cd build

# cmake -DCMAKE_INSTALL_PREFIX=${PREFIX} \
#   -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_ROOT}/build/cmake/android.toolchain.cmake \
#   -DANDROID_ABI=arm64-v8a -DANDROID_ARM_NEON=ON \
#   -DANDROID_NATIVE_API_LEVEL=28 \
#   -DANDROID_STL=c++_shared \
#   -DBOOST_ROOT=${PREFIX} \
#   -DBoost_DEBUG=OFF \
#   -DBoost_COMPILER=-clang \
#   -DBoost_USE_STATIC_LIBS=ON \
#   -DBoost_USE_DEBUG_LIBS=OFF \
#   -DBoost_ARCHITECTURE=-a64 \
#   -DGnuradio_DIR=${BUILD_ROOT}/toolchain/arm64-v8a/lib/cmake/gnuradio \
#   -DCMAKE_FIND_ROOT_PATH=${PREFIX} \
#   ../

# make -j ${NCORES}
# make install
