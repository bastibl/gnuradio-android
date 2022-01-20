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
#build_libzmq
build_fftw
build_openssl
#build_thrift
build_libgmp
build_libusb
build_libiio
build_libad9361
#build_hackrf # you need to revert libusb patches
#build_uhd # you need to revert libusb patches
#build_rtl-sdr # you need to revert libusb patches
build_volk
build_gnuradio
build_gr-iio
#build_gr-osmosdr # switch OOT to 3.8
#build_gr-grand  # switch OOT to 3.8
#build_gr-sched # switch OOT to 3.8
#build_gr-ieee-802-15-4 # switch OOT to 3.8
#build_gr-ieee-802-11 # switch OOT to 3.8
#build_gr-clenabled # switch OOT to 3.8
