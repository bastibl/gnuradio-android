#!/bin/bash
source ./android_toolchain.sh $1 $2
source ./include_dependencies.sh

build_libiconv
build_libffi
build_gettext
build_libiconv # HANDLE CIRCULAR DEP
build_libxml2
build_boost
move_boost_libs
build_libzmq
build_fftw
build_openssl
build_thrift
build_libgmp
build_libusb
build_libiio
build_libad9361
build_volk
build_gnuradio
build_gr-iio
build_hackrf
build_gr-osmosdr
build_gr-grand
build_gr-sched
