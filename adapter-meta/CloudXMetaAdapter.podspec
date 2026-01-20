Pod::Spec.new do |s|
  s.name = 'CloudXMetaAdapter'
  s.version = '2.0.0'
  s.summary = 'Mobile SDK for CloudX iOS Meta Adapter'
  s.description = 'iOS adapter add-on to the CloudX iOS SDK for a Meta bidder'
  s.homepage = 'https://github.com/cloudx-io/cloudx-ios'
  s.license = { :type => 'Business Source License 1.1', :file => 'LICENSE' }
  s.authors = { 'CloudX' => 'support@cloudx.com' }
  # For local development with :path in Podfile
  # Local development - no git source needed
  s.source = { :path => '.' }
  
  s.ios.deployment_target = '15.0'
  
  # LOCAL DEVELOPMENT: Build from source files
  s.source_files = 'Sources/CloudXMetaAdapter/**/*.{h,m}'
  s.public_header_files = 'Sources/CloudXMetaAdapter/**/*.h'
  
  s.dependency 'CloudXCore'
  s.dependency 'FBAudienceNetwork', '~> 6.21.0'
  s.frameworks = [
    'AVFoundation', 'AVKit', 'AdSupport', 'CoreGraphics', 'CoreLocation', 'CoreTelephony', 'Foundation', 'StoreKit', 'SystemConfiguration', 'UIKit'
  ]
  s.weak_frameworks = [
    'Combine', 'CryptoKit', 'SafariServices', 'SwiftUI', 'WebKit', 'FBAudienceNetwork'
  ]
  s.user_target_xcconfig = {
    'OTHER_LDFLAGS' => '-ObjC'
  }
  s.requires_arc = true
  
  # Swift version
  s.swift_version = '6.0'
end
