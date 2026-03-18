Pod::Spec.new do |s|
  s.name = 'CloudXUnityAdsAdapter'
  s.version = '2.2.2'
  s.summary = 'Unity Ads Adapter for CloudX iOS SDK'
  s.description = 'Unity Ads adapter for CloudX iOS SDK supporting Interstitial, Rewarded, and Banner/MREC ads'
  s.homepage = 'https://github.com/cloudx-xenoss/CloudXUnityAdsAdapter'
  s.license = { :type => 'Business Source License 1.1', :file => 'LICENSE' }
  s.authors = { 'CloudX' => 'support@cloudx.com' }
  s.platform = :ios, '13.0'
  s.swift_version = '6.0'
  s.module_name = 'CloudXUnityAdsAdapter'
  s.source = { :path => '.' }

  # Source files
  s.source_files = 'Sources/CloudXUnityAdsAdapter/**/*.{h,m}'

  # Public headers
  s.public_header_files = 'Sources/CloudXUnityAdsAdapter/**/*.h'

  # Privacy Manifest for App Store compliance (iOS 17+)
  s.resource_bundles = {
    'CloudXUnityAdsAdapter' => ['Sources/CloudXUnityAdsAdapter/PrivacyInfo.xcprivacy']
  }

  s.dependency 'CloudXCore', s.version.to_s
  s.dependency 'UnityAds', '~> 4.17.0'

  s.frameworks = ['Foundation', 'UIKit', 'WebKit', 'AVFoundation', 'CoreMedia',
                   'AudioToolbox', 'CFNetwork', 'CoreGraphics', 'CoreTelephony',
                   'SystemConfiguration', 'StoreKit']

  # Enable module support for proper bracket imports
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'CLANG_ENABLE_MODULES' => 'YES'
  }

  # Handle static framework dependencies
  s.user_target_xcconfig = {
    'OTHER_LDFLAGS' => '-ObjC'
  }

  s.requires_arc = true
end
