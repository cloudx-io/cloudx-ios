# CloudXCore

CloudXCore iOS internal repo. The code is packaged as a framework and then released externally from the following public repo `https://github.com/cloudx-xenoss/CloudXiOSCore`


## 📄 Documentation

Docs are stored in the repo at `cloudexchange.sdk.ios.core/Sources/CloudXCore/CloudXCore.docc`

To view the docs in XCode, open `CloudXCore.xcodeproj` and press `cmd+shift+d`

Docs should be generated as part of the CI/CD github action flow kicked off by pushing a tag (see CloudXCore Release Steps section below)

### 📊 Metrics System

The CloudX iOS SDK includes a comprehensive metrics tracking system that provides full parity with the Android implementation. See [METRICS_ARCHITECTURE.md](METRICS_ARCHITECTURE.md) for detailed documentation.

**Key Features:**
- Tracks SDK method calls and network performance
- SQLite-based persistence with automatic aggregation
- XOR-encrypted bulk metric submission
- Server-configurable enablement/disablement
- Full Android parity for metric types and behavior

**Quick Setup:**
```objective-c
// Metrics are automatically enabled when SDK is initialized
// Configure via server-side CLXSDKConfig.metricsConfig
// Enable debug logging with CLOUDX_VERBOSE_LOG=1
```

#### A. Fully local build/host for docs:

Run script
```
docs_local.sh 
```

Then open
```
http://localhost:8080/documentation/cloudxcore/
```

#### B. Mimic remote hosting via local build for docs:

Run script
```
./docs_proxy.sh
```

And then open
```
http://localhost:8080/CloudXCoreiOS/
```



## 🛠️ CloudXCore Release Steps

GitHub Actions are hooked up to automate a release via the script at `.github/workflows/release.yml`.

Whenever a tag is created and pushed, the core SDK will automatically be packaged as an .xcframework and deployed to the public core repo [CloudXCoreiOS Public Repo](https://github.com/cloudx-xenoss/CloudXCoreiOS)

Choose the next version then execute the following to create a public facing release:

⚠️ the tag name must be in this exact format (including the 'v')
```
git tag v*.*.*
git push origin v*.*.*
```

