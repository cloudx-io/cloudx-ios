# CloudXCore - Binary Framework Distribution

CloudXCore is the core SDK framework for CloudX, distributed as a pre-compiled dynamic XCFramework for iOS.

## 🚀 Features

- **Binary Distribution**: Pre-compiled xcframework for faster build times
- **Multi-Architecture Support**: Supports iOS device (arm64) and iOS Simulator (arm64, x86_64)
- **Swift & Objective-C Compatible**: Full interoperability with both languages
- **Modular Integration**: Works with CloudX adapters and other SDK components

## 📦 Installation

### CocoaPods

Add to your `Podfile`:

```ruby
pod 'CloudXCore', '~> 1.1.57'
```

Then run:

```bash
pod install
```

### Swift Package Manager

#### Via Xcode

1. In Xcode, go to **File → Add Package Dependencies**
2. Enter the repository URL: `https://github.com/cloudx-io/cloudx-ios`
3. Select the version you want to use
4. Add `CloudXCore` to your target

#### Via Package.swift

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/cloudx-io/cloudx-ios", from: "1.1.57")
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: [
            .product(name: "CloudXCore", package: "cloudx-ios")
        ]
    )
]
```

## 📋 Requirements

- iOS 14.0+
- Xcode 15.3+
- Swift 5.9+ (if using Swift)

## 🏗️ Architecture

CloudXCore is distributed as a **dynamic xcframework** containing:

- **iOS Device**: arm64 architecture
- **iOS Simulator**: arm64, x86_64 architectures

The framework includes:
- Compiled binary with optimized performance
- Module maps for Swift/Objective-C interoperability
- Header files for public API access
- Debug symbols uploaded to Sentry (not included in binary)

## 📚 Documentation

For detailed documentation, guides, and API references, visit:

- **Integration Guides**: [CloudX Documentation](https://docs.cloudx.io)
- **API Reference**: [CloudX iOS API Docs](https://docs.cloudx.io/ios)
- **GitHub Repository**: [cloudx-io/cloudx-ios](https://github.com/cloudx-io/cloudx-ios)

## 🔄 Release Process

CloudXCore follows semantic versioning (MAJOR.MINOR.PATCH):

- **MAJOR**: Breaking API changes
- **MINOR**: New features, backwards compatible
- **PATCH**: Bug fixes, backwards compatible

Releases are tagged with format: `v{VERSION}-core` (e.g., `v1.2.0-core`)

## 🔐 Binary Distribution Benefits

CloudXCore uses binary distribution for several reasons:

1. **Faster Build Times**: Pre-compiled binary reduces compilation time in your project
2. **IP Protection**: Source code is not exposed in the distributed framework
3. **Size Optimization**: Debug symbols are stripped and uploaded to Sentry separately
4. **Consistency**: All users get the exact same binary, reducing platform-specific build issues

## 🛠️ Troubleshooting

### Xcode Build Errors

If you encounter errors like "Building for iOS Simulator, but the linked framework was built for iOS":

1. Clean build folder: **Product → Clean Build Folder** (Shift + Cmd + K)
2. Delete derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData`
3. Ensure you're using Xcode 15.3+

### CocoaPods Integration Issues

If pod install fails:

```bash
pod repo update
pod cache clean --all
pod install --repo-update
```

### Swift Package Manager Issues

If SPM fails to resolve:

1. In Xcode: **File → Packages → Reset Package Caches**
2. Delete Package.resolved and re-add the package
3. Verify checksum matches in Package.swift

## 📄 License

CloudXCore is licensed under the Business Source License 1.1.

See [LICENSE](../LICENSE) for more information.

## 🤝 Support

For support, questions, or issues:

- **Email**: support@cloudx.io
- **Documentation**: https://docs.cloudx.io
- **GitHub Issues**: https://github.com/cloudx-io/cloudx-ios/issues

## 🔗 Related Packages

- **CloudXMetaAdapter**: Meta (Facebook) Audience Network adapter
- **CloudXInMobiAdapter**: InMobi adapter
- **CloudXVungleAdapter**: Vungle adapter
- **CloudX**: Main SDK adapter for CloudX mediation

---

**Note**: This is the binary distribution repository. Source code is maintained in a private repository. If you need access to source code for debugging or contribution, please contact support@cloudx.io.
