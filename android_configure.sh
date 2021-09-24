#!/bin/bash
#source /home/adi/android/android_toolchain.sh
./configure --build=x86_64-unknown-linux-gnu --host=$TARGET_PREFIX$API --prefix=${DEV_PREFIX} "$@"
#./configure --build=x86_64-unknown-linux-gnu --host=$TARGET_PREFIX$API --with-sysroot=${SYSROOT} --prefix=${DEV_PREFIX} "$@"
