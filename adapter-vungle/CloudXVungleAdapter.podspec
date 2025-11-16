Pod::Spec.new do |s|
  s.name = 'CloudXVungleAdapter'
  s.version = '1.2.0-rc.1'
  s.summary = 'Vungle Adapter for CloudX iOS SDK'
  s.description = 'Vungle adapter for CloudX iOS SDK supporting all ad formats: Interstitial, Rewarded, Banner/MREC, Native, and App Open ads'
  s.homepage = 'https://github.com/cloudx-xenoss/CloudXVungleAdapter'
  s.license = { :type => 'Business Source License 1.1', :file => 'LICENSE' }
  s.authors = { 'CloudX' => 'support@cloudx.com' }
  s.platform = :ios, '14.0'
  s.swift_version = '5.9'
  s.module_name = 'CloudXVungleAdapter'
  s.source = { :http => 'https://github.com/cloudx-io/cloudx-ios/releases/download/v1.2.0-rc.1-vungle/CloudXVungleAdapter-v1.2.0-rc.1.xcframework.zip' }
  
  s.vendored_frameworks = 'adapter-vungle/CloudXVungleAdapter.xcframework'
  
  s.dependency 'CloudXCore'
  s.dependency 'VungleAds', '~> 7.4.0'
  
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
