# Distribution podspec for the public cloudx-ios repo — binary, not source.
#
# This file is the template for what cloudx-ios carries as
# `integration-gam-prebid/CloudXGAMPrebid.podspec`. It is NOT used to build or lint from this
# private tree; `CloudXGAMPrebid.podspec` beside it is the source-mode spec for local
# development and `pod lib lint`. Copy this one across at release time, together with the
# xcframework, and keep s.version equal to integrations.gam-prebid.version in
# release/versions.json.
Pod::Spec.new do |s|
  s.name             = 'CloudXGAMPrebid'
  s.version = '1.0.0'
  s.summary          = 'CloudX iOS Google Ad Manager prebid integration - Static Framework'
  s.description      = 'A zero-SDK facade integration for the CloudX iOS SDK that lets publishers surface CloudX demand as prebid line items in Google Ad Manager - binary distribution. Supports Banner, MREC, Interstitial, Rewarded, and Native ad formats.'
  s.homepage         = 'https://github.com/cloudx-io/cloudx-ios'
  s.license          = { :type => 'Business Source License 1.1' }
  s.author           = { 'CloudX' => 'support@cloudx.io' }
  s.source           = { :git => 'https://github.com/cloudx-io/cloudx-ios.git', :tag => "integration-gam-prebid/#{s.version}" }
  s.ios.deployment_target = '13.0'
  s.vendored_frameworks = 'integration-gam-prebid/CloudXGAMPrebid.xcframework'

  # 3.8.0 is the published core that ships the integration telemetry bridge; RELEASES.md
  # explains why this floor is load-bearing. GMA is a major-compatible floor: the mediation
  # adapter protocols this pod implements are stable within a major but not across one, so
  # every new GMA major needs a compatibility check before the floor widens to it.
  s.dependency 'CloudXCore', '>= 3.8.0'
  s.dependency 'Google-Mobile-Ads-SDK', '~> 13.0'

  s.frameworks = ['Foundation']
  # GoogleMobileAds is linked weakly: the publisher already integrates and initializes GMA, so we
  # bind against it without forcing a load-time hard dependency on this pod.
  s.weak_frameworks = ['GoogleMobileAds']

  s.requires_arc = true
  s.static_framework = true

  # -ObjC ensures the integration's +load runs in the host app so it self-registers with CloudXCore.
  s.user_target_xcconfig = {
    'OTHER_LDFLAGS' => '-ObjC'
  }
  s.swift_versions = ['5.0', '5.1', '5.2', '5.3', '5.4', '5.5', '5.6', '5.7', '5.8', '5.9', '6.0', '6.1', '6.2']
end
