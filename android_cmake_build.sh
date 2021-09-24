#!/bin/bash

if [ $# -ne 1 ]; then
        ARG1=build_$ABI
else
        ARG1=$1
fi

$CMAKE_BIN --build $ARG1 --target all --parallel $JOBS
