# CloudX iOS SDK

Requires iOS 14.0+ and Xcode 12.0+.

> **Note for docs site migration:** In this README, Objective-C and Swift examples are shown separately. When transferring to the official docs portal, implement tab selectors (Objective-C | Swift | SwiftUI) above each code block so all three variants occupy a single visual space.

## Installation

### CocoaPods

```ruby
platform :ios, '14.0'

target 'YourApp' do
  use_frameworks!
  
  pod 'CloudXCore'
  
  # Add at least one adapter
  pod 'CloudXMetaAdapter'
end
```

```bash
pod install --repo-update
```

## Initialization

**Objective-C:**
```objc
#import <CloudXCore/CloudXCore.h>

[[CloudXCore shared] initializeSDKWithAppKey:@"your-app-key-here" 
                                  completion:^(BOOL success, CLXError * _Nullable error) {
    if (success) {
        NSLog(@"CloudX SDK initialized successfully");
    } else {
        NSLog(@"Failed to initialize CloudX SDK: %@", error.localizedDescription);
    }
}];
```

**Swift:**
```swift
import CloudXCore

CloudXCore.shared.initializeSDK(appKey: "your-app-key-here") { success, error in
    if success {
        print("CloudX SDK initialized successfully")
    } else {
        print("Failed to initialize CloudX SDK: \(error?.localizedDescription ?? "Unknown error")")
    }
}
```

## Ad Integration

### Banner Ads

**Objective-C:**
```objc
@interface YourViewController () <CLXBannerDelegate>
@property (nonatomic, strong) CLXBannerAdView *bannerAd;
@end

@implementation YourViewController

- (void)createBannerAd {
    self.bannerAd = [[CloudXCore shared] createBannerWithPlacement:@"your-banner-placement"
                                                    viewController:self
                                                          delegate:self
                                                              tmax:nil];
    
    if (self.bannerAd) {
        self.bannerAd.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addSubview:self.bannerAd];
        
        [NSLayoutConstraint activateConstraints:@[
            [self.bannerAd.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
            [self.bannerAd.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
            [self.bannerAd.widthAnchor constraintEqualToConstant:320],
            [self.bannerAd.heightAnchor constraintEqualToConstant:50]
        ]];
        
        [self.bannerAd load];
    }
}

#pragma mark - CLXBannerDelegate

- (void)didLoadAd:(CLXAd *)ad {
    NSLog(@"Banner ad loaded successfully");
}

- (void)didFailToLoadAd:(NSString *)placementName error:(CLXError *)error {
    NSLog(@"Banner ad (%@) failed to load: %@", placementName, error.localizedDescription);
}

- (void)didDisplayAd:(CLXAd *)ad {
    NSLog(@"Banner ad displayed");
}

- (void)didClickAd:(CLXAd *)ad {
    NSLog(@"Banner ad clicked");
}

- (void)didHideWithAd:(CLXAd *)ad {
    NSLog(@"Banner ad hidden");
}

@end
```

**Swift:**
```swift
class YourViewController: UIViewController, CLXBannerDelegate {
    private var bannerAd: CLXBannerAdView?
    
    func createBannerAd() {
        bannerAd = CloudXCore.shared.createBanner(withPlacement: "your-banner-placement",
                                                 viewController: self,
                                                 delegate: self,
                                                 tmax: nil)
        
        if let bannerAd = bannerAd {
            bannerAd.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(bannerAd)
            
            NSLayoutConstraint.activate([
                bannerAd.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
                bannerAd.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                bannerAd.widthAnchor.constraint(equalToConstant: 320),
                bannerAd.heightAnchor.constraint(equalToConstant: 50)
            ])
            
            bannerAd.load()
        }
    }
    
    // MARK: - CLXBannerDelegate
    
    func didLoad(_ ad: CLXAd) {
        print("Banner ad loaded successfully")
    }
    
    func didFailToLoadAd(_ placementName: String, error: Error) {
        print("Banner ad (\(placementName)) failed to load: \(error.localizedDescription)")
    }

    func didDisplay(_ ad: CLXAd) {
        print("Banner ad displayed")
    }

    func didClick(_ ad: CLXAd) {
        print("Banner ad clicked")
    }

    func didHide(with ad: CLXAd) {
        print("Banner ad hidden")
    }
}
```

### MREC Ads

