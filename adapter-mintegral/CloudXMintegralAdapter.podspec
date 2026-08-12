Pod::Spec.new do |s|
  s.name             = 'CloudXMintegralAdapter'
  s.version = '8.0.7.0'
  s.summary          = 'CloudX Mintegral Adapter - Static Framework'
  s.description      = 'Mintegral adapter for CloudX iOS SDK - binary distribution'
  s.homepage         = 'https://github.com/cloudx-io/cloudx-ios'
  s.license          = { :type => 'Business Source License 1.1' }
  s.author           = { 'CloudX' => 'support@cloudx.io' }
  s.source           = { :git => 'https://github.com/cloudx-io/cloudx-ios.git', :tag => "adapter-mintegral/#{s.version}" }

  s.ios.deployment_target = '13.0'
  s.vendored_frameworks = 'adapter-mintegral/CloudXMintegralAdapter.xcframework'

  # Dependencies
  s.dependency 'CloudXCore', '>= 3.5.0'
  s.dependency 'MintegralAdSDK', '= 8.0.7'
  s.dependency 'MintegralAdSDK/BidBannerAd', '= 8.0.7'
  s.dependency 'MintegralAdSDK/BidNewInterstitialAd', '= 8.0.7'
  s.dependency 'MintegralAdSDK/BidRewardVideoAd', '= 8.0.7'
  s.dependency 'MintegralAdSDK/BidNativeAdvancedAd', '= 8.0.7'
  s.dependency 'MintegralAdSDK/BidSplashAd', '= 8.0.7'

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
