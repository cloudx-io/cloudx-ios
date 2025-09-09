# CloudXCore

CloudXCore iOS internal repo. The code is packaged as a framework and then released externally from the following public repo `https://github.com/cloudx-xenoss/CloudXiOSCore`


## 📄 Documentation

Docs are stored in the repo at `cloudexchange.sdk.ios.core/Sources/CloudXCore/CloudXCore.docc`

To view the docs in XCode, open `CloudXCore.xcodeproj` and press `cmd+shift+d`

Docs should be generated as part of the CI/CD github action flow kicked off by pushing a tag (see CloudXCore Release Steps section below)

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

## 🐞 Crash Reporting

Crashes are captured in Sentry [ios-sdk Sentry Dashboard](https://sentry.io/organizations/cloudexchange/projects/ios-sdk/?project=4509136596828160)

✅ If the host app does not use Sentry, then Sentry will be setup when the core SDK is initialized. 

⚠️ HOST APP HAS SENTRY: If the host app uses Sentry for it's own crashes, the CloudXCore SDK will be blocked from capturing it's own crashes. The host app can forward crashes to us by adding the following code to it's `SentrySDK.start {}` initialization block. 

```swift
/** HOST APP SENTRY INITIALIZATION **/
SentrySDK.start { options in
    options.dsn = "<HOST APP DSN>"

    /** ADD THIS SNIPPET TO FORWARD HOST APP CRASHES TO THE CLOUDX SENTRY ACCOUNT**/
    options.beforeSend = { event in
        if event.module == "CloudXCore" || event.exception?.values.first?.stacktrace?.frames.contains(where: { $0.module?.contains("CloudXCore") == true }) == true {
            // Send event to CloudXCore SDK's Sentry
            sendToCloudXCoreSentry(event)
        }
        return event
    }
}

```

NOTE: The GitHub Action's release.yml file will automatically upload .dsyms for the core sdk to the CloudX `ios-sdk` Sentry app, which enables crash stack traces to be parsed into a readable format. (Even if a host app forwards Sentry crash events to us, it shouldn't be able to see the stack trace parsed into readable function calls)
