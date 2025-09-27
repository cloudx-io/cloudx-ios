Pod::Spec.new do |s|
  s.name = 'CloudXCore'
  s.version = '1.1.53'
  s.summary = 'Local development only'
  s.description = 'NOTE: This podspec is for local development only'
  s.homepage = 'https://github.com/cloudx-io/cloudx-ios'
  s.license = { :type => 'Business Source License 1.1', :file => 'LICENSE' }
  s.authors = { 'CloudX' => 'support@cloudx.com' }
  s.platform = :ios, '14.0'
  s.module_name = 'CloudXCore'
  s.static_framework = true
  s.source = { :path => '.' }
  
  # LOCAL PATHS - no 'core/' prefix needed since we're already in core directory
  s.source_files = 'Sources/CloudXCore/**/*.{h,m}'
  s.public_header_files = 'Sources/CloudXCore/**/*.h'
  
  # Resource bundles
  s.resource_bundles = {
    'CloudXCore' => ['Sources/CloudXCore/AdReporting/CoreData/CloudXDataModel.xcdatamodeld']
  }
  
  s.framework = 'Foundation'
  s.frameworks = 'SafariServices', 'CoreData'
  
  # Enable module support for proper bracket imports
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'CLANG_ENABLE_MODULES' => 'YES',
    'ENABLE_USER_SCRIPT_SANDBOXING' => 'NO'
  }
  s.user_target_xcconfig = {
    'ENABLE_USER_SCRIPT_SANDBOXING' => 'NO'
  }
  
  # Swift version
  s.swift_versions = ['5.0', '5.1', '5.2', '5.3', '5.4', '5.5', '5.6', '5.7', '5.8', '5.9', '6.0', '6.1', '6.2']
end
