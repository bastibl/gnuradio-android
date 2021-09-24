#!/bin/bash

set -xe

if [ $# -ne 1 ]; then
        ARG1=build_$ABI
else
        ARG1=$1
fi

$ANDROID_QT_DEPLOY --verbose --output $ARG1/android-build --no-build --input $ARG1/android-project-deployment-settings.json --gradle --reinstall --device <adb_device_id>

