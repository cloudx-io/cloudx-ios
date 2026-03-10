Pod::Spec.new do |s|
  s.name = 'CloudXUnityAdapter'
  s.version = '2.0.0-rc'
  s.summary = 'Unity Ads Adapter for CloudX iOS SDK'
  s.description = 'Unity Ads adapter for CloudX iOS SDK supporting Interstitial, Rewarded, and Banner/MREC ads'
  s.homepage = 'https://github.com/cloudx-xenoss/CloudXUnityAdapter'
  s.license = { :type => 'Business Source License 1.1', :file => 'LICENSE' }
  s.authors = { 'CloudX' => 'support@cloudx.com' }
  s.platform = :ios, '13.0'
  s.swift_version = '6.0'
  s.module_name = 'CloudXUnityAdapter'
  s.source = { :path => '.' }

  # Source files
  s.source_files = 'Sources/CloudXUnityAdapter/**/*.{h,m}'

  # Public headers
  s.public_header_files = 'Sources/CloudXUnityAdapter/**/*.h'

  # Privacy Manifest for App Store compliance (iOS 17+)
  s.resource_bundles = {
    'CloudXUnityAdapter' => ['Sources/CloudXUnityAdapter/PrivacyInfo.xcprivacy']
  }

  s.dependency 'CloudXCore'
  # TODO: Update version once Unity beta SDK is released on CocoaPods
  s.dependency 'UnityAds', '~> 4.17.0'

  s.framework = 'Foundation'
  s.framework = 'UIKit'
  s.framework = 'WebKit'
  s.framework = 'AVFoundation'
  s.framework = 'CoreMedia'
  s.framework = 'AudioToolbox'
  s.framework = 'CFNetwork'
  s.framework = 'CoreGraphics'
  s.framework = 'CoreTelephony'
  s.framework = 'SystemConfiguration'
  s.framework = 'StoreKit'

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
