Pod::Spec.new do |s|
  s.name             = 'CloudXCore'
  s.version          = '1.1.58'
  s.summary          = 'CloudX Core Framework'
  s.description      = 'Core framework for CloudX functionality'
  s.homepage         = 'https://github.com/cloudx-io/cloudx-ios'
  s.license          = { :type => 'Business Source License 1.1', :file => 'LICENSE' }
  s.author           = { 'CloudX' => 'support@cloudx.io' }
  s.source           = { :git => 'https://github.com/cloudx-io/cloudx-ios.git', :tag => "v#{s.version}-core" }
  
  s.ios.deployment_target = '14.0'
  
  # Source files for distribution
  s.source_files = 'Sources/CloudXCore/**/*.{h,m}'
  
  s.framework = 'Foundation'
  s.frameworks = 'SafariServices'
  
  # Configure for source-based distribution with proper header search paths
  s.pod_target_xcconfig = {
    'CLANG_ENABLE_MODULES' => 'YES',
    'ENABLE_USER_SCRIPT_SANDBOXING' => 'NO'
  }
  s.user_target_xcconfig = {
    'ENABLE_USER_SCRIPT_SANDBOXING' => 'NO'
  }
  
  # Swift version
  s.swift_versions = ['5.0', '5.1', '5.2', '5.3', '5.4', '5.5', '5.6', '5.7', '5.8', '5.9', '6.0', '6.1', '6.2']
end 