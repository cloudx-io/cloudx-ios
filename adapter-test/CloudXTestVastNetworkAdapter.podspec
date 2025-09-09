Pod::Spec.new do |s|
  s.name             = 'CloudXTestVastNetworkAdapter'
  s.version          = '1.0.0'
  s.summary          = 'CloudX Test Vast Network Demo Adapter (Objective-C)'
  s.description      = 'Demo/test ad network adapter for CloudXCore, Objective-C version.'
  s.homepage         = 'https://example.com'
  s.license          = { :type => 'Business Source License 1.1', :file => 'LICENSE' }
  s.author           = { 'Your Name' => 'your.email@example.com' }
  s.source           = { :path => '.' }

  s.ios.deployment_target = '14.0'
  s.frameworks = 'SafariServices'

  s.source_files = 'Sources/CloudXTestVastNetworkAdapter/**/*.{h,m}'
  s.public_header_files = 'Sources/CloudXTestVastNetworkAdapter/**/*.h'

  s.dependency 'CloudXCore'

  s.framework = 'Foundation'
  s.framework = 'UIKit'
  s.framework = 'WebKit'
  
  # Enable module support for proper bracket imports
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'CLANG_ENABLE_MODULES' => 'YES'
  }
end 