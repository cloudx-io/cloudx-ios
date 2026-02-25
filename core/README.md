# CloudX iOS SDK

[![CocoaPods](https://img.shields.io/cocoapods/v/CloudXCore.svg)](https://cocoapods.org/pods/CloudXCore)

## Installation

Requires iOS 13.0+ and Xcode 12.0+.

### CocoaPods

```ruby
platform :ios, '13.0'

target 'YourApp' do
  use_frameworks!

  # Core SDK
  pod 'CloudXCore'

  # Adapters for ad networks (add as needed)
  pod 'CloudXMetaAdapter'       # Meta Audience Network 6.21.0
  pod 'CloudXVungleAdapter'     # Vungle SDK 7.6.0
  pod 'CloudXInMobiAdapter'     # InMobi SDK 11.1.0
end
```

```bash
pod install --repo-update
```

## Initialization

**Objective-C:**
```objc
#import <CloudXCore/CloudXCore.h>

CLXInitializationConfiguration *config =
    [CLXInitializationConfiguration configurationWithAppKey:@"your-app-key-here"];

[[CloudXCore shared] initializeWithConfiguration:config completion:^(CLXSdkConfiguration *sdkConfig, CLXError * _Nullable error) {
    if (sdkConfig) {
        NSLog(@"CloudX SDK initialized successfully");
    } else {
        NSLog(@"Failed to initialize CloudX SDK: %@", error.localizedDescription);
    }
}];
```

**Swift:**
```swift
import CloudXCore

let config = CLXInitializationConfiguration.configuration(appKey: "your-app-key-here", builderBlock: nil)

CloudXCore.shared.initialize(with: config) { sdkConfig, error in
    if sdkConfig != nil {
        print("CloudX SDK initialized successfully")
    } else {
        print("Failed to initialize CloudX SDK: \(error?.localizedDescription ?? "Unknown error")")
    }
}
```

## Ad Integration

### Banner Ads (320x50)

**Objective-C:**
```objc
@interface YourViewController () <CLXBannerDelegate, CLXAdRevenueDelegate>
@property (nonatomic, strong) CLXBannerAdView *bannerAd;
@end

@implementation YourViewController

- (void)createBannerAd {
    self.bannerAd = [[CloudXCore shared] createBannerWithAdUnitId:@"your-banner-ad-unit-id"];
    self.bannerAd.delegate = self;
    self.bannerAd.revenueDelegate = self;

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

- (void)dealloc {
    [self.bannerAd destroy];
}

#pragma mark - CLXBannerDelegate

- (void)didLoadAd:(CLXAd *)ad {
    NSLog(@"Banner ad loaded from %@", ad.networkName);
}

- (void)didFailToLoadAd:(NSString *)adUnitId error:(CLXError *)error {
    NSLog(@"Banner ad failed to load: %@", error.localizedDescription);
}

- (void)didClickAd:(CLXAd *)ad {
    NSLog(@"Banner ad clicked");
}

// Optional: Called when banner expands (e.g., MRAID)
- (void)didExpandAd:(CLXAd *)ad {
    NSLog(@"Banner ad expanded");
}

// Optional: Called when banner collapses
- (void)didCollapseAd:(CLXAd *)ad {
    NSLog(@"Banner ad collapsed");
}

#pragma mark - CLXAdRevenueDelegate

- (void)didPayRevenueForAd:(CLXAd *)ad {
    NSLog(@"Banner revenue: %@ from %@", ad.revenue, ad.networkName);
}

@end
```

**Swift:**
```swift
class YourViewController: UIViewController, CLXBannerDelegate, CLXAdRevenueDelegate {
    private var bannerAd: CLXBannerAdView?

    func createBannerAd() {
        bannerAd = CloudXCore.shared.createBanner(adUnitId: "your-banner-ad-unit-id")
        bannerAd?.delegate = self
        bannerAd?.revenueDelegate = self

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

    deinit {
        bannerAd?.destroy()
    }

    // MARK: - CLXBannerDelegate

    func didLoad(_ ad: CLXAd) {
        print("Banner ad loaded from \(ad.networkName ?? "unknown")")
    }

    func didFailToLoadAd(_ adUnitId: String, error: CLXError) {
        print("Banner ad failed to load: \(error.localizedDescription)")
    }

    func didClick(_ ad: CLXAd) {
        print("Banner ad clicked")
    }

    // Optional: Called when banner expands (e.g., MRAID)
    func didExpand(_ ad: CLXAd) {
        print("Banner ad expanded")
    }

    // Optional: Called when banner collapses
    func didCollapse(_ ad: CLXAd) {
        print("Banner ad collapsed")
    }

    // MARK: - CLXAdRevenueDelegate

    func didPayRevenue(for ad: CLXAd) {
        print("Banner revenue: \(ad.revenue ?? 0) from \(ad.networkName ?? "unknown")")
    }
}
```

Banner ads auto-refresh by default. To control refresh manually:

**Objective-C:**
```objc
[self.bannerAd stopAutoRefresh];    // Stop auto-refresh
[self.bannerAd load];               // Manually load a new ad
[self.bannerAd startAutoRefresh];   // Re-enable auto-refresh
```

**Swift:**
```swift
bannerAd?.stopAutoRefresh()    // Stop auto-refresh
bannerAd?.load()               // Manually load a new ad
bannerAd?.startAutoRefresh()   // Re-enable auto-refresh
```

Optional placement and custom data for tracking:

**Objective-C:**
```objc
self.bannerAd.placement = @"home_screen";
self.bannerAd.customData = @"level:5,coins:100";
```

**Swift:**
```swift
bannerAd?.placement = "home_screen"
bannerAd?.customData = "level:5,coins:100"
```

### MREC Ads (300x250)

**Objective-C:**
```objc
@interface YourViewController () <CLXBannerDelegate, CLXAdRevenueDelegate>
@property (nonatomic, strong) CLXBannerAdView *mrecAd;
@end

@implementation YourViewController

- (void)createMRECAd {
    self.mrecAd = [[CloudXCore shared] createMRECWithAdUnitId:@"your-mrec-ad-unit-id"];
    self.mrecAd.delegate = self;
    self.mrecAd.revenueDelegate = self;

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

- (void)dealloc {
    [self.mrecAd destroy];
}

#pragma mark - CLXBannerDelegate

- (void)didLoadAd:(CLXAd *)ad {
    NSLog(@"MREC ad loaded from %@", ad.networkName);
}

- (void)didFailToLoadAd:(NSString *)adUnitId error:(CLXError *)error {
    NSLog(@"MREC ad failed to load: %@", error.localizedDescription);
}

- (void)didClickAd:(CLXAd *)ad {
    NSLog(@"MREC ad clicked");
}

// Optional: Called when MREC expands (e.g., MRAID)
- (void)didExpandAd:(CLXAd *)ad {
    NSLog(@"MREC ad expanded");
}

// Optional: Called when MREC collapses
- (void)didCollapseAd:(CLXAd *)ad {
    NSLog(@"MREC ad collapsed");
}

#pragma mark - CLXAdRevenueDelegate

- (void)didPayRevenueForAd:(CLXAd *)ad {
    NSLog(@"MREC revenue: %@ from %@", ad.revenue, ad.networkName);
}

@end
```

**Swift:**
```swift
class YourViewController: UIViewController, CLXBannerDelegate, CLXAdRevenueDelegate {
    private var mrecAd: CLXBannerAdView?

    func createMRECAd() {
        mrecAd = CloudXCore.shared.createMREC(adUnitId: "your-mrec-ad-unit-id")
        mrecAd?.delegate = self
        mrecAd?.revenueDelegate = self

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

    deinit {
        mrecAd?.destroy()
    }

    // MARK: - CLXBannerDelegate

    func didLoad(_ ad: CLXAd) {
        print("MREC ad loaded from \(ad.networkName ?? "unknown")")
    }

    func didFailToLoadAd(_ adUnitId: String, error: CLXError) {
        print("MREC ad failed to load: \(error.localizedDescription)")
    }

    func didClick(_ ad: CLXAd) {
        print("MREC ad clicked")
    }

    // Optional: Called when MREC expands (e.g., MRAID)
    func didExpand(_ ad: CLXAd) {
        print("MREC ad expanded")
    }

    // Optional: Called when MREC collapses
    func didCollapse(_ ad: CLXAd) {
        print("MREC ad collapsed")
    }

    // MARK: - CLXAdRevenueDelegate

    func didPayRevenue(for ad: CLXAd) {
        print("MREC revenue: \(ad.revenue ?? 0) from \(ad.networkName ?? "unknown")")
    }
}
```

MREC ads also auto-refresh by default. Use the same refresh control methods as Banner ads.

### Interstitial Ads

**Objective-C:**
```objc
@interface YourViewController () <CLXInterstitialDelegate, CLXAdRevenueDelegate>
@property (nonatomic, strong) CLXInterstitial *interstitialAd;
@end

@implementation YourViewController

- (void)createInterstitialAd {
    self.interstitialAd = [[CloudXCore shared] createInterstitialWithAdUnitId:@"your-interstitial-ad-unit-id"];
    self.interstitialAd.delegate = self;
    self.interstitialAd.revenueDelegate = self;
    [self.interstitialAd load];
}

- (void)showInterstitialAd {
    if (self.interstitialAd.isReady) {
        // Basic show
        [self.interstitialAd showFromViewController:self];

        // Or with optional placement and custom data for tracking
        // [self.interstitialAd showFromViewController:self placement:@"level_complete" customData:@"level:5,score:1000"];
    } else {
        NSLog(@"Interstitial ad not ready");
    }
}

- (void)dealloc {
    [self.interstitialAd destroy];
}

#pragma mark - CLXInterstitialDelegate

- (void)didLoadAd:(CLXAd *)ad {
    NSLog(@"Interstitial ad loaded from %@", ad.networkName);
}

- (void)didFailToLoadAd:(NSString *)adUnitId error:(CLXError *)error {
    NSLog(@"Interstitial ad failed to load: %@", error.localizedDescription);
}

- (void)didDisplayAd:(CLXAd *)ad {
    NSLog(@"Interstitial ad displayed");
}

- (void)didFailToDisplayAd:(CLXAd *)ad error:(CLXError *)error {
    NSLog(@"Interstitial ad failed to display: %@", error.localizedDescription);
}

- (void)didHideAd:(CLXAd *)ad {
    NSLog(@"Interstitial ad hidden");
    [self createInterstitialAd]; // Reload for next use
}

- (void)didClickAd:(CLXAd *)ad {
    NSLog(@"Interstitial ad clicked");
}

#pragma mark - CLXAdRevenueDelegate

- (void)didPayRevenueForAd:(CLXAd *)ad {
    NSLog(@"Interstitial revenue: %@ from %@", ad.revenue, ad.networkName);
}

@end
```

**Swift:**
```swift
class YourViewController: UIViewController, CLXInterstitialDelegate, CLXAdRevenueDelegate {
    private var interstitialAd: CLXInterstitial?

    func createInterstitialAd() {
        interstitialAd = CloudXCore.shared.createInterstitial(adUnitId: "your-interstitial-ad-unit-id")
        interstitialAd?.delegate = self
        interstitialAd?.revenueDelegate = self
        interstitialAd?.load()
    }

    func showInterstitialAd() {
        if interstitialAd?.isReady == true {
            // Basic show
            interstitialAd?.show(from: self)

            // Or with optional placement and custom data for tracking
            // interstitialAd?.show(from: self, placement: "level_complete", customData: "level:5,score:1000")
        } else {
            print("Interstitial ad not ready")
        }
    }

    deinit {
        interstitialAd?.destroy()
    }

    // MARK: - CLXInterstitialDelegate

    func didLoad(_ ad: CLXAd) {
        print("Interstitial ad loaded from \(ad.networkName ?? "unknown")")
    }

    func didFailToLoadAd(_ adUnitId: String, error: CLXError) {
        print("Interstitial ad failed to load: \(error.localizedDescription)")
    }

    func didDisplay(_ ad: CLXAd) {
        print("Interstitial ad displayed")
    }

    func didFailToDisplay(_ ad: CLXAd, error: CLXError) {
        print("Interstitial ad failed to display: \(error.localizedDescription)")
    }

    func didHide(_ ad: CLXAd) {
        print("Interstitial ad hidden")
        createInterstitialAd() // Reload for next use
    }

    func didClick(_ ad: CLXAd) {
        print("Interstitial ad clicked")
    }

    // MARK: - CLXAdRevenueDelegate

    func didPayRevenue(for ad: CLXAd) {
        print("Interstitial revenue: \(ad.revenue ?? 0) from \(ad.networkName ?? "unknown")")
    }
}
```

### Rewarded Ads

**Objective-C:**
```objc
@interface YourViewController () <CLXRewardedDelegate, CLXAdRevenueDelegate>
@property (nonatomic, strong) CLXRewarded *rewardedAd;
@end

@implementation YourViewController

- (void)createRewardedAd {
    self.rewardedAd = [[CloudXCore shared] createRewardedWithAdUnitId:@"your-rewarded-ad-unit-id"];
    self.rewardedAd.delegate = self;
    self.rewardedAd.revenueDelegate = self;
    [self.rewardedAd load];
}

- (void)showRewardedAd {
    if (self.rewardedAd.isReady) {
        // Basic show
        [self.rewardedAd showFromViewController:self];

        // Or with optional placement and custom data for tracking
        // [self.rewardedAd showFromViewController:self placement:@"bonus_coins" customData:@"level:5,coins:100"];
    } else {
        NSLog(@"Rewarded ad not ready");
    }
}

- (void)dealloc {
    [self.rewardedAd destroy];
}

#pragma mark - CLXRewardedDelegate

- (void)didLoadAd:(CLXAd *)ad {
    NSLog(@"Rewarded ad loaded from %@", ad.networkName);
}

- (void)didFailToLoadAd:(NSString *)adUnitId error:(CLXError *)error {
    NSLog(@"Rewarded ad failed to load: %@", error.localizedDescription);
}

- (void)didDisplayAd:(CLXAd *)ad {
    NSLog(@"Rewarded ad displayed");
}

- (void)didFailToDisplayAd:(CLXAd *)ad error:(CLXError *)error {
    NSLog(@"Rewarded ad failed to display: %@", error.localizedDescription);
}

- (void)didHideAd:(CLXAd *)ad {
    NSLog(@"Rewarded ad hidden");
    [self createRewardedAd]; // Reload for next use
}

- (void)didClickAd:(CLXAd *)ad {
    NSLog(@"Rewarded ad clicked");
}

- (void)didRewardUserForAd:(CLXAd *)ad withReward:(CLXReward *)reward {
    NSLog(@"User rewarded: %ld %@", (long)reward.amount, reward.label);
    // Grant the reward to the user
}

#pragma mark - CLXAdRevenueDelegate

- (void)didPayRevenueForAd:(CLXAd *)ad {
    NSLog(@"Rewarded revenue: %@ from %@", ad.revenue, ad.networkName);
}

@end
```

**Swift:**
```swift
class YourViewController: UIViewController, CLXRewardedDelegate, CLXAdRevenueDelegate {
    private var rewardedAd: CLXRewarded?

    func createRewardedAd() {
        rewardedAd = CloudXCore.shared.createRewarded(adUnitId: "your-rewarded-ad-unit-id")
        rewardedAd?.delegate = self
        rewardedAd?.revenueDelegate = self
        rewardedAd?.load()
    }

    func showRewardedAd() {
        if rewardedAd?.isReady == true {
            // Basic show
            rewardedAd?.show(from: self)

            // Or with optional placement and custom data for tracking
            // rewardedAd?.show(from: self, placement: "bonus_coins", customData: "level:5,coins:100")
        } else {
            print("Rewarded ad not ready")
        }
    }

    deinit {
        rewardedAd?.destroy()
    }

    // MARK: - CLXRewardedDelegate

    func didLoad(_ ad: CLXAd) {
        print("Rewarded ad loaded from \(ad.networkName ?? "unknown")")
    }

    func didFailToLoadAd(_ adUnitId: String, error: CLXError) {
        print("Rewarded ad failed to load: \(error.localizedDescription)")
    }

    func didDisplay(_ ad: CLXAd) {
        print("Rewarded ad displayed")
    }

    func didFailToDisplay(_ ad: CLXAd, error: CLXError) {
        print("Rewarded ad failed to display: \(error.localizedDescription)")
    }

    func didHide(_ ad: CLXAd) {
        print("Rewarded ad hidden")
        createRewardedAd() // Reload for next use
    }

    func didClick(_ ad: CLXAd) {
        print("Rewarded ad clicked")
    }

    func didRewardUser(for ad: CLXAd, with reward: CLXReward) {
        print("User rewarded: \(reward.amount) \(reward.label)")
        // Grant the reward to the user
    }

    // MARK: - CLXAdRevenueDelegate

    func didPayRevenue(for ad: CLXAd) {
        print("Rewarded revenue: \(ad.revenue ?? 0) from \(ad.networkName ?? "unknown")")
    }
}
```

### Ad Information (CLXAd)

The `CLXAd` object is passed to delegate callbacks and contains information about the loaded/displayed ad:

| Property | Type | Description |
|----------|------|-------------|
| `adFormat` | `CLXAdFormat` | Ad format (banner, mrec, interstitial, rewarded) |
| `adUnitId` | `NSString?` | The ad unit ID |
| `adUnitName` | `NSString?` | The ad unit name |
| `networkName` | `NSString?` | Name of the winning ad network |
| `networkPlacement` | `NSString?` | Network-specific placement ID |
| `placement` | `NSString?` | Custom placement set via `placement` property |
| `revenue` | `NSNumber?` | Impression-level revenue in USD |

**Objective-C:**
```objc
- (void)didLoadAd:(CLXAd *)ad {
    NSLog(@"Ad format: %ld", (long)ad.adFormat);
    NSLog(@"Network: %@", ad.networkName);
    NSLog(@"Revenue: %@", ad.revenue);
}
```

**Swift:**
```swift
func didLoad(_ ad: CLXAd) {
    print("Ad format: \(ad.adFormat)")
    print("Network: \(ad.networkName ?? "unknown")")
    print("Revenue: \(ad.revenue ?? 0)")
}
```

### Error Handling

All SDK errors are returned as `CLXError` objects in delegate callbacks:

| Property | Type | Description |
|----------|------|-------------|
| `code` | `CLXErrorCode` | Error category |
| `localizedDescription` | `NSString` | Human-readable description |
| `underlyingError` | `NSError?` | Optional underlying error |

#### Error Code Categories

| Range | Category | Common Codes |
|-------|----------|--------------|
| 0 | General | `CLXErrorCodeInternalError` |
| 100-199 | Network | `CLXErrorCodeNetworkError`, `CLXErrorCodeNetworkTimeout`, `CLXErrorCodeServerError`, `CLXErrorCodeNoConnection` |
| 200-299 | Initialization | `CLXErrorCodeNotInitialized`, `CLXErrorCodeSDKDisabled`, `CLXErrorCodeNoAdaptersFound`, `CLXErrorCodeInvalidAppKey` |
| 300-399 | Ad Loading | `CLXErrorCodeNoFill`, `CLXErrorCodeInvalidAdUnit`, `CLXErrorCodeAdsDisabled` |
| 400-499 | Display | `CLXErrorCodeAdNotReady`, `CLXErrorCodeAdAlreadyShowing` |
| 600-699 | Adapter | `CLXErrorCodeAdapterNoFill`, `CLXErrorCodeAdapterTimeout`, `CLXErrorCodeAdapterLoadTimeout`, `CLXErrorCodeAdapterInitializationError` |

## Advanced Features

### Debug Logging

**Objective-C:**
```objc
[CloudXCore setMinLogLevel:CLXLogLevelDebug];  // Enable debug logging
[CloudXCore setMinLogLevel:CLXLogLevelNone];   // Disable all logging
```

**Swift:**
```swift
CloudXCore.setMinLogLevel(.debug)  // Enable debug logging
CloudXCore.setMinLogLevel(.none)   // Disable all logging
```

**Log Levels:** `verbose` < `debug` < `info` < `warn` < `error` < `none`

### Impression-Level Revenue Tracking

Set a `revenueDelegate` on any ad format to receive impression-level revenue (ILR) callbacks. The `CLXAd` object contains the revenue value in USD and the winning network name.

**Objective-C:**
```objc
self.bannerAd.revenueDelegate = self;

- (void)didPayRevenueForAd:(CLXAd *)ad {
    NSLog(@"Revenue: %@ from %@", ad.revenue, ad.networkName);
}
```

**Swift:**
```swift
bannerAd?.revenueDelegate = self

func didPayRevenue(for ad: CLXAd) {
    print("Revenue: \(ad.revenue ?? 0) from \(ad.networkName ?? "unknown")")
}
```

Works with all ad formats (banner, MREC, interstitial, rewarded).

### Test Mode

Test mode is **server-controlled** via device whitelisting. This provides better security and control over which devices receive test ads.

**To enable test mode:**

1. Initialize the SDK and check the logs for your device IFA:
   ```
   [CloudX][INFO] Device IFA for test whitelisting: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
   ```

2. Copy the IFA and add it to your device whitelist on the CloudX server dashboard

3. The SDK will automatically configure adapters for test mode and include the test flag in bid requests

**Note:** Test mode is determined by the server, so you don't need to change any code between development and production builds.

### Privacy Compliance

The CloudX SDK supports GDPR and CCPA privacy compliance by reading standard IAB privacy strings from `NSUserDefaults`. These values are typically set automatically by your Consent Management Platform (CMP) such as Google UMP, OneTrust, or Sourcepoint.

#### How It Works

The SDK automatically detects user location and reads consent signals:

1. **EU Users (GDPR)**: Checks TCF v2 consent for purposes 1-4 and vendor consent (CloudX Vendor ID: 1510)
2. **US Users (CCPA)**: Checks for sale/sharing opt-out signals
3. **Other Regions**: No restrictions applied

When consent is denied or user opts out, the SDK removes PII from ad requests:
- Advertising ID (IDFA) is cleared
- Geo coordinates (lat/lon) are removed
- User key-values are not sent
- Hashed user ID is excluded

#### Supported Privacy Keys

| Key | Standard | Description |
|-----|----------|-------------|
| `IABGPP_HDR_GppString` | [GPP](https://github.com/InteractiveAdvertisingBureau/Global-Privacy-Platform) | Global Privacy Platform string (modern) |
| `IABGPP_GppSID` | GPP | Section IDs (e.g., "2" for EU, "7" for US-National, "8" for US-CA) |
| `IABTCF_TCString` | [TCF v2](https://github.com/InteractiveAdvertisingBureau/GDPR-Transparency-and-Consent-Framework) | GDPR consent string (legacy) |
| `IABTCF_gdprApplies` | TCF v2 | Whether GDPR applies (1 = yes, 0 = no) |
| `IABUSPrivacy_String` | [US Privacy](https://github.com/InteractiveAdvertisingBureau/USPrivacy) | CCPA privacy string (legacy, e.g., "1YNN") |

> **Note**: The SDK prioritizes GPP (modern standard) over legacy TCF/US Privacy strings when both are available.

#### App Tracking Transparency (ATT)

On iOS 14.5+, you must request App Tracking Transparency authorization before the SDK can access the IDFA. Request ATT permission before initializing the CloudX SDK:

**Objective-C:**
```objc
#import <AppTrackingTransparency/AppTrackingTransparency.h>

if (@available(iOS 14.5, *)) {
    [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
        // Initialize CloudX SDK after ATT response
        [self initializeCloudX];
    }];
} else {
    [self initializeCloudX];
}
```

**Swift:**
```swift
import AppTrackingTransparency

if #available(iOS 14.5, *) {
    ATTrackingManager.requestTrackingAuthorization { status in
        // Initialize CloudX SDK after ATT response
        self.initializeCloudX()
    }
} else {
    initializeCloudX()
}
```

Add the `NSUserTrackingUsageDescription` key to your Info.plist with a description of why you need tracking permission.

### User Targeting

**Objective-C:**
```objc
// Set hashed user ID for targeting
[[CloudXCore shared] setHashedUserID:@"hashed-user-id"];

// Set custom user key-value pairs (cleared by privacy regulations)
[[CloudXCore shared] setUserKeyValue:@"age" value:@"25"];
[[CloudXCore shared] setUserKeyValue:@"gender" value:@"male"];
[[CloudXCore shared] setUserKeyValue:@"location" value:@"US"];

// Set custom app key-value pairs (NOT affected by privacy regulations)
[[CloudXCore shared] setAppKeyValue:@"app_version" value:@"1.0.0"];
[[CloudXCore shared] setAppKeyValue:@"user_level" value:@"premium"];

// Clear all custom key-values
[[CloudXCore shared] clearAllKeyValues];
```

**Swift:**
```swift
// Set hashed user ID for targeting
CloudXCore.shared.setHashedUserID("hashed-user-id")

// Set custom user key-value pairs (cleared by privacy regulations)
CloudXCore.shared.setUserKeyValue("age", value: "25")
CloudXCore.shared.setUserKeyValue("gender", value: "male")
CloudXCore.shared.setUserKeyValue("location", value: "US")

// Set custom app key-value pairs (NOT affected by privacy regulations)
CloudXCore.shared.setAppKeyValue("app_version", value: "1.0.0")
CloudXCore.shared.setAppKeyValue("user_level", value: "premium")

// Clear all custom key-values
CloudXCore.shared.clearAllKeyValues()
```

## Support

For support, contact mobile@cloudx.io
