Pod::Spec.new do |s|
  s.name = 'CloudXMediationInMobiAdapter'
  s.version = '1.2.0'
  s.summary = 'InMobi adapter for CloudX iOS SDK - Industry standard mediation naming'
  s.description = 'iOS adapter for the CloudX SDK providing header bidding and waterfall support for InMobi advertising network'
  s.homepage = 'https://github.com/cloudx-io/cloudx-ios'
  s.license = { :type => 'Business Source License 1.1', :file => 'LICENSE' }
  s.authors = { 'CloudX' => 'support@cloudx.com' }
  s.source = { :path => '.' }
  
  s.ios.deployment_target = '14.0'
  
  # Local distribution uses source files
  s.source_files = 'Sources/CloudXMediationInMobiAdapter/**/*.{h,m}'
  s.public_header_files = 'Sources/CloudXMediationInMobiAdapter/**/*.h'
  s.module_map = 'Sources/CloudXMediationInMobiAdapter/module.modulemap'
  s.resource_bundles = {
    'CloudXMediationInMobiAdapter' => ['Sources/CloudXMediationInMobiAdapter/PrivacyInfo.xcprivacy']
  }
  
  s.dependency 'CloudXCore'
  s.dependency 'InMobiSDK', '~> 10.8'
  
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
  s.swift_versions = ['5.0', '5.1', '5.2', '5.3', '5.4', '5.5', '5.6', '5.7', '5.8', '5.9', '6.0', '6.1', '6.2']
end

