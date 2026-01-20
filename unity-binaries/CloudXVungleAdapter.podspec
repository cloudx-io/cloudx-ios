# CloudX iOS SDK - Release Candidate Podspec
# This podspec is used for RC testing only - points to xcframework in GitHub release
# DO NOT push to CocoaPods Trunk
#
# Based on: cloudx-ios/adapter-vungle/CloudXVungleAdapter.podspec (public binary distribution)

Pod::Spec.new do |s|
  s.name             = 'CloudXVungleAdapter'
  s.version          = '2.0.0-rc.47+89a05d4'
  s.summary          = 'CloudX Vungle Adapter - Static Framework'
  s.description      = 'Vungle/Liftoff adapter for CloudX iOS SDK - RC binary distribution'
  s.homepage         = 'https://github.com/cloudx-io/cloudx-ios'
  s.license          = { :type => 'Business Source License 1.1' }
  s.author           = { 'CloudX' => 'support@cloudx.io' }
  s.source           = { :git => '', :tag => s.version.to_s }
  
  s.ios.deployment_target = '15.0'
  s.vendored_frameworks = 'CloudXVungleAdapter.xcframework'
  
  # Dependencies - CloudXCore version is set to RC version via placeholder
  s.dependency 'CloudXCore', '2.0.0-rc.47+89a05d4'
  s.dependency 'VungleAds', '~> 7.6.0'
  
  s.frameworks = ['AVFoundation', 'AudioToolbox', 'CFNetwork', 'CoreGraphics', 'CoreMedia', 'CoreTelephony', 'Foundation', 'StoreKit', 'SystemConfiguration', 'UIKit', 'WebKit']
  
  s.requires_arc = true
  s.static_framework = true
  
  s.pod_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
  
  s.user_target_xcconfig = {
    'OTHER_LDFLAGS' => '-ObjC'
  }
  
  s.swift_versions = ['5.0', '5.1', '5.2', '5.3', '5.4', '5.5', '5.6', '5.7', '5.8', '5.9', '6.0', '6.1', '6.2']
end
