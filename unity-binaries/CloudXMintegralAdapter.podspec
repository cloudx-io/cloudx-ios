# CloudX iOS SDK - Release Candidate Podspec
# This podspec is used for RC testing only - points to xcframework in GitHub release
# DO NOT push to CocoaPods Trunk
#
# Note: Mintegral adapter is new - not yet in public repo

Pod::Spec.new do |s|
  s.name             = 'CloudXMintegralAdapter'
  s.version          = '2.0.0-rc.47+89a05d4'
  s.summary          = 'CloudX Mintegral Adapter - Static Framework'
  s.description      = 'Mintegral adapter for CloudX iOS SDK - RC binary distribution'
  s.homepage         = 'https://github.com/cloudx-io/cloudx-ios'
  s.license          = { :type => 'Business Source License 1.1' }
  s.author           = { 'CloudX' => 'support@cloudx.io' }
  s.source           = { :git => '', :tag => s.version.to_s }
  
  s.ios.deployment_target = '15.0'
  s.vendored_frameworks = 'CloudXMintegralAdapter.xcframework'
  
  # Dependencies - CloudXCore version is set to RC version via placeholder
  s.dependency 'CloudXCore', '2.0.0-rc.47+89a05d4'
  s.dependency 'MintegralAdSDK', '~> 8.0'
  s.dependency 'MintegralAdSDK/BannerAd', '~> 8.0'
  s.dependency 'MintegralAdSDK/BidInterstitialVideoAd', '~> 8.0'
  s.dependency 'MintegralAdSDK/BidRewardVideoAd', '~> 8.0'
  
  s.frameworks = ['Foundation', 'UIKit', 'AdSupport', 'CoreGraphics', 'CoreTelephony', 'SystemConfiguration', 'AVFoundation', 'CoreMedia', 'QuartzCore', 'StoreKit', 'WebKit']
  s.weak_frameworks = ['AppTrackingTransparency']
  
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
