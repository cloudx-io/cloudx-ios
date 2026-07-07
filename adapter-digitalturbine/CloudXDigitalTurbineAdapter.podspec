Pod::Spec.new do |s|
  s.name             = 'CloudXDigitalTurbineAdapter'
  s.version = '8.4.7.0'
  s.summary          = 'CloudX Digital Turbine Adapter - Static Framework'
  s.description      = 'Digital Turbine / Fyber adapter for CloudX iOS SDK - binary distribution. Supports Banner, MREC, Interstitial, Rewarded, and Native ad formats.'
  s.homepage         = 'https://github.com/cloudx-io/cloudx-ios'
  s.license          = { :type => 'Business Source License 1.1' }
  s.author           = { 'CloudX' => 'support@cloudx.io' }
  s.source           = { :git => 'https://github.com/cloudx-io/cloudx-ios.git', :tag => "adapter-digitalturbine/#{s.version}" }

  s.ios.deployment_target = '13.0'
  s.vendored_frameworks = 'adapter-digitalturbine/CloudXDigitalTurbineAdapter.xcframework'

  s.dependency 'CloudXCore', '>= 3.5.0'
  s.dependency 'Fyber_Marketplace_SDK', '= 8.4.7'

  s.frameworks = ['AVFoundation', 'AVKit', 'AdSupport', 'CoreGraphics', 'CoreLocation', 'CoreTelephony', 'Foundation', 'StoreKit', 'SystemConfiguration', 'UIKit']
  s.weak_frameworks = ['Combine', 'CryptoKit', 'SafariServices', 'SwiftUI', 'WebKit']

  s.requires_arc = true
  s.static_framework = true

  s.user_target_xcconfig = {
    'OTHER_LDFLAGS' => '-ObjC'
  }

  s.swift_versions = ['5.0', '5.1', '5.2', '5.3', '5.4', '5.5', '5.6', '5.7', '5.8', '5.9', '6.0', '6.1', '6.2']
end
