# ✅ CloudXMintegralAdapter

CloudXMintegralAdapter iOS internal repo. The code is packaged as a framework and then released externally from the following public repo `https://github.com/cloudx-xenoss/CloudXiOSMintegralAdapter`

# ✅ CloudXMintegralAdapter Release Steps

Create `CloudXMintegralAdapter.xcframework.zip` and release it to the public facing repo. Update the podspec and Package.json to support installation via Cocoapods and Swift Package Manager in addition to manual download. 

# ✅ Create the framework and zip it up

Create and zip the framework in this repo from your terminal

### ✅ 1. Setup

- Navigate to repo `cloudexchange.sdk.ios.mintegralAdapter`  
- Install pods:

```sh
pod install
```

---

### ✅ 2. Build Static Framework for Device

```sh
xcodebuild archive \
  -workspace CloudXMintegralAdapter.xcworkspace \
  -scheme CloudXMintegralAdapter \
  -destination "generic/platform=iOS" \
  -archivePath ./build/ios_devices.xcarchive \
  -configuration Release \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  CODE_SIGNING_ALLOWED=NO
```

---

### ✅ 3. Build Static Framework for Simulator

```sh
xcodebuild archive \
  -workspace CloudXMintegralAdapter.xcworkspace \
  -scheme CloudXMintegralAdapter \
  -destination "generic/platform=iOS Simulator" \
  -archivePath ./build/ios_simulator.xcarchive \
  -configuration Release \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  CODE_SIGNING_ALLOWED=NO
```

---

### ✅ 4. Create `.xcframework`

```sh
xcodebuild -create-xcframework \
  -framework ./build/ios_devices.xcarchive/Products/Library/Frameworks/CloudXMintegralAdapter.framework \
  -framework ./build/ios_simulator.xcarchive/Products/Library/Frameworks/CloudXMintegralAdapter.framework \
  -output ./CloudXMintegralAdapter.xcframework
```

---

### ✅ 5. Zip `.xcframework`

```sh
zip -r CloudXMintegralAdapter.xcframework.zip CloudXMintegralAdapter.xcframework
```

# ✅ Create the external release

Create a release in the public repo `https://github.com/cloudx-xenoss/CloudXiOSMintegralAdapter` by using the framework from the previous steps and then updating the podspec and `Package.swift`.

### ✅ 1. Update `CloudXMintegralAdapter.podspec.json`

- Set `version`: **1.0.0**  
- Update `.source.http` to:

```json
https://github.com/cloudx-xenoss/CloudXiOSMintegralAdapter/releases/download/1.0.0/CloudXMintegralAdapter.xcframework.zip
```

---

### ✅ 2. Update `Package.swift`

- Set the URL to:

```sh
https://github.com/cloudx-xenoss/CloudXiOSMintegralAdapter/releases/download/1.0.0/CloudXMintegralAdapter.xcframework.zip
```

- Compute and update the checksum:

```sh
swift package compute-checksum CloudXMintegralAdapter.xcframework.zip
```

---

### ✅ 3. Host in Public GitHub Repo

- Repo: [cloudx-xenoss/CloudXiOSMintegralAdapter](https://github.com/cloudx-xenoss/CloudXiOSMintegralAdapter)
- Create a **new Release**
  - Attach: `CloudXMintegralAdapter.xcframework.zip`
  - Check: ✅ *Set as the latest release*
  - Click **Publish**

---

### ✅ 4. Deploy to CocoaPods

```sh
cd path/to/CloudXiOSMintegralAdapter
pod trunk push
```

> ⚠️ Make sure that:
> - `CloudXMintegralAdapter.podspec` matches the release version (e.g., **1.0.0**)  
> - GitHub release **tag** matches `s.version`
