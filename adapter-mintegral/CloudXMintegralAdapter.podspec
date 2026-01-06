Pod::Spec.new do |s|
  s.name = 'CloudXMintegralAdapter'
  s.version = '1.3.0'
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
  s.source = { :git => 'https://github.com/cloudx-io/cloudx-ios.git', :tag => s.version.to_s }

  s.ios.deployment_target = '15.0'
  s.source_files = 'Sources/CloudXMintegralAdapter/**/*.{h,m}'
  s.public_header_files = 'Sources/CloudXMintegralAdapter/**/*.h'
  s.resource_bundles = {
    'CloudXMintegralAdapter' => ['Sources/CloudXMintegralAdapter/PrivacyInfo.xcprivacy']
  }

  s.dependency 'CloudXCore'
  
  # Mintegral SDK 8.x with bidding support
  # Uses newer SDK modules: MTGNewInterstitialBidAdManager, MTGBidRewardAdManager singleton
  s.dependency 'MintegralAdSDK', '~> 8.0'
  s.dependency 'MintegralAdSDK/BannerAd', '~> 8.0'
  s.dependency 'MintegralAdSDK/BidInterstitialVideoAd', '~> 8.0'
  s.dependency 'MintegralAdSDK/BidRewardVideoAd', '~> 8.0'

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
  s.swift_version = '6.0'
end

