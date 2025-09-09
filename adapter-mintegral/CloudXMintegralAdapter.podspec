Pod::Spec.new do |s|
  s.name = 'CloudXMintegralAdapter'
  s.version = '1.0.0'
  s.summary = 'Mintegral Adapter for CloudX'
  s.description = 'Mintegral adapter for CloudX iOS SDK'
  s.homepage = 'https://github.com/cloudx-xenoss/CloudXMintegralAdapter'
  s.license = { :type => 'Copyright', :text => 'Copyright 2024 CloudX, Inc. All rights reserved.' }
  s.authors = { 'CloudX' => 'support@cloudx.com' }
  s.platform = :ios, '14.0'
  s.swift_version = '5.9'
  s.module_name = 'CloudXMintegralAdapter'
  
  # Source configuration
  s.source = {
    :git => 'https://github.com/cloudx-xenoss/CloudXMintegralAdapter.git',
    :tag => s.version.to_s
  }
  
  # Source files
  s.source_files = 'Sources/CloudXMintegralAdapter/**/*.{swift,h,m}'
  s.public_header_files = 'Sources/CloudXMintegralAdapter/**/*.h'
  
  # Dependencies
  s.dependency 'CloudXCore'
  s.dependency 'MintegralAdSDK', '7.6.8'
  
  # Build settings
  s.pod_target_xcconfig = {
    'VALID_ARCHS[sdk=iphoneos*]' => 'arm64 armv7',
    'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64 arm64',
    'ENABLE_USER_SCRIPT_SANDBOXING' => 'NO'
  }
  
  s.user_target_xcconfig = {
    'OTHER_LDFLAGS' => '-ObjC',
    'ENABLE_USER_SCRIPT_SANDBOXING' => 'NO'
  }
  
  s.requires_arc = true
end 