Pod::Spec.new do |s|
  s.name             = 'CloudXMagniteAdapterV2'
  s.version = '1.0.0.1'
  s.summary          = 'CloudX Magnite Adapter (independent versioning) - Static Framework'
  s.description      = 'Magnite adapter for CloudX iOS SDK - binary distribution. Supports Banner, MREC, Interstitial, and Rewarded formats via MagniteSDK. Independent-versioned successor to CloudXMagniteAdapter, which remains on the legacy unified version line.'
  s.homepage         = 'https://github.com/cloudx-io/cloudx-ios'
  s.license          = { :type => 'Business Source License 1.1' }
  s.author           = { 'CloudX' => 'support@cloudx.io' }
  s.source           = { :git => 'https://github.com/cloudx-io/cloudx-ios.git', :tag => "adapter-magnite/#{s.version}" }

  s.ios.deployment_target = '13.0'
  # The vendored framework/module is named CloudXMagniteAdapter (the pod is
  # independently versioned as V2, distinct from the legacy CloudXMagniteAdapter
  # unified-line pod). CocoaPods derives the -framework link flag from the
  # xcframework wrapper basename, so the wrapper MUST match the inner framework
  # name (CloudXMagniteAdapter). It lives in a CloudXMagniteAdapterV2/ subdir to
  # avoid colliding on disk with the legacy pod's CloudXMagniteAdapter.xcframework.
  s.vendored_frameworks = 'adapter-magnite/CloudXMagniteAdapterV2/CloudXMagniteAdapter.xcframework'

  # Dependencies
  s.dependency 'CloudXCore', '>= 3.5.0'
  s.dependency 'MagniteSDK', '= 1.0.0'

  s.frameworks = ['Foundation', 'UIKit', 'WebKit', 'AVFoundation', 'CoreMedia', 'CoreGraphics', 'CoreTelephony', 'SystemConfiguration', 'StoreKit', 'AdSupport', 'JavaScriptCore', 'QuartzCore', 'CoreFoundation', 'CoreAudio']
  s.weak_frameworks = ['AppTrackingTransparency']

  s.requires_arc = true
  s.static_framework = true

  s.pod_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }

  s.user_target_xcconfig = {
    'OTHER_LDFLAGS' => '-ObjC'
  }

  s.swift_version = '6.0'
end
