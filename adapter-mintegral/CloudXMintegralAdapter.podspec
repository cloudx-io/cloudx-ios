Pod::Spec.new do |s|
  s.name = 'CloudXMintegralAdapter'
  s.version = '1.0.0'
  s.summary = 'CloudX Adapter for Mintegral iOS SDK'
  s.description = 'The CloudX Mintegral Adapter enables publishers to monetize their iOS applications through the CloudX SDK.'
  s.homepage = 'https://github.com/cloudx-io/cloudx-ios'
  s.license = { :type => 'Business Source License 1.1', :file => 'LICENSE' }
  s.authors = { 'CloudX' => 'support@cloudx.com' }
  s.source = { :git => 'https://github.com/cloudx-io/cloudx-ios.git', :tag => s.version.to_s }

  s.ios.deployment_target = '15.0'
  s.source_files = 'Sources/CloudXMintegralAdapter/**/*.{h,m}'
  s.public_header_files = 'Sources/CloudXMintegralAdapter/**/*.h'
  s.resource_bundles = {
    'CloudXMintegralAdapter' => ['Sources/CloudXMintegralAdapter/PrivacyInfo.xcprivacy']
  }

  s.dependency 'CloudXCore'
  s.dependency 'MintegralAdSDK', '~> 7.6'
  s.dependency 'MintegralAdSDK/BidBannerAd', '~> 7.6'
  s.dependency 'MintegralAdSDK/BidInterstitialVideoAd', '~> 7.6'
  s.dependency 'MintegralAdSDK/BidRewardVideoAd', '~> 7.6'

  s.frameworks = ['Foundation', 'UIKit', 'AdSupport', 'CoreGraphics', 'CoreTelephony', 'SystemConfiguration', 'AVFoundation', 'CoreMedia', 'QuartzCore', 'StoreKit', 'WebKit']
  s.weak_frameworks = ['AppTrackingTransparency']

  s.pod_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64',
    'DEFINES_MODULE' => 'YES',
    'CLANG_ENABLE_MODULES' => 'YES'
  }
  
  s.user_target_xcconfig = {
    'OTHER_LDFLAGS' => '-ObjC'
  }
  
  s.requires_arc = true
  s.swift_versions = ['5.0', '5.1', '5.2', '5.3', '5.4', '5.5', '5.6', '5.7', '5.8', '5.9', '6.0', '6.1', '6.2']
end

