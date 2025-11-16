Pod::Spec.new do |s|
  s.name = 'CloudXMolocoAdapter'
  s.version = '1.0.0'
  s.summary = 'CloudX Adapter for Moloco iOS SDK'
  s.description = 'Pre-built xcframework for CloudX Moloco adapter'
  s.homepage = 'https://github.com/cloudx-io/cloudx-ios'
  s.license = { :type => 'Business Source License 1.1', :file => 'LICENSE' }
  s.authors = { 'CloudX' => 'support@cloudx.com' }
  s.source = {
    :http => "https://github.com/cloudx-io/cloudx-ios/releases/download/v#{s.version}-moloco/CloudXMolocoAdapter-v#{s.version}.xcframework.zip",
    :type => "zip",
    :flatten => false
  }

  s.ios.deployment_target = '14.0'
  
  s.vendored_frameworks = 'CloudXMolocoAdapter.xcframework'
  s.preserve_paths = 'CloudXMolocoAdapter.xcframework'

  s.dependency 'CloudXCore'
  s.dependency 'MolocoSDK', '~> 1.0'

  s.frameworks = ['Foundation', 'UIKit', 'AdSupport', 'CoreGraphics', 'CoreTelephony', 'SystemConfiguration']
  s.weak_frameworks = ['AppTrackingTransparency']

  s.pod_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64',
    'FRAMEWORK_SEARCH_PATHS' => '$(PODS_ROOT)/CloudXMolocoAdapter',
    'OTHER_LDFLAGS' => '-framework CloudXMolocoAdapter',
    'DEFINES_MODULE' => 'YES'
  }
  
  s.user_target_xcconfig = {
    'OTHER_LDFLAGS' => '-ObjC'
  }
  
  s.requires_arc = true
  s.swift_versions = ['5.0', '5.1', '5.2', '5.3', '5.4', '5.5', '5.6', '5.7', '5.8', '5.9', '6.0', '6.1', '6.2']
end

