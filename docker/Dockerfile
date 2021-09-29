FROM ubuntu:19.10

MAINTAINER Bastian Bloessl mail@bastibl.net

ARG USER=android

RUN sed -i 's/archive.ubuntu.com/old-releases.ubuntu.com/g' /etc/apt/sources.list
RUN sed -i 's/security.ubuntu.com/old-releases.ubuntu.com/g' /etc/apt/sources.list

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update
RUN apt-get install -y git vim wget unzip sudo xserver-xorg openjdk-11-jre cmake libtool build-essential pkg-config autogen ocaml ocamlbuild bison flex texinfo python-dev python-mako python-six swig3.0 python3-mako python3-numpy python3-distutils

RUN groupadd -g 1000 -r $USER
RUN useradd -u 1000 -g 1000 --create-home -r $USER

#Change password
RUN echo "$USER:$USER" | chpasswd

#Make sudo passwordless
RUN echo "${USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-$USER
RUN usermod -aG sudo $USER
RUN usermod -aG plugdev $USER

USER $USER

RUN mkdir -p /home/$USER/src
WORKDIR /home/$USER/src

RUN git clone --recursive https://github.com/bastibl/gnuradio-android.git

WORKDIR /home/$USER/src/gnuradio-android/thrift
RUN git clean -xdf
RUN ./bootstrap.sh
RUN ./configure --disable-tests --disable-tutorial --with-cpp --without-python --without-qt4 --without-qt5 --without-py3 --without-go --without-nodejs --without-c_glib --without-php --without-csharp --without-java --without-libevent --without-zlib
RUN make -j $(getconf _NPROCESSORS_ONLN)
RUN sudo make install

WORKDIR /home/$USER/src
RUN wget https://redirector.gvt1.com/edgedl/android/studio/ide-zips/3.6.3.0/android-studio-ide-192.6392135-linux.tar.gz
RUN tar xvf android-studio-ide-192.6392135-linux.tar.gz
RUN rm android-studio-ide-192.6392135-linux.tar.gz

RUN wget https://dl.google.com/android/repository/commandlinetools-linux-6200805_latest.zip
RUN unzip commandlinetools-linux-6200805_latest.zip

RUN mkdir -p /home/$USER/Android/Sdk
ENV ANDROID_HOME /home/$USER/Android/Sdk
WORKDIR /home/$USER/src/tools/bin

RUN yes | ./sdkmanager --sdk_root=${ANDROID_HOME} --licenses
RUN yes | ./sdkmanager --sdk_root=${ANDROID_HOME} "platforms;android-29"
RUN yes | ./sdkmanager --sdk_root=${ANDROID_HOME} "ndk;21.3.6528147"
RUN yes | ./sdkmanager --sdk_root=${ANDROID_HOME} "platform-tools"
RUN yes | ./sdkmanager --sdk_root=${ANDROID_HOME} "build-tools;30.0.0"
RUN yes | ./sdkmanager --sdk_root=${ANDROID_HOME} "cmake;3.10.2.4988404"
RUN yes | ./sdkmanager --sdk_root=${ANDROID_HOME} "cmdline-tools;latest"

WORKDIR /home/$USER/src/gnuradio-android
RUN ./build.sh
RUN ./build_aarch64.sh

WORKDIR /home/$USER/src
RUN git clone https://github.com/bastibl/android-benchmark.git
RUN git clone https://github.com/bastibl/android-volk.git
RUN git clone https://github.com/bastibl/android-fm.git
#RUN git clone https://github.com/bastibl/android-hw.git
#RUN git clone https://github.com/bastibl/android-wlan.git

WORKDIR /home/$USER/src/gnuradio-android

ENTRYPOINT ["/bin/bash"]



