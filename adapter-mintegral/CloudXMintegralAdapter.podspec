Pod::Spec.new do |s|
  s.name = 'CloudXMintegralAdapter'
  s.version = '2.2.2'
  s.summary = 'CloudX Adapter for Mintegral iOS SDK'
  s.description = <<-DESC
    The CloudX Mintegral Adapter enables publishers to monetize their iOS applications 
    through the CloudX SDK using Mintegral ad network.
    
    Features:
    - Banner, Interstitial, and Rewarded Video ads
    - Header bidding support with enhanced bid tokens
    - Creative ID tracking for analytics
    - Video mute control and banner configuration
    - Channel attribution for Mintegral
    - Comprehensive error code mapping
  DESC
  s.homepage = 'https://github.com/cloudx-io/cloudx-ios'
  s.license = { :type => 'Business Source License 1.1', :file => 'LICENSE' }
  s.authors = { 'CloudX' => 'support@cloudx.com' }
  s.source = { :path => '.' }

  s.ios.deployment_target = '13.0'
  
  # Local distribution uses source files
  s.source_files = 'Sources/CloudXMintegralAdapter/**/*.{h,m}'
  s.public_header_files = 'Sources/CloudXMintegralAdapter/**/*.h'
  s.module_map = 'Sources/CloudXMintegralAdapter/module.modulemap'
  s.resource_bundles = {
    'CloudXMintegralAdapter' => ['Sources/CloudXMintegralAdapter/PrivacyInfo.xcprivacy']
  }

  s.dependency 'CloudXCore', '2.2.2'
  
  # Mintegral SDK 8.x with bidding support
  # Uses: MTGBannerAdView, MTGNewInterstitialBidAdManager, MTGBidRewardAdManager
  s.dependency 'MintegralAdSDK', '~> 8.0.8'
  s.dependency 'MintegralAdSDK/BidBannerAd', '~> 8.0.8'
  s.dependency 'MintegralAdSDK/BidNewInterstitialAd', '~> 8.0.8'
  s.dependency 'MintegralAdSDK/BidRewardVideoAd', '~> 8.0.8'

  s.frameworks = ['Foundation', 'UIKit', 'AdSupport', 'CoreGraphics', 'CoreTelephony', 'SystemConfiguration', 'AVFoundation', 'CoreMedia', 'QuartzCore', 'StoreKit', 'WebKit']
  s.weak_frameworks = ['AppTrackingTransparency']

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'CLANG_ENABLE_MODULES' => 'YES',
    'OTHER_CFLAGS' => '-fmodules',
    'ENABLE_USER_SCRIPT_SANDBOXING' => 'NO'
  }
  
  s.user_target_xcconfig = {
    'OTHER_LDFLAGS' => '-ObjC',
    'ENABLE_USER_SCRIPT_SANDBOXING' => 'NO'
  }
  
  s.requires_arc = true
  s.swift_version = '6.0'
end

