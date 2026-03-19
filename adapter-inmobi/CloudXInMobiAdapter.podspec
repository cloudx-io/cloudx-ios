Pod::Spec.new do |s|
  s.name = 'CloudXInMobiAdapter'
  s.version = '2.2.3'
  s.summary = 'InMobi adapter for CloudX iOS SDK - Industry standard mediation naming'
  s.description = 'iOS adapter for the CloudX SDK providing header bidding and waterfall support for InMobi advertising network'
  s.homepage = 'https://github.com/cloudx-io/cloudx-ios'
  s.license = { :type => 'Business Source License 1.1', :file => 'LICENSE' }
  s.authors = { 'CloudX' => 'support@cloudx.com' }
  s.source = { :path => '.' }
  
  s.ios.deployment_target = '13.0'
  
  # Local distribution uses source files
  s.source_files = 'Sources/CloudXInMobiAdapter/**/*.{h,m}'
  s.public_header_files = 'Sources/CloudXInMobiAdapter/**/*.h'
  s.module_map = 'Sources/CloudXInMobiAdapter/module.modulemap'
  s.resource_bundles = {
    'CloudXInMobiAdapter' => ['Sources/CloudXInMobiAdapter/PrivacyInfo.xcprivacy']
  }
  
  s.dependency 'CloudXCore', s.version.to_s
  s.dependency 'InMobiSDK', '~> 11.1'
  
  s.frameworks = [
    'AVFoundation', 'AdSupport', 'CoreGraphics', 'CoreTelephony', 'Foundation', 'StoreKit', 'SystemConfiguration', 'UIKit', 'WebKit'
  ]
  
  s.pod_target_xcconfig = {
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
  s.swift_version = '6.0'
end

