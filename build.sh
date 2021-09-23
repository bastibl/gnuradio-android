set -xe

#############################################################
### CONFIG
#############################################################

#############################################################
### DERIVED CONFIG
#############################################################
#export SYS_ROOT=$SYSROOT
export BUILD_ROOT=$SCRIPT_HOME_DIR/gnuradio-android
export PATH=${TOOLCHAIN_BIN}:${PATH}
export PREFIX=$DEV_PREFIX
#export PREFIX=${BUILD_ROOT}/toolchain/$ABI

mkdir -p ${PREFIX}

echo $SYS_ROOT $BUILD_ROOT $PATH $PREFIX
#############################################################
### BOOST
#############################################################

build_boost() {

## ADI COMMENT PULL LATEST

pushd ${BUILD_ROOT}/Boost-for-Android
git clean -xdf

#./build-android.sh --boost=1.69.0 --toolchain=llvm --prefix=$(dirname ${PREFIX}) --arch=$ABI --target-version=28 ${ANDROID_NDK_ROOT}

./build-android.sh --boost=1.69.0 --layout=system --toolchain=llvm --prefix=${PREFIX} --arch=$ABI --target-version=28 ${ANDROID_NDK_ROOT}
popd
}

#############################################################
### ZEROMQ
#############################################################

build_libzmq() {
pushd ${BUILD_ROOT}/libzmq
git clean -xdf

./autogen.sh
./configure --enable-static --disable-shared --host=$TARGET_BINUTILS --prefix=${PREFIX} LDFLAGS="-L${PREFIX}/lib" CPPFLAGS="-fPIC -I${PREFIX}/include" LIBS="-lgcc"

make -j ${JOBS}
make install

# CXX Header-Only Bindings
wget -O $PREFIX/include/zmq.hpp https://raw.githubusercontent.com/zeromq/cppzmq/master/zmq.hpp
popd
}

#############################################################
### FFTW
#############################################################
build_fftw() {
## ADI COMMENT: USE downloaded version instead (OCAML fail?)
pushd ${BUILD_ROOT}/
#wget http://www.fftw.org/fftw-3.3.9.tar.gz
rm -rf fftw-3.3.9
tar xvf fftw-3.3.9.tar.gz
cd fftw-3.3.9
#git clean -xdf

if [ "$ABI" = "armeabi-v7a" ] || [ "$ABI" = "arm64-v8a" ]; then
	NEON_FLAG=--enable-neon
else
	NEON_FLAG=""
fi
echo $NEON_FLAG


./bootstrap.sh --enable-single --enable-static --enable-threads \
  --enable-float  $NEON_FLAG --disable-doc \
  --host=$TARGET_BINUTILS \
  --prefix=$PREFIX

make -j ${JOBS}
make install
popd
}

#############################################################
### OPENSSL
#############################################################
build_openssl() {
pushd ${BUILD_ROOT}/openssl
git clean -xdf

export ANDROID_NDK_HOME=${ANDROID_NDK_ROOT}

./Configure android-arm -D__ARM_MAX_ARCH__=7 --prefix=${PREFIX} shared no-ssl3 no-comp
make -j ${JOBS}
make install
popd
}

#############################################################
### THRIFT
#############################################################
build_thrift() {
pushd ${BUILD_ROOT}/thrift
git clean -xdf
rm -rf ${PREFIX}/include/thrift

./bootstrap.sh

CPPFLAGS="-I${PREFIX}/include" \
CFLAGS="-fPIC" \
CXXFLAGS="-fPIC" \
LDFLAGS="-L${PREFIX}/lib" \
./configure --prefix=${PREFIX}   --disable-tests --disable-tutorial --with-cpp \
 --without-python --without-qt4 --without-qt5 --without-py3 --without-go --without-nodejs --without-c_glib --without-php --without-csharp --without-java \
 --without-libevent --without-zlib \
 --with-boost=${PREFIX} --host=$TARGET_BINUTILS --build=x86_64-linux

sed -i '/malloc rpl_malloc/d' ./lib/cpp/src/thrift/config.h
sed -i '/realloc rpl_realloc/d' ./lib/cpp/src/thrift/config.h

make -j ${JOBS}
make install

sed -i '/malloc rpl_malloc/d' ${PREFIX}/include/thrift/config.h
sed -i '/realloc rpl_realloc/d' ${PREFIX}/include/thrift/config.h
popd
}

#############################################################
### GMP
#############################################################
build_libgmp() {
pushd ${BUILD_ROOT}/libgmp
ABI_BACKUP=$ABI
ABI=""
git clean -xdf

./.bootstrap
./configure --enable-maintainer-mode --prefix=${PREFIX} \
            --host=$TARGET_BINUTILS \
            --enable-cxx
make -j ${JOBS}
make install
ABI=$ABI_BACKUP
popd
}

