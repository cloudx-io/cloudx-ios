Pod::Spec.new do |s|
  s.name = 'CloudXMetaAdapter'
  s.version = '1.1.25'
  s.summary = 'Mobile SDK for CloudX iOS Meta Adapter'
  s.description = 'iOS adapter add-on to the CloudX iOS SDK for a Meta bidder'
  s.homepage = 'https://github.com/cloudx-io/cloudx-ios'
  s.license = { :type => 'Business Source License 1.1', :file => 'LICENSE' }
  s.authors = { 'CloudX' => 'support@cloudx.com' }
  s.platform = :ios, '14.0'
  s.module_name = 'CloudXMetaAdapter'
  s.static_framework = true
  s.source = { :path => '.' }
  s.source_files = 'Sources/**/*.{h,m}'
  s.public_header_files = 'Sources/**/*.h'
  s.dependency 'CloudXCore'
  s.dependency 'FBAudienceNetwork', '~> 6.16.0'
  s.frameworks = [
    'AVFoundation', 'AVKit', 'AdSupport', 'CoreGraphics', 'CoreLocation', 'CoreTelephony', 'Foundation', 'StoreKit', 'SystemConfiguration', 'UIKit'
  ]
  s.weak_frameworks = [
    'Combine', 'CryptoKit', 'SafariServices', 'SwiftUI', 'WebKit', 'FBAudienceNetwork'
  ]
  s.pod_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64',
    'FRAMEWORK_SEARCH_PATHS' => '$(PODS_ROOT)/CloudXMetaAdapter',
    'OTHER_LDFLAGS' => '-framework CloudXMetaAdapter',
    'DEFINES_MODULE' => 'YES',
    'CLANG_ENABLE_MODULES' => 'YES',
    'OTHER_CFLAGS' => '-fmodules'
  }
  s.user_target_xcconfig = {
    'OTHER_LDFLAGS' => '-ObjC'
  }
  s.requires_arc = true
end
