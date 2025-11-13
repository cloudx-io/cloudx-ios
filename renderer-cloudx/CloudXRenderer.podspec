Pod::Spec.new do |s|
  s.name = 'CloudXRenderer'
  s.version = '1.2.0'
  s.summary = 'CloudX Renderer for in-house and third-party demand sources'
  s.description = 'CloudX renderer for rendering ad markup from CloudX or third-party demand sources'
  s.homepage = 'https://github.com/cloudx-xenoss/CloudXRenderer'
  s.license = { :type => 'Business Source License 1.1', :file => 'LICENSE' }
  s.authors = { 'CloudX' => 'support@cloudx.com' }
  s.platform = :ios, '14.0'
  s.module_name = 'CloudXRenderer'
  
  # Source configuration
  s.source = {
    :git => 'https://github.com/cloudx-xenoss/CloudXRenderer.git',
    :tag => s.version.to_s
  }
  
  # Source files
  s.source_files = 'Sources/CloudXRenderer/**/*.{h,m}'
  s.public_header_files = 'Sources/CloudXRenderer/**/*.h'
  
  # Dependencies
  s.dependency 'CloudXCore'
  
  # Build settings
  s.pod_target_xcconfig = {
    'VALID_ARCHS[sdk=iphoneos*]' => 'arm64 armv7',
    'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64 arm64'
  }
  
  s.user_target_xcconfig = {
    'OTHER_LDFLAGS' => '-ObjC'
  }
  
  s.requires_arc = true
end 