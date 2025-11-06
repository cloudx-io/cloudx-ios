Pod::Spec.new do |s|
  s.name = 'CloudXVungleAdapter'
  s.version = '1.0.0'
  s.summary = 'Mobile SDK for CloudX iOS Vungle Adapter'
  s.description = 'iOS adapter add-on to the CloudX iOS SDK for Vungle bidder supporting all ad formats'
  s.homepage = 'https://github.com/cloudx-io/cloudx-ios'
  s.license = { :type => 'Business Source License 1.1', :file => 'LICENSE' }
  s.authors = { 'CloudX' => 'support@cloudx.com' }
  s.source = {
    :http => "https://github.com/cloudx-io/cloudx-ios/releases/download/v#{s.version}-vungle/CloudXVungleAdapter-v#{s.version}.xcframework.zip",
    :type => "zip",
    :flatten => false
  }
  
  s.ios.deployment_target = '12.0'
  
  # Remote distribution uses vendored frameworks (binary)
  s.vendored_frameworks = 'CloudXVungleAdapter.xcframework'
  s.preserve_paths = 'CloudXVungleAdapter.xcframework'
  
  s.dependency 'CloudXCore'
  s.dependency 'VungleAds', '~> 7.4.0'
  s.frameworks = [
    'Foundation', 'UIKit', 'WebKit', 'AVFoundation', 'CoreMedia', 'AudioToolbox', 'CFNetwork', 'CoreGraphics', 'CoreTelephony', 'SystemConfiguration', 'StoreKit'
  ]
  s.pod_target_xcconfig = {
    'FRAMEWORK_SEARCH_PATHS' => '$(PODS_ROOT)/CloudXVungleAdapter',
    'OTHER_LDFLAGS' => '-framework CloudXVungleAdapter',
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
  
  # Swift version
  s.swift_versions = ['5.0', '5.1', '5.2', '5.3', '5.4', '5.5', '5.6', '5.7', '5.8', '5.9', '6.0', '6.1', '6.2']
end

