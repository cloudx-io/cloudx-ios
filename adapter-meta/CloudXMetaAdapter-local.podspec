Pod::Spec.new do |s|
  s.name = 'CloudXMetaAdapter'
  s.version = '1.1.68'
  s.summary = 'Mobile SDK for CloudX iOS Meta Adapter'
  s.description = 'iOS adapter add-on to the CloudX iOS SDK for a Meta bidder'
  s.homepage = 'https://github.com/cloudx-io/cloudx-ios'
  s.license = { :type => 'Business Source License 1.1', :file => 'LICENSE' }
  s.authors = { 'CloudX' => 'support@cloudx.com' }
  # For local development with :path in Podfile
  s.source = { :path => '.' }
  
  s.ios.deployment_target = '14.0'
  
  # LOCAL DEVELOPMENT: Build from source files
  s.source_files = 'Sources/CloudXMetaAdapter/**/*.{h,m}'
  s.public_header_files = 'Sources/CloudXMetaAdapter/**/*.h'
  
  # s.dependency "CloudXCore" # Manually linked as xcframework
  s.dependency 'FBAudienceNetwork', '~> 6.20.1'
  s.frameworks = [
    'AVFoundation', 'AVKit', 'AdSupport', 'CoreGraphics', 'CoreLocation', 'CoreTelephony', 'Foundation', 'StoreKit', 'SystemConfiguration', 'UIKit'
  ]
  s.weak_frameworks = [
    'Combine', 'CryptoKit', 'SafariServices', 'SwiftUI', 'WebKit', 'FBAudienceNetwork'
  ]
  s.pod_target_xcconfig = {
    'CLANG_ENABLE_MODULES' => 'YES',
    'ENABLE_USER_SCRIPT_SANDBOXING' => 'NO'
  }
  s.user_target_xcconfig = {
    'OTHER_LDFLAGS' => '-ObjC',
    'ENABLE_USER_SCRIPT_SANDBOXING' => 'NO'
  }
  s.requires_arc = true
  
  # Swift version
  s.swift_versions = ['5.0', '5.1', '5.2', '5.3', '5.4', '5.5', '5.6', '5.7', '5.8', '5.9', '6.0', '6.1', '6.2']
end
