Pod::Spec.new do |s|
  s.name             = 'CloudXMolocoAdapter'
  s.version = '3.4.0'
  s.summary          = 'CloudX Moloco Adapter - Static Framework'
  s.description      = 'Moloco adapter for CloudX iOS SDK - binary distribution. Supports Banner, MREC, Interstitial, Rewarded, and Native ad formats.'
  s.homepage         = 'https://github.com/cloudx-io/cloudx-ios'
  s.license          = { :type => 'Business Source License 1.1' }
  s.author           = { 'CloudX' => 'support@cloudx.io' }
  s.source           = { :git => 'https://github.com/cloudx-io/cloudx-ios.git', :tag => "v#{s.version}" }

  s.ios.deployment_target = '13.0'
  s.vendored_frameworks = 'adapter-moloco/CloudXMolocoAdapter.xcframework'

  s.dependency 'CloudXCore', '3.4.0'
  s.dependency 'MolocoSDKiOS', '~> 4.6.0'

  s.frameworks = ['AVFoundation', 'AVKit', 'AdSupport', 'CoreGraphics', 'CoreLocation', 'CoreTelephony', 'Foundation', 'StoreKit', 'SystemConfiguration', 'UIKit', 'WebKit']

  s.requires_arc = true
  s.static_framework = true

  s.user_target_xcconfig = {
    'OTHER_LDFLAGS' => '-ObjC'
  }

  s.swift_versions = ['5.0', '5.1', '5.2', '5.3', '5.4', '5.5', '5.6', '5.7', '5.8', '5.9', '6.0', '6.1', '6.2']
end
