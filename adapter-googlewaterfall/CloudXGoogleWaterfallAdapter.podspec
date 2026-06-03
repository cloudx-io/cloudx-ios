Pod::Spec.new do |s|
  s.name             = 'CloudXGoogleWaterfallAdapter'
  s.version = '3.4.5'
  s.summary          = 'CloudX Google Waterfall Adapter - Static Framework'
  s.description      = 'Google Waterfall adapter for CloudX iOS SDK - binary distribution. Supports Banner (320x50) and MREC (300x250) ad formats.'
  s.homepage         = 'https://github.com/cloudx-io/cloudx-ios'
  s.license          = { :type => 'Business Source License 1.1' }
  s.author           = { 'CloudX' => 'support@cloudx.io' }
  s.source           = { :git => 'https://github.com/cloudx-io/cloudx-ios.git', :tag => "v#{s.version}" }

  s.ios.deployment_target = '13.0'
  s.vendored_frameworks = 'adapter-googlewaterfall/CloudXGoogleWaterfallAdapter.xcframework'

  s.dependency 'CloudXCore', '3.4.5'
  s.dependency 'Google-Mobile-Ads-SDK', '12.14.0'

  s.frameworks = ['AVFoundation', 'AVKit', 'AdSupport', 'CoreGraphics', 'CoreLocation', 'CoreTelephony', 'Foundation', 'StoreKit', 'SystemConfiguration', 'UIKit', 'WebKit']
  s.weak_frameworks = ['GoogleMobileAds']

  s.requires_arc = true
  s.static_framework = true

  s.user_target_xcconfig = {
    'OTHER_LDFLAGS' => '-ObjC'
  }

  s.swift_versions = ['5.0', '5.1', '5.2', '5.3', '5.4', '5.5', '5.6', '5.7', '5.8', '5.9', '6.0', '6.1', '6.2']
end