**Objective-C:**
```objc
@interface YourViewController () <CLXBannerDelegate>
@property (nonatomic, strong) CLXBannerAdView *mrecAd;
@end

@implementation YourViewController

- (void)createMRECAd {
    self.mrecAd = [[CloudXCore shared] createMRECWithPlacement:@"your-mrec-placement"
                                                viewController:self
                                                      delegate:self];
    
    if (self.mrecAd) {
        self.mrecAd.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addSubview:self.mrecAd];
        
        [NSLayoutConstraint activateConstraints:@[
            [self.mrecAd.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
            [self.mrecAd.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-20],
            [self.mrecAd.widthAnchor constraintEqualToConstant:300],
            [self.mrecAd.heightAnchor constraintEqualToConstant:250]
        ]];
        
        [self.mrecAd load];
    }
}

#pragma mark - CLXBannerDelegate

- (void)didLoadAd:(CLXAd *)ad {
    NSLog(@"MREC ad loaded successfully");
}

- (void)didFailToLoadAd:(NSString *)placementName error:(CLXError *)error {
    NSLog(@"MREC ad (%@) failed to load: %@", placementName, error.localizedDescription);
}

- (void)didDisplayAd:(CLXAd *)ad {
    NSLog(@"MREC ad displayed");
}

- (void)didClickAd:(CLXAd *)ad {
    NSLog(@"MREC ad clicked");
}

- (void)didHideWithAd:(CLXAd *)ad {
    NSLog(@"MREC ad hidden");
}

@end
```

**Swift:**
```swift
class YourViewController: UIViewController, CLXBannerDelegate {
    private var mrecAd: CLXBannerAdView?
    
    func createMRECAd() {
        mrecAd = CloudXCore.shared.createMREC(withPlacement: "your-mrec-placement",
                                             viewController: self,
                                             delegate: self)
        
        if let mrecAd = mrecAd {
            mrecAd.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(mrecAd)
            
            NSLayoutConstraint.activate([
                mrecAd.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                mrecAd.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
                mrecAd.widthAnchor.constraint(equalToConstant: 300),
                mrecAd.heightAnchor.constraint(equalToConstant: 250)
            ])
            
            mrecAd.load()
        }
    }
    
    // MARK: - CLXBannerDelegate
    
    func didLoad(_ ad: CLXAd) {
        print("MREC ad loaded successfully")
    }
    
    func didFailToLoadAd(_ placementName: String, error: Error) {
        print("MREC ad (\(placementName)) failed to load: \(error.localizedDescription)")
    }

    func didDisplay(_ ad: CLXAd) {
        print("MREC ad displayed")
    }

    func didClick(_ ad: CLXAd) {
        print("MREC ad clicked")
    }

    func didHide(with ad: CLXAd) {
        print("MREC ad hidden")
    }
}
```

### Interstitial Ads

**Objective-C:**
```objc
@interface YourViewController () <CLXInterstitialDelegate>
@property (nonatomic, strong) CLXInterstitial *interstitialAd;
@end

@implementation YourViewController

- (void)createInterstitialAd {
    self.interstitialAd = [[CloudXCore shared] createInterstitialWithPlacement:@"your-interstitial-placement"];
    self.interstitialAd.delegate = self;
    
    if (self.interstitialAd) {
        [self.interstitialAd load];
    }
}

- (void)showInterstitialAd {
    if (self.interstitialAd.isReady) {
        [self.interstitialAd showFromViewController:self];
    } else {
        NSLog(@"Interstitial ad not ready");
    }
}

#pragma mark - CLXInterstitialDelegate

- (void)didLoadAd:(CLXAd *)ad {
    NSLog(@"Interstitial ad loaded successfully");
}

- (void)didFailToLoadAd:(NSString *)placementName error:(CLXError *)error {
    NSLog(@"Interstitial ad (%@) failed to load: %@", placementName, error.localizedDescription);
}

- (void)didDisplayAd:(CLXAd *)ad {
    NSLog(@"Interstitial ad displayed");
}

- (void)failToShowWithAd:(CLXAd *)ad error:(CLXError *)error {
    NSLog(@"Interstitial ad failed to show: %@", error.localizedDescription);
}

- (void)didHideWithAd:(CLXAd *)ad {
    NSLog(@"Interstitial ad hidden");
    [self createInterstitialAd]; // Reload for next use
}

- (void)didClickWithAd:(CLXAd *)ad {
    NSLog(@"Interstitial ad clicked");
}

@end
```

