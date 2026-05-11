Pod::Spec.new do |s|
  s.name             = 'CloudXRenderer'
  s.version = '3.3.0-beta'
  s.summary          = 'CloudX Renderer Framework - Dynamic Framework'
  s.description      = 'Rendering engine for CloudX iOS SDK - binary distribution as dynamic framework'
  s.homepage         = 'https://github.com/cloudx-io/cloudx-ios'
  s.license          = { :type => 'Business Source License 1.1' }
  s.author           = { 'CloudX' => 'support@cloudx.io' }
  s.source           = { :git => 'https://github.com/cloudx-io/cloudx-ios.git', :tag => "v#{s.version}" }
  
  s.ios.deployment_target = '13.0'
  s.vendored_frameworks = 'renderer-cloudx/CloudXRenderer.xcframework'
  
  # Dependencies
  s.dependency 'CloudXCore', '3.3.0-beta'
  
  s.frameworks = ['Foundation', 'UIKit', 'WebKit', 'AVFoundation', 'AVKit']
  s.weak_frameworks = ['SafariServices']
  
  s.requires_arc = true
  
  # Static framework with -ObjC for OMSDK categories (mirrors AppLovin setup)
  s.pod_target_xcconfig = {
    'OTHER_LDFLAGS' => '-ObjC'
  }
  
  s.user_target_xcconfig = {
    'OTHER_LDFLAGS' => '-ObjC'
  }
  
  s.swift_versions = ['5.0', '5.1', '5.2', '5.3', '5.4', '5.5', '5.6', '5.7', '5.8', '5.9', '6.0', '6.1', '6.2']
end


