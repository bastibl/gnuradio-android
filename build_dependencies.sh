#!/bin/bash
source ./include_dependencies.sh $1 $2


download_dependencies
build_libiconv
build_libffi
build_gettext
build_libiconv # HANDLE CIRCULAR DEP
build_libxml2
build_boost
move_boost_libs
build_libzmq
build_fftw
# build_openssl
# build_thrift
build_libgmp
build_libusb
# build_hackrf
build_libiio
build_libad9361
build_volk
build_gnuradio
build_gr-iio
# build_gr-osmosdr
# build_gr-grand
# build_gr-sched