#############################################################
### LIBUSB
#############################################################
build_libusb() {
pushd ${BUILD_ROOT}/libusb/android/jni
# WE NEED TO USE BetterAndroidSupport PR from libusb
# this will be merged to mainline soon
# https://github.com/libusb/libusb/pull/874

git clean -xdf

export NDK=${ANDROID_NDK_ROOT}
${NDK}/ndk-build clean
${NDK}/ndk-build -B -r -R

cp ${BUILD_ROOT}/libusb/android/libs/$ABI/* ${PREFIX}/lib
cp ${PREFIX}/lib/libusb1.0.so $PREFIX/lib/libusb-1.0.so # IDK why this happens (?)
cp ${BUILD_ROOT}/libusb/libusb/libusb.h ${PREFIX}/include
popd
}

#############################################################
### HACK RF
#############################################################
build_hackrf() {
pushd ${BUILD_ROOT}/hackrf/host/
git clean -xdf

mkdir build
cd build

$CMAKE -DCMAKE_INSTALL_PREFIX=${PREFIX} \
  -DCMAKE_TOOLCHAIN_FILE=${ANDROID_NDK_ROOT}/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=$ABI -DANDROID_ARM_NEON=ON \
  -DANDROID_NATIVE_API_LEVEL=28 \
  -DCMAKE_FIND_ROOT_PATH=${PREFIX} \
  ../

make -j ${JOBS}
make install
popd
}

# #############################################################
# ### VOLK
#############################################################
build_volk() {
pushd ${BUILD_ROOT}/volk
git clean -xdf

mkdir build
cd build
$CMAKE -DCMAKE_INSTALL_PREFIX=${PREFIX} \
  -DCMAKE_TOOLCHAIN_FILE=${ANDROID_NDK_ROOT}/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=$ABI -DANDROID_ARM_NEON=ON \
  -DANDROID_STL=c++_shared \
  -DANDROID_NATIVE_API_LEVEL=28 \
  -DPYTHON_EXECUTABLE=/usr/bin/python3 \
  -DBOOST_ROOT=${PREFIX} \
  -DBoost_COMPILER=-clang \
  -DBoost_USE_STATIC_LIBS=ON \
  -DBoost_ARCHITECTURE=-a32 \
  -DENABLE_STATIC_LIBS=False \
  -DCMAKE_FIND_ROOT_PATH=${PREFIX} \
  -DCMAKE_EXE_LINKER_FLAGS="$LDFLAGS" \
  -DCMAKE_VERBOSE_MAKEFILE=ON \
  ../
make -j ${JOBS}
make install
popd
}

#############################################################
### GNU Radio
#############################################################
build_gnuradio() {
pushd ${BUILD_ROOT}/gnuradio
git clean -xdf

mkdir build
cd build

echo "$LDFLAGS"

$CMAKE -DCMAKE_INSTALL_PREFIX=${PREFIX} \
  -DCMAKE_TOOLCHAIN_FILE=${ANDROID_NDK_ROOT}/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=$ABI -DANDROID_ARM_NEON=ON \
  -DANDROID_STL=c++_shared \
  -DANDROID_NATIVE_API_LEVEL=28 \
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
  -DENABLE_GR_CTRLPORT=OFF \
  -DENABLE_CTRLPORT_THRIFT=OFF \
  -DCMAKE_C_FLAGS="$CFLAGS" \
  -DCMAKE_CXX_FLAGS="$CPPFLAGS" \
  -DCMAKE_SHARED_LINKER_FLAGS="$LDFLAGS" \
  -DCMAKE_VERBOSE_MAKEFILE=ON \
   ../
make -j ${JOBS}
make install
popd
}

#############################################################
### GR OSMOSDR
#############################################################
build_gr-osmosdr() {
pushd ${BUILD_ROOT}/gr-osmosdr
git clean -xdf

mkdir build
cd build

$CMAKE -DCMAKE_INSTALL_PREFIX=${PREFIX} \
  -DCMAKE_TOOLCHAIN_FILE=${ANDROID_NDK_ROOT}/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=$ABI -DANDROID_ARM_NEON=ON \
  -DANDROID_NATIVE_API_LEVEL=28 \
  -DBOOST_ROOT=${PREFIX} \
  -DANDROID_STL=c++_shared \
  -DBoost_COMPILER=-clang \
  -DBoost_USE_STATIC_LIBS=ON \
  -DBoost_ARCHITECTURE=-a32 \
  -DGnuradio_DIR=${BUILD_ROOT}/toolchain/$ABI/lib/cmake/gnuradio \
  -DENABLE_REDPITAYA=OFF \
  -DENABLE_RFSPACE=OFF \
  -DCMAKE_FIND_ROOT_PATH=${PREFIX} \
  ../
make -j ${JOBS}
make install
popd
}

#############################################################
### GR GRAND
#############################################################
build_gr-grand() {
pushd ${BUILD_ROOT}/gr-grand
git clean -xdf

mkdir build
cd build

$CMAKE -DCMAKE_INSTALL_PREFIX=${PREFIX} \
  -DCMAKE_TOOLCHAIN_FILE=${ANDROID_NDK_ROOT}/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=$ABI -DANDROID_ARM_NEON=ON \
  -DANDROID_NATIVE_API_LEVEL=28 \
  -DANDROID_STL=c++_shared \
  -DBOOST_ROOT=${PREFIX} \
  -DBoost_COMPILER=-clang \
  -DBoost_USE_STATIC_LIBS=ON \
  -DBoost_ARCHITECTURE=-a32 \
  -DGnuradio_DIR=${BUILD_ROOT}/toolchain/$ABI/lib/cmake/gnuradio \
  -DCMAKE_FIND_ROOT_PATH=${PREFIX} \
    ../

make -j ${JOBS}
make install
popd
}

#############################################################
### GR SCHED
#############################################################
build_gr-sched() {
pushd ${BUILD_ROOT}/gr-sched
git clean -xdf

mkdir build
cd build

$CMAKE -DCMAKE_INSTALL_PREFIX=${PREFIX} \
  -DCMAKE_TOOLCHAIN_FILE=${ANDROID_NDK_ROOT}/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=$ABI -DANDROID_ARM_NEON=ON \
  -DANDROID_STL=c++_shared \
  -DANDROID_NATIVE_API_LEVEL=28 \
  -DBOOST_ROOT=${PREFIX} \
  -DBoost_COMPILER=-clang \
  -DBoost_USE_STATIC_LIBS=ON \
  -DBoost_ARCHITECTURE=-a32 \
  -DGnuradio_DIR=${BUILD_ROOT}/toolchain/$ABI/lib/cmake/gnuradio \
  -DCMAKE_FIND_ROOT_PATH=${PREFIX} \
  ../

make -j ${JOBS}
make install
popd
}


#############################################################
### LIBXML2
#############################################################
build_libxml2 () {
        pushd ${BUILD_ROOT}/libxml2
        cd ../libxml2
        git clean -xdf

	build_with_cmake -DLIBXML2_WITH_LZMA=OFF -DLIBXML2_WITH_PYTHON=OFF

        popd
}

#############################################################
### LIBIIO
#############################################################
build_libiio () {
        pushd ${BUILD_ROOT}/libiio
        cd ../libiio
        git clean -xdf

	build_with_cmake -DHAVE_DNS_SD=OFF

        popd
}

#############################################################
### LIBAD9361
#############################################################
build_libad9361 () {
        pushd ${BUILD_ROOT}/libad9361-iio
        cd ../libad9361-iio
        git clean -xdf

	build_with_cmake

        popd
}

#############################################################
### GR IIO
#############################################################
build_gr-iio () {
        pushd ${BUILD_ROOT}/gr-iio
        cd ../gr-iio
        git clean -xdf

	build_with_cmake -DWITH_PYTHON=OFF

        popd
}

#############################################################
### LIBICONV
#############################################################
build_libiconv () {

        pushd ${BUILD_ROOT}
        rm -rf libiconv-1.15
	tar xvf $DOWNLOADED_DEPS_PATH/libiconv-1.15.tar.gz
        cd libiconv-1.15

        LDFLAGS="$LDFLAGS_COMMON"
        android_configure --enable-static=no --enable-shared=yes

        popd
}

#############################################################
### LIBFFI
#############################################################
build_libffi() {
        pushd ${BUILD_ROOT}
        rm -rf libffi-3.3
        tar xvf $DOWNLOADED_DEPS_PATH/libffi-3.3.tar.gz
        cd libffi-3.3

        LDFLAGS="$LDFLAGS_COMMON"
        android_configure --cache-file=android.cache

        popd
}

#############################################################
### GETTEXT
#############################################################
build_gettext() {
        pushd ${BUILD_ROOT}
        rm -rf gettext-0.21
        tar xvf $DOWNLOADED_DEPS_PATH/gettext-0.21.tar.gz
        cd gettext-0.21
        #./gitsub.sh pull
        #NOCONFIGURE=1 ./autogen.sh

        LDFLAGS="$LDFLAGS_COMMON"
        android_configure --cache-file=android.cache

        popd
}

#build_boost
#build_libzmq
#build_fftw
#build_openssl
#build_thrift
#build_libgmp
#build_libusb
#build_hackrf
#build_volk
#build_gnuradio
#build_gr-osmosdr
#build_gr-grand
#build_gr-sched
#build_libxml2
#build_libiio
#build_libad9361
#build_gr-iio
#build_libiconv
#build_libffi
#build_gettext
#build_libiconv # HANDLE CIRCULAR DEP
