Pod::Spec.new do |s|
  s.name             = 'CloudXCore'
  s.version          = '1.1.34'
  s.summary          = 'CloudX Core Framework'
  s.description      = 'Core framework for CloudX functionality'
  s.homepage         = 'https://github.com/cloudx-xenoss/CloudXCoreiOS'
  s.license          = { :type => 'Business Source License 1.1', :file => 'LICENSE' }
  s.author           = { 'CloudX' => 'support@cloudx.io' }
  s.source           = { :http => 'https://github.com/cloudx-xenoss/CloudXCoreiOS/releases/download/v1.1.4/CloudXCore.xcframework.zip' }
  
  s.ios.deployment_target = '14.0'
  
  # Source files for local development
  s.source_files = 'Sources/CloudXCore/**/*.{h,m}'
  
  # This may only be necessary when doing local development (b/c local development needs the podfile to declare static frameworks)
  s.resource_bundles = {
    'CloudXCore' => ['Sources/CloudXCore/AdReporting/CoreData/CloudXDataModel.xcdatamodeld']
  }
  
  s.framework = 'Foundation'
  s.frameworks = 'SafariServices', 'CoreData'
  
  # Enable module support for proper bracket imports
  s.pod_target_xcconfig = {
    'HEADER_SEARCH_PATHS' => '$(PODS_ROOT)/CloudXCore/Sources/CloudXCore',
    'DEFINES_MODULE' => 'YES',
    'CLANG_ENABLE_MODULES' => 'YES',
    'ENABLE_USER_SCRIPT_SANDBOXING' => 'NO'
  }
  s.user_target_xcconfig = {
    'ENABLE_USER_SCRIPT_SANDBOXING' => 'NO'
  }
  
  # Use vendored framework for remote builds, source files for local development
  # s.vendored_frameworks = 'CloudXCore.xcframework'
end 