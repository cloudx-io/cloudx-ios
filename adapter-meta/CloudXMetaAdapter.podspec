Pod::Spec.new do |s|
  s.name             = 'CloudXMetaAdapter'
  s.version          = '1.2.1'
  s.summary          = 'CloudX Meta Adapter - Static Framework'
  s.description      = 'Meta (Facebook Audience Network) adapter for CloudX iOS SDK - binary distribution'
  s.homepage         = 'https://github.com/cloudx-io/cloudx-ios'
  s.license          = { :type => 'Business Source License 1.1' }
  s.author           = { 'CloudX' => 'support@cloudx.io' }
  s.source           = { :git => 'https://github.com/cloudx-io/cloudx-ios.git', :tag => "v#{s.version}-meta" }
  
  s.ios.deployment_target = '15.0'
  s.vendored_frameworks = 'CloudXMetaAdapter.xcframework'
  
  # Dependencies
  s.dependency 'CloudXCore', '1.2.1'
  s.dependency 'FBAudienceNetwork', '~> 6.20.1'
  
  s.frameworks = ['AVFoundation', 'AVKit', 'AdSupport', 'CoreGraphics', 'CoreLocation', 'CoreTelephony', 'Foundation', 'StoreKit', 'SystemConfiguration', 'UIKit']
  s.weak_frameworks = ['Combine', 'CryptoKit', 'SafariServices', 'SwiftUI', 'WebKit']
  
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



