Pod::Spec.new do |s|
  s.name = 'CloudXMetaAdapter'
  s.version = '1.1.3'
  s.summary = 'Meta (Facebook) Adapter for CloudX iOS SDK'
  s.description = 'Meta adapter for CloudX iOS SDK'
  s.homepage = 'https://github.com/cloudx-xenoss/CloudXMetaAdapter'
  s.license = { :type => 'Copyright', :text => 'Copyright 2024 CloudX, Inc. All rights reserved.' }
  s.authors = { 'CloudX' => 'support@cloudx.com' }
  s.platform = :ios, '14.0'
  s.swift_version = '5.9'
  s.module_name = 'CloudXMetaAdapter'
  s.source = { :path => '.' }
  
  # Source files
  s.source_files = 'Sources/CloudXMetaAdapter/**/*.{h,m}'
  
  # Public headers
  s.public_header_files = 'Sources/CloudXMetaAdapter/**/*.h'
  
  s.dependency 'CloudXCore'
  s.dependency 'FBAudienceNetwork', '6.16.0'
  
  s.framework = 'Foundation'
  s.framework = 'UIKit'
  s.framework = 'WebKit'
  
  # Enable module support for proper bracket imports
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'CLANG_ENABLE_MODULES' => 'YES'
  }
  
  # Handle static framework dependencies
  s.user_target_xcconfig = {
    'OTHER_LDFLAGS' => '-ObjC'
  }
  
  s.requires_arc = true
end 