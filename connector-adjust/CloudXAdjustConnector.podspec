Pod::Spec.new do |s|
  s.name             = 'CloudXAdjustConnector'
  s.version = '5.0.0.0'
  s.summary          = 'CloudX Adjust Connector - Static Framework'
  s.description      = 'Adjust ad-revenue connector for CloudX iOS SDK - binary distribution. Forwards CloudX ad revenue to Adjust via trackAdRevenue.'
  s.homepage         = 'https://github.com/cloudx-io/cloudx-ios'
  s.license          = { :type => 'Business Source License 1.1' }
  s.author           = { 'CloudX' => 'support@cloudx.io' }
  s.source           = { :git => 'https://github.com/cloudx-io/cloudx-ios.git', :tag => "connector-adjust/#{s.version}" }
  s.ios.deployment_target = '13.0'
  s.vendored_frameworks = 'connector-adjust/CloudXAdjustConnector.xcframework'
  s.dependency 'CloudXCore', '>= 3.6.0'
  s.dependency 'Adjust', '>= 5.0.0'
  s.frameworks = ['Foundation']
  s.requires_arc = true
  s.static_framework = true
  s.user_target_xcconfig = {
    'OTHER_LDFLAGS' => '-ObjC'
  }
  s.swift_versions = ['5.0', '5.1', '5.2', '5.3', '5.4', '5.5', '5.6', '5.7', '5.8', '5.9', '6.0', '6.1', '6.2']
end
