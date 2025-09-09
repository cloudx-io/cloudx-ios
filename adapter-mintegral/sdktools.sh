#! /bin/bash

 xcodebuild archive -workspace CloudXMintegralAdapter.xcworkspace \
                -scheme CloudXMintegralAdapter \
                -archivePath "archives/CloudXMintegralAdapter-iOS" \
                -destination "generic/platform=iOS" \
                SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES

 xcodebuild archive -workspace CloudXMintegralAdapter.xcworkspace \
                -scheme CloudXMintegralAdapter \
                -archivePath "archives/CloudXMintegralAdapter-iOS_Simulator" \
                -destination "generic/platform=iOS Simulator" \
                SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES

xcodebuild -create-xcframework \
    -archive archives/CloudXMintegralAdapter-iOS.xcarchive -framework CloudXMintegralAdapter.framework \
    -archive archives/CloudXMintegralAdapter-iOS_Simulator.xcarchive -framework CloudXMintegralAdapter.framework \
    -output archives/CloudXMintegralAdapter.xcframework
