Pod::Spec.new do |s|
  s.name = 'CloudXMolocoAdapter'
  s.version = '1.3.0'
  s.summary = 'CloudX Adapter for Moloco iOS SDK'
  s.description = 'iOS adapter add-on to the CloudX iOS SDK for Moloco bidding'
  s.homepage = 'https://github.com/cloudx-io/cloudx-ios'
  s.license = { :type => 'Business Source License 1.1', :file => 'LICENSE' }
  s.authors = { 'CloudX' => 'support@cloudx.com' }
  # For local development with :path in Podfile
  s.source = { :path => '.' }
  
  s.ios.deployment_target = '13.0'
  
  # LOCAL DEVELOPMENT: Build from source files
  s.source_files = 'Sources/CloudXMolocoAdapter/**/*.{h,m}'
  s.public_header_files = 'Sources/CloudXMolocoAdapter/**/*.h'
  
  s.dependency 'CloudXCore'
  s.dependency 'MolocoSDK', '~> 1.0'
  
  s.frameworks = ['Foundation', 'UIKit', 'AdSupport', 'CoreGraphics', 'CoreTelephony', 'SystemConfiguration']
  s.weak_frameworks = ['AppTrackingTransparency']
  
  s.user_target_xcconfig = {
    'OTHER_LDFLAGS' => '-ObjC'
  }
  
  s.requires_arc = true
  s.swift_versions = ['5.0', '5.1', '5.2', '5.3', '5.4', '5.5', '5.6', '5.7', '5.8', '5.9', '6.0', '6.1', '6.2']
end

