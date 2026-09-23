Pod::Spec.new do |s|
  s.name             = 'CloudXBigoAdapter'
  s.version          = '6.1.0.0'
  s.summary          = 'CloudX BIGO Ads Adapter - Static Framework'
  s.description      = 'BIGO Ads server-bidding adapter for CloudX iOS SDK - binary distribution. Supports Banner, MREC, Interstitial, and Rewarded ad formats.'
  s.homepage         = 'https://github.com/cloudx-io/cloudx-ios'
  s.license          = { :type => 'Business Source License 1.1' }
  s.author           = { 'CloudX' => 'support@cloudx.io' }
  s.source           = { :git => 'https://github.com/cloudx-io/cloudx-ios.git', :tag => "adapter-bigo/#{s.version}" }

  s.ios.deployment_target = '13.0'
  s.vendored_frameworks = 'adapter-bigo/CloudXBigoAdapter.xcframework'

  s.dependency 'CloudXCore', '>= 3.9.0'
  s.dependency 'BigoADS', '= 6.1.0'

  s.frameworks = ['Foundation', 'UIKit']

  s.requires_arc = true
  s.static_framework = true

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'CLANG_ENABLE_MODULES' => 'YES'
  }

  s.user_target_xcconfig = {
    'OTHER_LDFLAGS' => '-ObjC'
  }

  s.swift_versions = ['5.0', '5.1', '5.2', '5.3', '5.4', '5.5', '5.6', '5.7', '5.8', '5.9', '6.0', '6.1', '6.2']
end
