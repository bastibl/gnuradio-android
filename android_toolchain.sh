#!/bin/bash

source ./build_system_setup.sh $2

export NDK_VERSION=21.3.6528147
export API=28 # need ABI at least 28 for glob from my tests
#export JOBS=$(getconf _NPROCESSORS_ONLN)
export JOBS=9
export HOST_ARCH=linux-x86_64

if [ $# -ne 1 ]; then
	ARG1=aarch64
else
	ARG1=$1
fi

TARGET_PREFIX=NO_ABI

if [ $ARG1 = "aarch64" ]; then
############ aarch64 #########
export ABI=arm64-v8a
export TARGET_PREFIX=aarch64-linux-android
export TARGET_BINUTILS=aarch64-linux-android
#############################
fi

if [ $ARG1 = "arm" ]; then
############# armv7a ##########
export ABI=armeabi-v7a
export TARGET_PREFIX=armv7a-linux-androideabi
export TARGET_BINUTILS=arm-linux-androideabi
###############################
fi

if [ $ARG1 = "x86_64" ]; then
############# x86_64 ###########
export TARGET_BINUTILS=x86_64-linux-android
export ABI=x86_64
export TARGET_PREFIX=x86_64-linux-android
#################################
fi

if [ $ARG1 = "x86" ]; then
######## x86 - i686 ############
export TARGET_PREFIX=i686-linux-android
export ABI=x86
export TARGET_BINUTILS=i686-linux-android
#################################
fi

export WORKDIR=$SCRIPT_HOME_DIR/deps_build_$TARGET_PREFIX

# This is just an empty directory where I want the built objects to be installed
export DEV_PREFIX=$WORKDIR/out
# Don't mix up .pc files from your host and build target
export PKG_CONFIG_PATH=${DEV_PREFIX}/lib/pkgconfig

export ANDROID_NDK_ROOT=$ANDROID_SDK_ROOT/ndk/$NDK_VERSION
export TOOLCHAIN=${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/$HOST_ARCH
export TOOLCHAIN_BIN=${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/${HOST_ARCH}/bin
export QMAKE=$QT_INSTALL_PREFIX/bin/qmake
export ANDROID_QT_DEPLOY=$QT_INSTALL_PREFIX/bin/androiddeployqt

# Apparently android-8 works fine, there are other versions, look them up
export SYSROOT=$TOOLCHAIN/sysroot

# Non-exhaustive lists of compiler + binutils
# Depending on what you compile, you might need more binutils than that
#export CC=$TOOLCHAIN/bin/clang

export CC=$TOOLCHAIN/bin/$TARGET_PREFIX$API-clang
export CXX=$TOOLCHAIN/bin/$TARGET_PREFIX$API-clang++
export CPP="$CC -E"
export AR=$TOOLCHAIN/bin/llvm-ar
export AS=${CC}
export NM=$TOOLCHAIN/bin/${TARGET_BINUTILS}-nm
export STRIP=${TOOLCHAIN_BIN}/arm-linux-androideabi-strip
export READELF=$TOOLCHAIN/bin/${TARGET_BINUTILS}-readelf
export LD=$TOOLCHAIN/bin/${TARGET_BINUTILS}-ld
export RANLIB=$TOOLCHAIN/bin/llvm-ranlib

export CFLAGS="-I${SYSROOT}/include -I${SYSROOT}/usr/include -I${TOOLCHAIN}/include -I${DEV_PREFIX}/include -fPIC"
export STAGING_DIR=${DEV_PREFIX}
#export CFLAGS="--sysroot=${SYSROOT} -I${SYSROOT}/include -I${SYSROOT}/usr/include -I${TOOLCHAIN}/include -I${DEV_PREFIX}/include -fPIC"
export CPPFLAGS="-fexceptions -frtti ${CFLAGS} "
export LDFLAGS_COMMON="-L${SYSROOT}/usr/lib/$TARGET_BINUTILS/$API -L${TOOLCHAIN}/lib -L${DEV_PREFIX} -L${DEV_PREFIX}/lib"
export LDFLAGS="$LDFLAGS_COMMON"

echo ANDROID_SDK=$ANDROID_SDK_ROOT
echo CMAKE=$CMAKE
echo QT_INSTALL_PREFIX=$QT_INSTALL_PREFIX
echo JDK=$JDK
echo NDK_VERSION=$NDK_VERSION
echo JOBS=$JOBS
echo SCRIPT_HOME_DIR=$SCRIPT_HOME_DIR
#echo
echo $TARGET_PREFIX$API
#if [ $TARGET_PREFIX = "NO_ABI" ]; then
#	exit 22 # Invalid argument
#fi

