#!/bin/bash
set -e

WORKING_DIR=$(pwd)

FRAMEWORK_FOLDER_NAME="ClearentIdtechIOSFramework.xcframework"

FRAMEWORK_NAME="ClearentIdtechIOSFramework"

FRAMEWORK_PATH="${WORKING_DIR}/${FRAMEWORK_FOLDER_NAME}/${FRAMEWORK_NAME}.xcframework"

BUILD_SCHEME="ClearentIdtechIOSFramework"

iOS_ARCHIVE_PATH="${WORKING_DIR}/${FRAMEWORK_FOLDER_NAME}/iOS.xcarchive/Products/Library/Frameworks/ClearentIdtechIOSFramework.framework/Modules"
SIMULATOR_ARCHIVE_PATH="${WORKING_DIR}/${FRAMEWORK_FOLDER_NAME}/simulator.xcarchive/Products/Library/Frameworks/ClearentIdtechIOSFramework.framework/Modules"


iOS_XC_DEST_FRMWK_PATH="${WORKING_DIR}/${FRAMEWORK_FOLDER_NAME}/ClearentIdtechIOSFramework.xcframework/ios-arm64/ClearentIdtechIOSFramework.framework"
SIMULATOR_XC_DEST_FRMWK_PATH="${WORKING_DIR}/${FRAMEWORK_FOLDER_NAME}/ClearentIdtechIOSFramework.xcframework/ios-arm64_x86_64-simulator/ClearentIdtechIOSFramework.framework"


cp -r ${iOS_ARCHIVE_PATH} ${iOS_XC_DEST_FRMWK_PATH}
cp -r ${SIMULATOR_ARCHIVE_PATH} ${SIMULATOR_XC_DEST_FRMWK_PATH}


echo "Modules were replace in the to xcframework"
