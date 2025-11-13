Pod::Spec.new do |s|
  s.name             = 'CloudXCore'
  s.version          = '1.2.0'
  s.summary          = 'CloudX Core Framework'
  s.description      = 'Core framework for CloudX functionality - binary distribution'
  s.homepage         = 'https://github.com/cloudx-io/cloudx-ios'
  s.license          = { :type => 'Business Source License 1.1' }
  s.author           = { 'CloudX' => 'support@cloudx.io' }
  s.source           = { :git => 'https://github.com/cloudx-io/cloudx-ios.git', :tag => "v#{s.version}-core" }
  
  s.ios.deployment_target = '14.0'
  s.vendored_frameworks = 'core/CloudXCore.xcframework'
  
  s.frameworks = ['Foundation', 'SafariServices', 'UIKit', 'CoreLocation', 'WebKit', 'CoreData']
  s.requires_arc = true
  s.static_framework = false
  
  s.pod_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'ENABLE_USER_SCRIPT_SANDBOXING' => 'NO'
  }
  
  s.user_target_xcconfig = {
    'ENABLE_USER_SCRIPT_SANDBOXING' => 'NO'
  }
  
  s.swift_versions = ['5.0', '5.1', '5.2', '5.3', '5.4', '5.5', '5.6', '5.7', '5.8', '5.9', '6.0', '6.1', '6.2']
end
