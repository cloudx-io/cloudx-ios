# ✅ CloudXMetaAdapter

CloudXMetaAdapter iOS internal repo. The code is packaged as a framework and then released externally from the following public repo `https://github.com/cloudx-xenoss/CloudXiOSMetaAdapter`

# ✅ CloudXMetaAdapter Release Steps

Create the `CloudXMetaAdapter.xcframework.zip` and release it to the public facing repo. Update the podspec and Package.json to support installation via Cocoapods and Swift Package Manager in addition manual download. 

# ✅ Create the framework and zip it up

Create and zip the framework in this repo from your terminal

### ✅ 1. Setup

- Navigate to repo `cloudexchange.sdk.ios.metaAdapter`  

If needed, first execute
```
chmod +x build_frameworks.sh
```

Then run the build_frameworks script to create and zip up both a static framework (for pods) and a dynamic framework (for SPM)
```
./build_frameworks.sh
```

# ✅ Create the external release

Create a release in the public repo `https://github.com/cloudx-xenoss/CloudXiOSMetaAdapter` by using the framework from the previous steps and then updating the podspec and Package.swift

### ✅ 1. Update `CloudXMetaAdapter.podspec.json`

- Set `version`: **1.0.0**  
- Update `.source.http` to:

```json
https://github.com/cloudx-xenoss/CloudXiOSMetaAdapter/releases/download/1.0.0/CloudXMetaAdapter.xcframework.zip
```

---

### ✅ 2. Update `Package.swift`

- Set the URL to:

```sh
https://github.com/cloudx-xenoss/CloudXiOSMetaAdapter/releases/download/1.0.0/CloudXMetaAdapter.xcframework.zip
```

- Compute and update the checksum for Package.swift and SPM:

```sh
swift package compute-checksum CloudXMetaAdapter-Dynamic.xcframework.zip
```

- If CloudXCore version was changed, update it
```
.package(url: "https://github.com/cloudx-xenoss/CloudXCoreiOS.git", from: "*.*.*")
```

---

### ✅ 3. Host in Public GitHub Repo

- Repo: [cloudx-xenoss/CloudXiOSMetaAdapter](https://github.com/cloudx-xenoss/CloudXiOSMetaAdapter)
- Create a **new Release**
  - Attach: `CloudXMetaAdapter-Dynamic.xcframework.zip`
  - Attach: `CloudXMetaAdapter-Static.xcframework.zip`
  - Check: ✅ *Set as the latest release*
  - Click **Publish**

---

### ✅ 4. Deploy to CocoaPods

```sh
cd path/to/CloudXiOSMetaAdapter
pod trunk push
```

> ⚠️ Make sure that:
> - `CloudXMetaAdapter.podspec` matches the release version (e.g., **1.0.0**)  
> - GitHub release **tag** matches `s.version`
