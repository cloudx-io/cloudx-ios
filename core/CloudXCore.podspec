Pod::Spec.new do |s|
  s.name             = 'CloudXCore'
  s.version = '2.0.0'
  s.summary          = 'CloudX Core Framework'
  s.description      = 'Core framework for CloudX functionality - local development version'
  s.homepage         = 'https://github.com/cloudx-io/cloudx-ios'
  s.license          = { :type => 'Business Source License 1.1' }
  s.author           = { 'CloudX' => 'support@cloudx.io' }
  # Local development - no git source needed
  s.source           = { :path => '.' }
  
  s.ios.deployment_target = '15.0'
  
  # Source files for local development - relative to this podspec location
  s.source_files = 'Sources/CloudXCore/**/*.{h,m}'
  s.public_header_files = 'Sources/CloudXCore/**/*.h'
  
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
