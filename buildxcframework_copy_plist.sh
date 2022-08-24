#!/bin/bash
set -e

WORKING_DIR=$(pwd)

FRAMEWORK_FOLDER_NAME="ClearentIdtechIOSFramework_XCFramework"

FRAMEWORK_NAME="ClearentIdtechIOSFramework"

FRAMEWORK_PATH="${WORKING_DIR}/${FRAMEWORK_FOLDER_NAME}/${FRAMEWORK_NAME}.xcframework"

BUILD_SCHEME="ClearentIdtechIOSFramework"

SIMULATOR_ARCHIVE_PATH="${WORKING_DIR}/${FRAMEWORK_FOLDER_NAME}/simulator.xcarchive"

SIMULATOR_ARCHIVE_PATH="${WORKING_DIR}/${FRAMEWORK_FOLDER_NAME}/simulator.xcarchive"

INFO_PLIST_ARCHIVE_PATH="/Users/dhigginbotham/Documents/_idtech_frameworks/ios/3.1.lumber/ClearentIdtechIOSFramework/${FRAMEWORK_FOLDER_NAME}"

echo "*********/Users/dhigginbotham/Documents/_idtech_frameworks/ios/3.1.lumber/ClearentIdtechIOSFramework/ClearentIdtechIOSFramework/Info.plist********************"
echo "*********************** info plist location ${INFO_PLIST_ARCHIVE_PATH} ******************************"

echo "*********************** TRY TO COPY ******************************"
cp "/Users/dhigginbotham/Documents/_idtech_frameworks/ios/3.1.lumber/ClearentIdtechIOSFramework/ClearentIdtechIOSFramework/Info.plist" "${INFO_PLIST_ARCHIVE_PATH}"


echo "*********************** info plist copied ******************************"
echo "*********************** info plist copied ******************************"
echo "*********************** info plist copied ******************************"
echo "*********************** info plist copied ******************************"
echo "*********************** info plist copied ******************************"

open "${WORKING_DIR}/${FRAMEWORK_FOLDER_NAME}"
