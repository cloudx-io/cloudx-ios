Pod::Spec.new do |s|
  s.name             = 'CloudXCore'
  s.version          = '1.2.0-test'
  s.summary          = 'CloudX Core Framework (XCFramework Binary)'
  s.description      = 'Core framework for CloudX functionality - local xcframework binary for testing'
  s.homepage         = 'https://github.com/cloudx-io/cloudx-ios'
  s.license          = { :type => 'Business Source License 1.1' }
  s.author           = { 'CloudX' => 'support@cloudx.io' }
  
  # Git source placeholder (not actually downloaded when using :podspec in Podfile)
  s.source           = { :git => 'https://github.com/cloudx-io/cloudx-ios.git', :tag => s.version.to_s }
  s.ios.deployment_target = '14.0'
  
  # Point to the xcframework relative to this podspec
  s.vendored_frameworks = 'CloudXCore.xcframework'
  
  s.frameworks = ['Foundation', 'SafariServices', 'UIKit', 'CoreLocation', 'WebKit', 'CoreData']
  
  s.pod_target_xcconfig = {
    'CLANG_ENABLE_MODULES' => 'YES',
    'ENABLE_USER_SCRIPT_SANDBOXING' => 'NO',
    'DEFINES_MODULE' => 'YES'
  }
  s.user_target_xcconfig = {
    'ENABLE_USER_SCRIPT_SANDBOXING' => 'NO'
  }
  
  s.swift_versions = ['5.0', '5.1', '5.2', '5.3', '5.4', '5.5', '5.6', '5.7', '5.8', '5.9', '6.0', '6.1', '6.2']
end

