Pod::Spec.new do |s|
  s.name = 'CloudXDSPAdapter'
  s.version = '1.0.0'
  s.summary = 'DSP Adapter for CloudX'
  s.description = 'DSP adapter for CloudX iOS SDK'
  s.homepage = 'https://github.com/cloudx-xenoss/CloudXDSPAdapter'
  s.license = { :type => 'Copyright', :text => 'Copyright 2024 CloudX, Inc. All rights reserved.' }
  s.authors = { 'CloudX' => 'support@cloudx.com' }
  s.platform = :ios, '14.0'
  s.swift_version = '5.9'
  s.module_name = 'CloudXDSPAdapter'
  
  # Source configuration
  s.source = {
    :git => 'https://github.com/cloudx-xenoss/CloudXDSPAdapter.git',
    :tag => s.version.to_s
  }
  
  # Source files
  s.source_files = 'Sources/CloudXDSPAdapter/**/*.{swift,h,m}'
  s.public_header_files = 'Sources/CloudXDSPAdapter/**/*.h'
  
  # Dependencies
  s.dependency 'CloudXCore'
  
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