Pod::Spec.new do |s|
  s.name             = 'CloudXCore'
  s.version          = '1.1.40'
  s.summary          = 'CloudX Core Framework'
  s.description      = 'Core framework for CloudX functionality'
  s.homepage         = 'https://github.com/cloudx-io/cloudx-ios'
  s.license          = { :type => 'Business Source License 1.1', :file => 'core/LICENSE' }
  s.author           = { 'CloudX' => 'support@cloudx.io' }
  s.source           = { :git => 'https://github.com/cloudx-io/cloudx-ios.git', :tag => "v#{s.version}-core" }
  
  s.ios.deployment_target = '14.0'
  
  # Source files for distribution
  s.source_files = 'core/Sources/CloudXCore/**/*.{h,m}'
  
  # Resource bundles
  s.resource_bundles = {
    'CloudXCore' => ['core/Sources/CloudXCore/AdReporting/CoreData/CloudXDataModel.xcdatamodeld']
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
end 