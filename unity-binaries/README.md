# CloudX SDK RC 2.0.0 - Pre-built Binaries for Unity iOS

This folder contains pre-built xcframeworks and podspecs for integrating CloudX SDK into Unity iOS projects.

## Contents

- `CloudXCore.xcframework` - Core SDK framework
- `CloudXRenderer.xcframework` - Ad rendering framework  
- `CloudXVungleAdapter.xcframework` - Vungle adapter
- `CloudXMetaAdapter.xcframework` - Meta (Facebook) adapter
- `CloudXInMobiAdapter.xcframework` - InMobi adapter
- `CloudXMintegralAdapter.xcframework` - Mintegral adapter
- Matching `.podspec` files for each framework

## Setup Instructions

### 1. Copy this folder to your Unity iOS export

After exporting your Unity project to Xcode, copy this entire `unity-binaries/` folder into the exported iOS project directory.

### 2. Update your Podfile

Add the following to your Podfile:

```ruby
platform :ios, '15.0'

target 'Unity-iPhone' do
  use_frameworks! :linkage => :static

  # CloudX SDK - RC 2.0.0 local binaries
  pod 'CloudXCore', :path => 'unity-binaries'
  pod 'CloudXRenderer', :path => 'unity-binaries'
  pod 'CloudXVungleAdapter', :path => 'unity-binaries'
  pod 'CloudXMetaAdapter', :path => 'unity-binaries'
  pod 'CloudXInMobiAdapter', :path => 'unity-binaries'
  pod 'CloudXMintegralAdapter', :path => 'unity-binaries'

end
```

### 3. Run pod install

```bash
cd /path/to/unity/ios/export
pod install
```

### 4. Open the workspace

```bash
open Unity-iPhone.xcworkspace
```

## Notes

- These are **pre-compiled binaries** (xcframeworks), not source code
- This should work the same as installing from CocoaPods Trunk
- The `:path` directive tells CocoaPods to use local podspecs which reference local xcframeworks
- Version: `2.0.0-rc.47+89a05d4`
