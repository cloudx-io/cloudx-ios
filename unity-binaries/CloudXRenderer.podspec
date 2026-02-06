# CloudX iOS SDK - Release Candidate Podspec
# This podspec is used for RC testing only - points to xcframework in GitHub release
# DO NOT push to CocoaPods Trunk
#
# Based on: cloudx-ios/renderer-cloudx/CloudXRenderer.podspec (public binary distribution)

Pod::Spec.new do |s|
  s.name             = 'CloudXRenderer'
  s.version          = '2.0.0-rc.47+89a05d4'
  s.summary          = 'CloudX Renderer Framework'
  s.description      = 'Rendering engine for CloudX iOS SDK - RC binary distribution'
  s.homepage         = 'https://github.com/cloudx-io/cloudx-ios'
  s.license          = { :type => 'Business Source License 1.1' }
  s.author           = { 'CloudX' => 'support@cloudx.io' }
  s.source           = { :git => '', :tag => s.version.to_s }
  
  s.ios.deployment_target = '13.0'
  s.vendored_frameworks = 'CloudXRenderer.xcframework'
  
  # Dependencies - CloudXCore version is set to RC version via placeholder
  s.dependency 'CloudXCore', '2.0.0-rc.47+89a05d4'
  
  s.frameworks = ['Foundation', 'UIKit', 'WebKit', 'AVFoundation', 'AVKit']
  s.weak_frameworks = ['SafariServices']
  
  s.requires_arc = true
  
  # -ObjC for OMSDK categories (mirrors AppLovin setup)
  s.pod_target_xcconfig = {
    'OTHER_LDFLAGS' => '-ObjC'
  }
  
  s.user_target_xcconfig = {
    'OTHER_LDFLAGS' => '-ObjC'
  }
  
  s.swift_versions = ['5.0', '5.1', '5.2', '5.3', '5.4', '5.5', '5.6', '5.7', '5.8', '5.9', '6.0', '6.1', '6.2']
end