**Swift:**
```swift
class YourViewController: UIViewController, CLXInterstitialDelegate {
    private var interstitialAd: CLXInterstitial?
    
    func createInterstitialAd() {
        interstitialAd = CloudXCore.shared.createInterstitial(withPlacement: "your-interstitial-placement",
                                                             delegate: self)
        interstitialAd?.load()
    }
    
    func showInterstitialAd() {
        if interstitialAd?.isReady == true {
            interstitialAd?.show(from: self)
        } else {
            print("Interstitial ad not ready")
        }
    }
    
    // MARK: - CLXInterstitialDelegate
    
    func didLoad(_ ad: CLXAd) {
        print("Interstitial ad loaded successfully")
    }
    
    func didFailToLoadAd(_ placementName: String, error: Error) {
        print("Interstitial ad (\(placementName)) failed to load: \(error.localizedDescription)")
    }

    func didDisplay(_ ad: CLXAd) {
        print("Interstitial ad displayed")
    }

    func failToShow(with ad: CLXAd, error: Error) {
        print("Interstitial ad failed to show: \(error.localizedDescription)")
    }

    func didHide(with ad: CLXAd) {
        print("Interstitial ad hidden")
        createInterstitialAd() // Reload for next use
    }

    func didClick(with ad: CLXAd) {
        print("Interstitial ad clicked")
    }
}
```

## Advanced Features

### Debug Logging

Control SDK log output by setting the minimum log level. Available levels: `CLXLogLevelVerbose`, `CLXLogLevelDebug`, `CLXLogLevelInfo`, `CLXLogLevelWarn`, `CLXLogLevelError`, `CLXLogLevelNone`.

**Objective-C:**
```objc
// Enable verbose logging before SDK initialization
[CloudXCore setMinLogLevel:CLXLogLevelVerbose];

// Disable all logging
[CloudXCore setMinLogLevel:CLXLogLevelNone];
```

**Swift:**
```swift
// Enable verbose logging before SDK initialization
CloudXCore.setMinLogLevel(.verbose)

// Disable all logging
CloudXCore.setMinLogLevel(.none)
```

### Test Mode

Test mode is now **server-controlled** via device whitelisting. This provides better security and control over which devices receive test ads.

**To enable test mode:**

1. Initialize the SDK and check the logs for your device IFA:
   ```
   [CloudX][INFO] Device IFA for test whitelisting: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
   ```

2. Copy the IFA and add it to your device whitelist on the CloudX server dashboard

3. The server will return `deviceConfig.test = 1` for whitelisted devices

4. The SDK will automatically configure adapters for test mode and include the test flag in bid requests

**Note:** Test mode is determined by the server, so you don't need to change any code between development and production builds.

### Privacy Compliance

The CloudX SDK supports GDPR and CCPA privacy compliance by reading standard IAB privacy strings from `NSUserDefaults`. These values are typically set automatically by your Consent Management Platform (CMP).

#### Supported Privacy Keys

| Key | Description |
|-----|-------------|
| `IABTCF_TCString` | GDPR TC String |
| `IABTCF_gdprApplies` | Whether GDPR applies (1 = yes, 0 = no) |
| `IABUSPrivacy_String` | CCPA privacy string |
| `IABGPP_HDR_GppString` | Global Privacy Platform string |
| `IABGPP_GppSID` | GPP Section IDs |

### User Targeting

**Objective-C:**
```objc
// Set hashed user ID
[[CloudXCore shared] setHashedUserID:@"hashed-user-id"];

// User-level targeting (cleared by privacy regulations)
[[CloudXCore shared] setUserKeyValue:@"age" value:@"25"];

// App-level targeting (NOT affected by privacy regulations)
[[CloudXCore shared] setAppKeyValue:@"app_version" value:@"1.2.0"];

// Clear all key-value pairs
[[CloudXCore shared] clearAllKeyValues];
```

**Swift:**
```swift
// Set hashed user ID
CloudXCore.shared.provideUserDetails(withHashedUserID: "hashed-user-id")

// User-level targeting (cleared by privacy regulations)
CloudXCore.shared.setUserKeyValue("age", value: "25")

// App-level targeting (NOT affected by privacy regulations)
CloudXCore.shared.setAppKeyValue("app_version", value: "1.2.0")

// Clear all key-value pairs
CloudXCore.shared.clearAllKeyValues()
```

## Support

For support, contact mobile@cloudx.io
