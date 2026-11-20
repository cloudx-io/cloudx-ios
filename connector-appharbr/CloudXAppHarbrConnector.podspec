Pod::Spec.new do |s|
  s.name             = 'CloudXAppHarbrConnector'
  s.version = '1.38.3.0'
  s.summary          = 'CloudX AppHarbr Connector - Static Framework'
  s.description      = 'AppHarbr ad-quality connector for CloudX iOS SDK - binary distribution. Sends each CloudX ad to AppHarbr for analysis; ads AppHarbr blocks are not shown.'
  s.homepage         = 'https://github.com/cloudx-io/cloudx-ios'
  s.license          = { :type => 'Business Source License 1.1' }
  s.author           = { 'CloudX' => 'support@cloudx.io' }
  s.source           = { :git => 'https://github.com/cloudx-io/cloudx-ios.git', :tag => "connector-appharbr/#{s.version}" }
  s.ios.deployment_target = '13.0'
  s.vendored_frameworks = 'connector-appharbr/CloudXAppHarbrConnector.xcframework'
  s.dependency 'CloudXCore', '>= 3.11.0'
  s.dependency 'AppHarbrSDK', '>= 1.38.3'
  s.frameworks = ['Foundation']
  s.requires_arc = true
  s.static_framework = true
  s.user_target_xcconfig = {
    'OTHER_LDFLAGS' => '-ObjC'
  }
  s.swift_versions = ['5.0', '5.1', '5.2', '5.3', '5.4', '5.5', '5.6', '5.7', '5.8', '5.9', '6.0', '6.1', '6.2']
end
