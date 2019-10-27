#!/bin/bash

docker build -t gnuradio-android .

docker run -it --privileged --net=host --env="DISPLAY" --volume="$HOME/.Xauthority:/home/android/.Xauthority:rw"  gnuradio-android
