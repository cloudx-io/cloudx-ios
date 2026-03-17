Pod::Spec.new do |s|
  s.name = 'CloudXVungleAdapter'
  s.version = '2.2.2'
  s.summary = 'Vungle Adapter for CloudX iOS SDK'
  s.description = 'Vungle adapter for CloudX iOS SDK supporting all ad formats: Interstitial, Rewarded, Banner/MREC, Native, and App Open ads'
  s.homepage = 'https://github.com/cloudx-xenoss/CloudXVungleAdapter'
  s.license = { :type => 'Business Source License 1.1', :file => 'LICENSE' }
  s.authors = { 'CloudX' => 'support@cloudx.com' }
  s.platform = :ios, '13.0'
  s.swift_version = '6.0'
  s.module_name = 'CloudXVungleAdapter'
  s.source = { :path => '.' }
  
  # Source files
  s.source_files = 'Sources/CloudXVungleAdapter/**/*.{h,m}'
  
  # Public headers
  s.public_header_files = 'Sources/CloudXVungleAdapter/**/*.h'
  
  # Privacy Manifest for App Store compliance (iOS 17+)
  s.resource_bundles = {
    'CloudXVungleAdapter' => ['Sources/CloudXVungleAdapter/PrivacyInfo.xcprivacy']
  }
  
  s.dependency 'CloudXCore', s.version.to_s
  s.dependency 'VungleAds', '~> 7.6.0'
  
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
