# CloudX iOS SDK - Release Candidate Podspec
# This podspec is used for RC testing only - points to xcframework in GitHub release
# DO NOT push to CocoaPods Trunk
#
# Based on: cloudx-ios/core/CloudXCore.podspec (public binary distribution)

Pod::Spec.new do |s|
  s.name             = 'CloudXCore'
  s.version          = '2.0.0-rc.47+89a05d4'
  s.summary          = 'CloudX Core Framework'
  s.description      = 'Core framework for CloudX functionality - RC binary distribution'
  s.homepage         = 'https://github.com/cloudx-io/cloudx-ios'
  s.license          = { :type => 'Business Source License 1.1' }
  s.author           = { 'CloudX' => 'support@cloudx.io' }
  s.source           = { :http => 'https://github.com/cloudx-io/cloudx-ios-private/releases/download/2.0.0-rc.47%2B89a05d4/CloudXCore.xcframework.zip' }
  
  s.ios.deployment_target = '13.0'
  s.vendored_frameworks = 'CloudXCore.xcframework'
  
  s.frameworks = ['Foundation', 'SafariServices', 'UIKit', 'CoreLocation', 'WebKit', 'CoreData']
  
  s.pod_target_xcconfig = {
    'CLANG_ENABLE_MODULES' => 'YES',
    'ENABLE_USER_SCRIPT_SANDBOXING' => 'NO',
    'DEFINES_MODULE' => 'YES'
  }
  s.user_target_xcconfig = {
    'ENABLE_USER_SCRIPT_SANDBOXING' => 'NO',
    'OTHER_LDFLAGS' => '$(inherited) -ObjC'
  }
  
  s.swift_versions = ['5.0', '5.1', '5.2', '5.3', '5.4', '5.5', '5.6', '5.7', '5.8', '5.9', '6.0', '6.1', '6.2']
end
