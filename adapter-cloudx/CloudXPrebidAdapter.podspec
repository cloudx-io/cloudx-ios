Pod::Spec.new do |s|
  s.name = 'CloudXPrebidAdapter'
  s.version = '1.2.0'
  s.summary = 'CloudX Prebid Adapter for in-house demand sources'
  s.description = 'Prebid adapter for CloudX iOS SDK for rendering ad markup from CloudX demand sources'
  s.homepage = 'https://github.com/cloudx-io/cloudx-ios'
  s.license = { :type => 'Business Source License 1.1', :file => 'LICENSE' }
  s.authors = { 'CloudX' => 'support@cloudx.com' }
  s.platform = :ios, '14.0'
  s.module_name = 'CloudXPrebidAdapter'
  s.source = { :path => '.' }
  
  # Source files for local development
  s.source_files = 'Sources/CloudXPrebidAdapter/**/*.{h,m}'
  s.public_header_files = 'Sources/CloudXPrebidAdapter/**/*.h'
  
  # Dependencies
  s.dependency 'CloudXCore'
  s.dependency 'CloudXRenderer'
  
  # Build settings
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'CLANG_ENABLE_MODULES' => 'YES'
  }
  
  s.user_target_xcconfig = {
    'OTHER_LDFLAGS' => '-ObjC'
  }
  
  s.requires_arc = true
  s.swift_versions = ['5.0', '5.1', '5.2', '5.3', '5.4', '5.5', '5.6', '5.7', '5.8', '5.9', '6.0', '6.1', '6.2']
end

