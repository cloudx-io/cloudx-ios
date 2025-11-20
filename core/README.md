# CloudX iOS SDK

A powerful iOS SDK for maximizing ad revenue through intelligent ad mediation across multiple ad networks. The CloudX SDK helps developers efficiently manage and optimize their ad inventory to ensure the highest possible returns.

## Features

- **Multiple Ad Formats**: Banner, Interstitial, Rewarded, Native, and MREC ads
- **Intelligent Mediation**: Automatic optimization across multiple ad networks
- **Real-time Bidding**: Advanced bidding technology for maximum revenue
- **Comprehensive Analytics**: Detailed reporting and performance metrics
- **Easy Integration**: Simple API with comprehensive delegate callbacks
- **iOS 14.0+ Support**: Modern iOS compatibility

## Requirements

- **iOS**: 14.0 or later
- **Xcode**: 12.0 or later
- **Swift**: 5.0 or later (for Swift projects)
- **Objective-C**: Compatible with all Objective-C projects

## Installation

### CocoaPods (Recommended)

1. Add the CloudX SDK to your `Podfile`:

```ruby
platform :ios, '14.0'

target 'YourApp' do
  use_frameworks!
  
  # CloudX Core SDK
  pod 'CloudXCore'
  
  # REQUIRED: Add at least one adapter to see ads
  # pod 'CloudXMetaAdapter'
end
```

2. Install the dependencies:

```bash
pod install --repo-update
```

3. Open your project using the `.xcworkspace` file.

### Manual Installation

1. Download the latest release from [cloudx-ios Releases](https://github.com/cloudx-io/cloudx-ios/releases)
2. Extract the downloaded zip file
3. Drag the source files into your Xcode project
4. Ensure "Copy items if needed" is checked and select your target
5. Add the required frameworks to your target's "Frameworks, Libraries, and Embedded Content" section

## Quick Start

### 1. Import the SDK

**Objective-C:**
```objc
#import <CloudXCore/CloudXCore.h>
```

**Swift:**
```swift
import CloudXCore
```

### 2. Initialize the SDK

**Objective-C:**
```objc
// Initialize with app key only
[[CloudXCore shared] initializeSDKWithAppKey:@"your-app-key-here" 
                             completion:^(BOOL success, NSError * _Nullable error) {
    if (success) {
        NSLog(@"✅ CloudX SDK initialized successfully");
    } else {
        NSLog(@"❌ Failed to initialize CloudX SDK: %@", error.localizedDescription);
    }
}];

// Initialize with app key and hashed user ID
[[CloudXCore shared] initializeSDKWithAppKey:@"your-app-key-here" 
                           hashedUserID:@"user-id-optional" 
                             completion:^(BOOL success, NSError * _Nullable error) {
    if (success) {
        NSLog(@"✅ CloudX SDK initialized successfully");
    } else {
        NSLog(@"❌ Failed to initialize CloudX SDK: %@", error.localizedDescription);
    }
}];
```

**Swift:**
```swift
// Initialize with app key only
CloudXCore.shared.initSDK(withAppKey: "your-app-key-here") { success, error in
    if success {
        print("✅ CloudX SDK initialized successfully")
    } else {
        print("❌ Failed to initialize CloudX SDK: \(error?.localizedDescription ?? "Unknown error")")
    }
}

// Initialize with app key and hashed user ID
CloudXCore.shared.initSDK(withAppKey: "your-app-key-here", 
                         hashedUserID: "user-id-optional") { success, error in
    if success {
        print("✅ CloudX SDK initialized successfully")
    } else {
        print("❌ Failed to initialize CloudX SDK: \(error?.localizedDescription ?? "Unknown error")")
    }
}
```

### 3. Check SDK Status

**Objective-C:**
```objc
BOOL isInitialized = [[CloudXCore shared] isInitialized];
NSString *sdkVersion = [[CloudXCore shared] sdkVersion];
```

**Swift:**
```swift
let isInitialized = CloudXCore.shared.isInitialized
let sdkVersion = CloudXCore.shared.sdkVersion
```

## Ad Integration

### Banner Ads

Banner ads are rectangular ads that appear at the top or bottom of the screen.

**Objective-C:**
```objc
@interface YourViewController () <CLXBannerDelegate>
@property (nonatomic, strong) CLXBannerAdView *bannerAd;
@end

@implementation YourViewController

- (void)createBannerAd {
    // Create banner ad
    self.bannerAd = [[CloudXCore shared] createBannerWithPlacement:@"your-banner-placement"
                                                    viewController:self
                                                        delegate:self
                                                            tmax:nil];
    
    if (self.bannerAd) {
        // Add to view hierarchy
        self.bannerAd.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addSubview:self.bannerAd];
        
        // Set constraints
        [NSLayoutConstraint activateConstraints:@[
            [self.bannerAd.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
            [self.bannerAd.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
            [self.bannerAd.widthAnchor constraintEqualToConstant:320],
            [self.bannerAd.heightAnchor constraintEqualToConstant:50]
        ]];
        
        // Load the ad
        [self.bannerAd load];
    }
}

#pragma mark - CLXBannerDelegate

- (void)didLoadWithAd:(CLXAd *)ad {
    NSLog(@"✅ Banner ad loaded successfully");
}

- (void)failToLoadWithAd:(CLXAd *)ad error:(NSError *)error {
    NSLog(@"❌ Banner ad failed to load: %@", error.localizedDescription);
}

- (void)didShowWithAd:(CLXAd *)ad {
    NSLog(@"👀 Banner ad shown");
}

- (void)didClickWithAd:(CLXAd *)ad {
    NSLog(@"👆 Banner ad clicked");
}

- (void)impressionOn:(CLXAd *)ad {
    NSLog(@"👁️ Banner ad impression recorded");
}

- (void)didHideWithAd:(CLXAd *)ad {
    NSLog(@"🔚 Banner ad hidden");
}

- (void)closedByUserActionWithAd:(CLXAd *)ad {
    NSLog(@"✋ Banner ad closed by user");
}

@end
```

**Swift:**
```swift
class YourViewController: UIViewController, CLXBannerDelegate {
    private var bannerAd: CLXBannerAdView?
    
    func createBannerAd() {
        // Create banner ad
        bannerAd = CloudXCore.shared.createBanner(withPlacement: "your-banner-placement",
                                                 viewController: self,
                                                 delegate: self,
                                                 tmax: nil)
        
        if let bannerAd = bannerAd {
            // Add to view hierarchy
            bannerAd.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(bannerAd)
            
            // Set constraints
            NSLayoutConstraint.activate([
                bannerAd.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
                bannerAd.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                bannerAd.widthAnchor.constraint(equalToConstant: 320),
                bannerAd.heightAnchor.constraint(equalToConstant: 50)
            ])
            
            // Load the ad
            bannerAd.load()
        }
    }
}

// MARK: - CLXBannerDelegate
extension YourViewController {
    func didLoad(with ad: CLXAd) {
        print("✅ Banner ad loaded successfully")
    }
    
    func failToLoad(with ad: CLXAd, error: Error) {
        print("❌ Banner ad failed to load: \(error.localizedDescription)")
    }
    
    func didShow(with ad: CLXAd) {
        print("👀 Banner ad shown")
    }
    
    func didClick(with ad: CLXAd) {
        print("👆 Banner ad clicked")
    }
    
    func impression(on ad: CLXAd) {
        print("👁️ Banner ad impression recorded")
    }
    
    func didHide(with ad: CLXAd) {
        print("🔚 Banner ad hidden")
    }
    
    func closedByUserAction(with ad: CLXAd) {
        print("✋ Banner ad closed by user")
    }
}
```

### Interstitial Ads

Interstitial ads are full-screen ads that appear between app content.

```objc
@interface YourViewController () <CLXInterstitialDelegate>
@property (nonatomic, strong) CLXInterstitial *interstitialAd;
@end

@implementation YourViewController

- (void)createInterstitialAd {
    // Create interstitial ad
    self.interstitialAd = [[CloudXCore shared] createInterstitialWithPlacement:@"your-interstitial-placement"];
    self.interstitialAd.delegate = self;
    
    if (self.interstitialAd) {
        // Load the ad
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

- (void)didLoadWithAd:(CLXAd *)ad {
    NSLog(@"✅ Interstitial ad loaded successfully");
}

- (void)failToLoadWithAd:(CLXAd *)ad error:(NSError *)error {
    NSLog(@"❌ Interstitial ad failed to load: %@", error.localizedDescription);
}

- (void)didShowWithAd:(CLXAd *)ad {
    NSLog(@"👀 Interstitial ad shown");
}

- (void)failToShowWithAd:(CLXAd *)ad error:(NSError *)error {
    NSLog(@"❌ Interstitial ad failed to show: %@", error.localizedDescription);
}

- (void)didHideWithAd:(CLXAd *)ad {
    NSLog(@"🔚 Interstitial ad hidden");
    // Reload for next use
    [self createInterstitialAd];
}

- (void)didClickWithAd:(CLXAd *)ad {
    NSLog(@"👆 Interstitial ad clicked");
}

- (void)impressionOn:(CLXAd *)ad {
    NSLog(@"👁️ Interstitial ad impression recorded");
}

- (void)closedByUserActionWithAd:(CLXAd *)ad {
    NSLog(@"✋ Interstitial ad closed by user");
    // Reload for next use
    [self createInterstitialAd];
}

@end
```

```swift
class YourViewController: UIViewController, CLXInterstitialDelegate {
    private var interstitialAd: CLXInterstitial?
    
    func createInterstitialAd() {
        // Create interstitial ad
        interstitialAd = CloudXCore.shared.createInterstitial(withPlacement: "your-interstitial-placement",
                                                             delegate: self)
        
        if let interstitialAd = interstitialAd {
            // Load the ad
            interstitialAd.load()
        }
    }
    
    func showInterstitialAd() {
        if interstitialAd?.isReady == true {
            interstitialAd?.show(from: self)
        } else {
            print("Interstitial ad not ready")
        }
    }
}

// MARK: - CLXInterstitialDelegate
extension YourViewController {
    func didLoad(with ad: CLXAd) {
        print("✅ Interstitial ad loaded successfully")
    }
    
    func failToLoad(with ad: CLXAd, error: Error) {
        print("❌ Interstitial ad failed to load: \(error.localizedDescription)")
    }
    
    func didShow(with ad: CLXAd) {
        print("👀 Interstitial ad shown")
    }
    
    func failToShow(with ad: CLXAd, error: Error) {
        print("❌ Interstitial ad failed to show: \(error.localizedDescription)")
    }
    
    func didHide(with ad: CLXAd) {
        print("🔚 Interstitial ad hidden")
        // Reload for next use
        createInterstitialAd()
    }
    
    func didClick(with ad: CLXAd) {
        print("👆 Interstitial ad clicked")
    }
    
    func impression(on ad: CLXAd) {
        print("👁️ Interstitial ad impression recorded")
    }
    
    func closedByUserAction(with ad: CLXAd) {
        print("✋ Interstitial ad closed by user")
        // Reload for next use
        createInterstitialAd()
    }
}
```

### Rewarded Ads

Rewarded ads are full-screen ads that provide rewards to users for watching.

```objc
@interface YourViewController () <CLXRewardedDelegate>
@property (nonatomic, strong) CLXRewarded *rewardedAd;
@end

@implementation YourViewController

- (void)createRewardedAd {
    // Create rewarded ad
    self.rewardedAd = [[CloudXCore shared] createRewardedWithPlacement:@"your-rewarded-placement"];
    self.rewardedAd.delegate = self;
    
    if (self.rewardedAd) {
        // Load the ad
        [self.rewardedAd load];
    }
}

- (void)showRewardedAd {
    if (self.rewardedAd.isReady) {
        [self.rewardedAd showFromViewController:self];
    } else {
        NSLog(@"Rewarded ad not ready");
    }
}

#pragma mark - CLXRewardedDelegate

- (void)didLoadWithAd:(CLXAd *)ad {
    NSLog(@"✅ Rewarded ad loaded successfully");
}

- (void)failToLoadWithAd:(CLXAd *)ad error:(NSError *)error {
    NSLog(@"❌ Rewarded ad failed to load: %@", error.localizedDescription);
}

- (void)didShowWithAd:(CLXAd *)ad {
    NSLog(@"👀 Rewarded ad shown");
}

- (void)failToShowWithAd:(CLXAd *)ad error:(NSError *)error {
    NSLog(@"❌ Rewarded ad failed to show: %@", error.localizedDescription);
}

- (void)didHideWithAd:(CLXAd *)ad {
    NSLog(@"🔚 Rewarded ad hidden");
    // Reload for next use
    [self createRewardedAd];
}

- (void)didClickWithAd:(CLXAd *)ad {
    NSLog(@"👆 Rewarded ad clicked");
}

- (void)impressionOn:(CLXAd *)ad {
    NSLog(@"👁️ Rewarded ad impression recorded");
}

- (void)closedByUserActionWithAd:(CLXAd *)ad {
    NSLog(@"✋ Rewarded ad closed by user");
    // Reload for next use
    [self createRewardedAd];
}

// Rewarded-specific callbacks
- (void)userRewarded:(CLXAd *)ad {
    NSLog(@"🎁 User earned reward!");
    // Handle reward here
    [self showRewardDialog];
}

- (void)rewardedVideoStarted:(CLXAd *)ad {
    NSLog(@"▶️ Rewarded video started");
}

- (void)rewardedVideoCompleted:(CLXAd *)ad {
    NSLog(@"✅ Rewarded video completed");
}

- (void)showRewardDialog {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Reward Earned!"
                                                                   message:@"You earned a reward!"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                      style:UIAlertActionStyleDefault
                                                    handler:nil];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
```

```swift
class YourViewController: UIViewController, CLXRewardedDelegate {
    private var rewardedAd: CLXRewardedInterstitial?
    
    func createRewardedAd() {
        // Create rewarded ad
        rewardedAd = CloudXCore.shared.createRewarded(withPlacement: "your-rewarded-placement",
                                                     delegate: self)
        
        if let rewardedAd = rewardedAd {
            // Load the ad
            rewardedAd.load()
        }
    }
    
    func showRewardedAd() {
        if rewardedAd?.isReady == true {
            rewardedAd?.show(from: self)
        } else {
            print("Rewarded ad not ready")
        }
    }
}

// MARK: - CLXRewardedDelegate
extension YourViewController {
    func didLoad(with ad: CLXAd) {
        print("✅ Rewarded ad loaded successfully")
    }
    
    func failToLoad(with ad: CLXAd, error: Error) {
        print("❌ Rewarded ad failed to load: \(error.localizedDescription)")
    }
    
    func didShow(with ad: CLXAd) {
        print("👀 Rewarded ad shown")
    }
    
    func failToShow(with ad: CLXAd, error: Error) {
        print("❌ Rewarded ad failed to show: \(error.localizedDescription)")
    }
    
    func didHide(with ad: CLXAd) {
        print("🔚 Rewarded ad hidden")
        // Reload for next use
        createRewardedAd()
    }
    
    func didClick(with ad: CLXAd) {
        print("👆 Rewarded ad clicked")
    }
    
    func impression(on ad: CLXAd) {
        print("👁️ Rewarded ad impression recorded")
    }
    
    func closedByUserAction(with ad: CLXAd) {
        print("✋ Rewarded ad closed by user")
        // Reload for next use
        createRewardedAd()
    }
    
    // Rewarded-specific callbacks
    func userRewarded(_ ad: CLXAd) {
        print("🎁 User earned reward!")
        // Handle reward here
        showRewardDialog()
    }
    
    func rewardedVideoStarted(_ ad: CLXAd) {
        print("▶️ Rewarded video started")
    }
    
    func rewardedVideoCompleted(_ ad: CLXAd) {
        print("✅ Rewarded video completed")
    }
    
    private func showRewardDialog() {
        let alert = UIAlertController(title: "Reward Earned!",
                                    message: "You earned a reward!",
                                    preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default)
        alert.addAction(okAction)
        present(alert, animated: true)
    }
}
```

### Native Ads

Native ads are designed to match the look and feel of your app's content.

```objc
@interface YourViewController () <CLXNativeDelegate>
@property (nonatomic, strong) CLXNativeAdView *nativeAd;
@end

@implementation YourViewController

- (void)createNativeAd {
    // Create native ad
    self.nativeAd = [[CloudXCore shared] createNativeAdWithPlacement:@"your-native-placement"
                                                    viewController:self
                                                          delegate:self];
    
    if (self.nativeAd) {
        // Load the ad
        [self.nativeAd load];
    }
}

- (void)showNativeAd {
    if (self.nativeAd.isReady) {
        // Add to your view hierarchy
        self.nativeAd.frame = CGRectMake(0, 0, 300, 200);
        [self.adContainerView addSubview:self.nativeAd];
    } else {
        NSLog(@"Native ad not ready");
    }
}

#pragma mark - CLXNativeDelegate

- (void)didLoadWithAd:(CLXAd *)ad {
    NSLog(@"✅ Native ad loaded successfully");
}

- (void)failToLoadWithAd:(CLXAd *)ad error:(NSError *)error {
    NSLog(@"❌ Native ad failed to load: %@", error.localizedDescription);
}

- (void)didShowWithAd:(CLXAd *)ad {
    NSLog(@"👀 Native ad shown");
}

- (void)failToShowWithAd:(CLXAd *)ad error:(NSError *)error {
    NSLog(@"❌ Native ad failed to show: %@", error.localizedDescription);
}

- (void)didHideWithAd:(CLXAd *)ad {
    NSLog(@"🔚 Native ad hidden");
}

- (void)didClickWithAd:(CLXAd *)ad {
    NSLog(@"👆 Native ad clicked");
}

- (void)impressionOn:(CLXAd *)ad {
    NSLog(@"👁️ Native ad impression recorded");
}

- (void)closedByUserActionWithAd:(CLXAd *)ad {
    NSLog(@"✋ Native ad closed by user");
}

@end
```

```swift
class YourViewController: UIViewController, CLXNativeDelegate {
    private var nativeAd: CLXNativeAdView?
    
    func createNativeAd() {
        // Create native ad
        nativeAd = CloudXCore.shared.createNativeAd(withPlacement: "your-native-placement",
                                                   viewController: self,
                                                   delegate: self)
        
        if let nativeAd = nativeAd {
            // Load the ad
            nativeAd.load()
        }
    }
    
    func showNativeAd() {
        if nativeAd?.isReady == true {
            // Add to your view hierarchy
            nativeAd?.frame = CGRect(x: 0, y: 0, width: 300, height: 200)
            adContainerView.addSubview(nativeAd!)
        } else {
            print("Native ad not ready")
        }
    }
}

// MARK: - CLXNativeDelegate
extension YourViewController {
    func didLoad(with ad: CLXAd) {
        print("✅ Native ad loaded successfully")
    }
    
    func failToLoad(with ad: CLXAd, error: Error) {
        print("❌ Native ad failed to load: \(error.localizedDescription)")
    }
    
    func didShow(with ad: CLXAd) {
        print("👀 Native ad shown")
    }
    
    func failToShow(with ad: CLXAd, error: Error) {
        print("❌ Native ad failed to show: \(error.localizedDescription)")
    }
    
    func didHide(with ad: CLXAd) {
        print("🔚 Native ad hidden")
    }
    
    func didClick(with ad: CLXAd) {
        print("👆 Native ad clicked")
    }
    
    func impression(on ad: CLXAd) {
        print("👁️ Native ad impression recorded")
    }
    
    func closedByUserAction(with ad: CLXAd) {
        print("✋ Native ad closed by user")
    }
}
```

### MREC Ads (Medium Rectangle)

MREC ads are 300x250 pixel banner ads that provide more space for rich content.

```objc
@interface YourViewController () <CLXBannerDelegate>
@property (nonatomic, strong) CLXBannerAdView *mrecAd;
@end

@implementation YourViewController

- (void)createMRECAd {
    // Create MREC ad
    self.mrecAd = [[CloudXCore shared] createMRECWithPlacement:@"your-mrec-placement"
                                                viewController:self
                                                      delegate:self];
    
    if (self.mrecAd) {
        // Add to view hierarchy
        self.mrecAd.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addSubview:self.mrecAd];
        
        // Set constraints for 300x250 size
        [NSLayoutConstraint activateConstraints:@[
            [self.mrecAd.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
            [self.mrecAd.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-20],
            [self.mrecAd.widthAnchor constraintEqualToConstant:300],
            [self.mrecAd.heightAnchor constraintEqualToConstant:250]
        ]];
        
        // Load the ad
        [self.mrecAd load];
    }
}

#pragma mark - CLXBannerDelegate

- (void)didLoadWithAd:(CLXAd *)ad {
    NSLog(@"✅ MREC ad loaded successfully");
}

- (void)failToLoadWithAd:(CLXAd *)ad error:(NSError *)error {
    NSLog(@"❌ MREC ad failed to load: %@", error.localizedDescription);
}

- (void)didShowWithAd:(CLXAd *)ad {
    NSLog(@"👀 MREC ad shown");
}

- (void)didClickWithAd:(CLXAd *)ad {
    NSLog(@"👆 MREC ad clicked");
}

- (void)impressionOn:(CLXAd *)ad {
    NSLog(@"👁️ MREC ad impression recorded");
}

- (void)didHideWithAd:(CLXAd *)ad {
    NSLog(@"🔚 MREC ad hidden");
}

- (void)closedByUserActionWithAd:(CLXAd *)ad {
    NSLog(@"✋ MREC ad closed by user");
}

@end
```

```swift
class YourViewController: UIViewController, CLXBannerDelegate {
    private var mrecAd: CLXBannerAdView?
    
    func createMRECAd() {
        // Create MREC ad
        mrecAd = CloudXCore.shared.createMREC(withPlacement: "your-mrec-placement",
                                             viewController: self,
                                             delegate: self)
        
        if let mrecAd = mrecAd {
            // Add to view hierarchy
            mrecAd.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(mrecAd)
            
            // Set constraints for 300x250 size
            NSLayoutConstraint.activate([
                mrecAd.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                mrecAd.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
                mrecAd.widthAnchor.constraint(equalToConstant: 300),
                mrecAd.heightAnchor.constraint(equalToConstant: 250)
            ])
            
            // Load the ad
            mrecAd.load()
        }
    }
}

// MARK: - CLXBannerDelegate
extension YourViewController {
    func didLoad(with ad: CLXAd) {
        print("✅ MREC ad loaded successfully")
    }
    
    func failToLoad(with ad: CLXAd, error: Error) {
        print("❌ MREC ad failed to load: \(error.localizedDescription)")
    }
    
    func didShow(with ad: CLXAd) {
        print("👀 MREC ad shown")
    }
    
    func didClick(with ad: CLXAd) {
        print("👆 MREC ad clicked")
    }
    
    func impression(on ad: CLXAd) {
        print("👁️ MREC ad impression recorded")
    }
    
    func didHide(with ad: CLXAd) {
        print("🔚 MREC ad hidden")
    }
    
    func closedByUserAction(with ad: CLXAd) {
        print("✋ MREC ad closed by user")
    }
}
```

## Advanced Features

### Privacy Compliance & GPP Integration

The CloudX SDK supports privacy compliance for GDPR, CCPA, and COPPA regulations. Publishers are responsible for obtaining consent through their Consent Management Platform (CMP) and providing the privacy signals to our SDK.

**Objective-C:**
```objc
// Set CCPA privacy string
[CloudXCore setCCPAPrivacyString:@"1YNN"];

// Set GDPR consent (⚠️ Not yet supported by CloudX servers)
[CloudXCore setIsUserConsent:YES];

// Set COPPA compliance (⚠️ Not yet supported by CloudX servers)
[CloudXCore setIsAgeRestrictedUser:YES];

// Set "do not sell" preference (CCPA)
[CloudXCore setIsDoNotSell:YES];
```

**Swift:**
```swift
// Set CCPA privacy string
CloudXCore.setCCPAPrivacyString("1YNN")

// Set GDPR consent (⚠️ Not yet supported by CloudX servers)
CloudXCore.setIsUserConsent(true)

// Set COPPA compliance (⚠️ Not yet supported by CloudX servers)
CloudXCore.setIsAgeRestrictedUser(true)

// Set "do not sell" preference (CCPA)
CloudXCore.setIsDoNotSell(true)
```

#### Privacy API Reference

| Method | Type | Description |
|--------|------|-------------|
| `setCCPAPrivacyString:` | String | Set CCPA privacy string (e.g., "1YNN") |
| `setIsUserConsent:` | Boolean | Set GDPR consent (⚠️ Not yet supported by servers) |
| `setIsAgeRestrictedUser:` | Boolean | Set COPPA compliance (⚠️ Not yet supported by servers) |
| `setIsDoNotSell:` | Boolean | Set "do not sell" preference for CCPA compliance |

#### GPP String Integration

If you're using a Global Privacy Platform (GPP) string, you'll need to parse it and extract the individual privacy components before passing them to our SDK:

```objc
// Example: Parse your GPP string and extract components
NSString *gppString = @"DBACNYA~CPXxRfAPXxRfAAfKABENB-CgAAAAAAAAAAYgAAAAAAAA~1YNN";

// Your CMP should parse the GPP string and provide:
NSString *ccpaString = [yourCMP extractCCPAStringFromGPP:gppString];
BOOL gdprConsent = [yourCMP extractGDPRConsentFromGPP:gppString];
BOOL coppaApplies = [yourCMP extractCOPPAFromGPP:gppString];

// Then set the individual components using CloudX privacy API
[CloudXCore setCCPAPrivacyString:ccpaString];
[CloudXCore setIsUserConsent:gdprConsent];
[CloudXCore setIsAgeRestrictedUser:coppaApplies];
```

#### Privacy-Aware Ad Serving

The SDK automatically uses privacy information to:
- Respect CCPA "do not sell" preferences (fully supported)
- Handle GDPR consent flags (⚠️ server support pending)
- Handle COPPA age restrictions (⚠️ server support pending)
- Provide privacy-safe fallbacks for ad targeting

**Note**: Publishers must obtain proper consent through their own Consent Management Platform before providing privacy signals to the SDK. Currently, only CCPA is fully supported by CloudX servers.

### User Targeting

**Objective-C:**
```objc
// Set hashed user ID for targeting
[[CloudXCore shared] setHashedUserID:@"hashed-user-id"];

// Set key-value pairs for targeting
[[CloudXCore shared] setHashedKeyValue:@"age" value:@"25"];
[[CloudXCore shared] setHashedKeyValue:@"gender" value:@"male"];

// Set multiple key-value pairs
NSDictionary *userData = @{
    @"age": @"25",
    @"gender": @"male",
    @"location": @"US"
};
[[CloudXCore shared] setKeyValueDictionary:userData];

// Set bidder-specific targeting
[[CloudXCore shared] setBidderKeyValue:@"adnetwork" key:@"custom_key" value:@"custom_value"];

// User-level targeting (cleared when privacy regulations require removing personal data)
[[CloudXCore shared] setUserKeyValue:@"age" value:@"25"];
[[CloudXCore shared] setUserKeyValue:@"interests" value:@"gaming"];

// App-level targeting (NOT affected by privacy regulations)
[[CloudXCore shared] setAppKeyValue:@"app_version" value:@"1.2.0"];
[[CloudXCore shared] setAppKeyValue:@"build_type" value:@"release"];

// Clear all user and app-level key-value pairs
[[CloudXCore shared] clearAllKeyValues];
```

**Swift:**
```swift
// Set hashed user ID for targeting
CloudXCore.shared.provideUserDetails(withHashedUserID: "hashed-user-id")

// Set key-value pairs for targeting
CloudXCore.shared.useHashedKeyValue(withKey: "age", value: "25")
CloudXCore.shared.useHashedKeyValue(withKey: "gender", value: "male")

// Set multiple key-value pairs
let userData: [String: String] = [
    "age": "25",
    "gender": "male",
    "location": "US"
]
CloudXCore.shared.useKeyValues(withUserDictionary: userData)

// Set bidder-specific targeting
CloudXCore.shared.useBidderKeyValue(withBidder: "adnetwork", key: "custom_key", value: "custom_value")

// User-level targeting (cleared when privacy regulations require removing personal data)
CloudXCore.shared.setUserKeyValue("age", value: "25")
CloudXCore.shared.setUserKeyValue("interests", value: "gaming")

// App-level targeting (NOT affected by privacy regulations)
CloudXCore.shared.setAppKeyValue("app_version", value: "1.2.0")
CloudXCore.shared.setAppKeyValue("build_type", value: "release")

// Clear all user and app-level key-value pairs
CloudXCore.shared.clearAllKeyValues()
```

### Ad Lifecycle Management

**Objective-C:**
```objc
// Check if ad is ready
BOOL isReady = [self.bannerAd isReady];

// Destroy ad and release resources
[self.bannerAd destroy];

// Suspend preloading when not visible (banner only)
self.bannerAd.suspendPreloadWhenInvisible = YES;
```

**Swift:**
```swift
// Check if ad is ready
let isReady = bannerAd?.isReady ?? false

// Destroy ad and release resources
bannerAd?.destroy()

// Suspend preloading when not visible (banner only)
bannerAd?.suspendPreloadWhenInvisible = true
```

## Complete App Example

Here's a complete example showing how to integrate all ad types in a single app:

**Objective-C:**
```objc
// AppDelegate.m
#import "AppDelegate.h"
#import <CloudXCore/CloudXCore.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Initialize CloudX SDK
    [[CloudXCore shared] initializeSDKWithAppKey:@"your-app-key-here" 
                              hashedUserID:@"user-id-optional" 
                                completion:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            NSLog(@"✅ CloudX SDK initialized successfully");
        } else {
            NSLog(@"❌ Failed to initialize CloudX SDK: %@", error.localizedDescription);
        }
    }];
    
    return YES;
}

@end

// MainViewController.m
#import "MainViewController.h"
#import <CloudXCore/CloudXCore.h>

@interface MainViewController () <CLXBannerDelegate, CLXInterstitialDelegate, CLXRewardedDelegate, CLXNativeDelegate>
@property (nonatomic, strong) CLXBannerAdView *bannerAd;
@property (nonatomic, strong) CLXPublisherFullscreenAd *interstitialAd;
@property (nonatomic, strong) CLXPublisherFullscreenAd *rewardedAd;
@property (nonatomic, strong) CLXNativeAdView *nativeAd;
@property (nonatomic, strong) CLXBannerAdView *mrecAd;
@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Wait for SDK initialization
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sdkInitialized)
                                                 name:@"cloudXSDKInitialized"
                                               object:nil];
    
    [self setupUI];
}

- (void)setupUI {
    // Create buttons for each ad type
    [self createButtonWithTitle:@"Show Banner" action:@selector(showBanner)];
    [self createButtonWithTitle:@"Show Interstitial" action:@selector(showInterstitial)];
    [self createButtonWithTitle:@"Show Rewarded" action:@selector(showRewarded)];
    [self createButtonWithTitle:@"Show Native" action:@selector(showNative)];
    [self createButtonWithTitle:@"Show MREC" action:@selector(showMREC)];
}

- (void)sdkInitialized {
    // Create all ad instances
    [self createBannerAd];
    [self createInterstitialAd];
    [self createRewardedAd];
    [self createNativeAd];
    [self createMRECAd];
}

// Implementation of ad creation and delegate methods...
// (See individual ad type examples above)

@end
```

**Swift:**
```swift
// AppDelegate.swift
import UIKit
import CloudXCore

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Initialize CloudX SDK
        CloudXCore.shared.initSDK(withAppKey: "your-app-key-here", 
                                 hashedUserID: "user-id-optional") { success, error in
            if success {
                print("✅ CloudX SDK initialized successfully")
            } else {
                print("❌ Failed to initialize CloudX SDK: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
        
        return true
    }
}

// MainViewController.swift
import UIKit
import CloudXCore

class MainViewController: UIViewController {
    private var bannerAd: CLXBannerAdView?
    private var interstitialAd: CLXInterstitial?
    private var rewardedAd: CLXRewardedInterstitial?
    private var nativeAd: CLXNativeAdView?
    private var mrecAd: CLXBannerAdView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Wait for SDK initialization
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(sdkInitialized),
                                             name: NSNotification.Name("cloudXSDKInitialized"),
                                             object: nil)
        
        setupUI()
    }
    
    private func setupUI() {
        // Create buttons for each ad type
        createButton(title: "Show Banner", action: #selector(showBanner))
        createButton(title: "Show Interstitial", action: #selector(showInterstitial))
        createButton(title: "Show Rewarded", action: #selector(showRewarded))
        createButton(title: "Show Native", action: #selector(showNative))
        createButton(title: "Show MREC", action: #selector(showMREC))
    }
    
    @objc private func sdkInitialized() {
        // Create all ad instances
        createBannerAd()
        createInterstitialAd()
        createRewardedAd()
        createNativeAd()
        createMRECAd()
    }
    
    // Implementation of ad creation and delegate methods...
    // (See individual ad type examples above)
}

// MARK: - Ad Delegates
extension MainViewController: CLXBannerDelegate, CLXInterstitialDelegate, CLXRewardedDelegate, CLXNativeDelegate {
    // Implement delegate methods for each ad type
    // (See individual ad type examples above)
}
```

## API Reference

### Core Methods

| Method | Description |
|--------|-------------|
| `initializeSDKWithAppKey:completion:` | Initialize SDK with app key |
| `initializeSDKWithAppKey:hashedUserID:completion:` | Initialize SDK with app key and user ID |
| `isInitialized` | Check if SDK is initialized |
| `sdkVersion` | Get SDK version |

### Ad Creation Methods

| Method | Description |
|--------|-------------|
| `createBannerWithPlacement:viewController:delegate:tmax:` | Create banner ad |
| `createMRECWithPlacement:viewController:delegate:` | Create MREC ad |
| `createInterstitialWithPlacement:` | Create interstitial ad (set delegate property after creation) |
| `createRewardedWithPlacement:` | Create rewarded ad (set delegate property after creation) |
| `createNativeAdWithPlacement:viewController:delegate:` | Create native ad |

### User Targeting Methods

| Method | Description |
|--------|-------------|
| `setHashedUserID:` | Set hashed user ID |
| `setHashedKeyValue:value:` | Set key-value pair |
| `setKeyValueDictionary:` | Set multiple key-value pairs |
| `setBidderKeyValue:key:value:` | Set bidder-specific targeting |
| `setUserKeyValue:value:` | Set user-level targeting (cleared by privacy regulations) |
| `setAppKeyValue:value:` | Set app-level targeting (NOT affected by privacy) |
| `clearAllKeyValues` | Clear all user and app-level key-value pairs |

### Ad Control Methods

| Method | Description |
|--------|-------------|
| `load` | Load ad content |
| `isReady` | Check if ad is ready |
| `showFromViewController:` | Show fullscreen ad |
| `destroy` | Destroy ad and release resources |

### Delegate Callbacks

All ad types support these common callbacks:
- `didLoadWithAd:` - Ad loaded successfully
- `failToLoadWithAd:error:` - Ad failed to load
- `didShowWithAd:` - Ad was shown
- `failToShowWithAd:error:` - Ad failed to show
- `didHideWithAd:` - Ad was hidden
- `didClickWithAd:` - Ad was clicked
- `impressionOn:` - Ad impression recorded
- `closedByUserActionWithAd:` - Ad closed by user

**Rewarded ads additionally support:**
- `userRewarded:` - User earned reward
- `rewardedVideoStarted:` - Video started
- `rewardedVideoCompleted:` - Video completed

## How Ads Load (Automatic Waterfall)

When you call `load`, the SDK automatically tries multiple ad sources in priority order. **You don't need to do anything** - the SDK handles retries internally.

- **Success**: Your `didLoadWithAd:` callback fires when ANY source succeeds
- **Failure**: Your `failToLoadWithAd:error:` callback fires ONLY after ALL sources fail
- **No manual intervention needed** - the waterfall happens automatically and transparently

```objc
[self.bannerAd load];
// SDK tries: CloudX auction → Meta → Google → Other adapters
// You only get ONE callback: success or final failure
```

**Bottom line:** A single ad source failing doesn't trigger your error callback. The SDK keeps trying until something works or everything fails.

## Troubleshooting

### Common Issues

1. **SDK not initialized**
   - Ensure you call `initializeSDKWithAppKey:completion:` before creating ads
   - Check that the completion block is called with success

2. **Ads not loading**
   - Verify your placement IDs are correct
   - Check network connectivity
   - Ensure you're testing on a real device (not simulator)

3. **Delegate methods not called**
   - Verify your view controller implements the correct delegate protocol
   - Ensure the delegate is set when creating ads

4. **Build errors**
   - Make sure you're using iOS 14.0 or later
   - Verify all required frameworks are linked
   - Check that you're using the correct import statements

### Debug Logging

The CloudX SDK provides logging to help with integration and troubleshooting.

**Default Behavior:**
- ✅ **Errors are always visible** - Critical issues are logged even without verbose mode
- 🔇 **Debug/Info logs are opt-in** - Enable verbose mode to see detailed diagnostic information

**Enable Verbose Logging:**

**Objective-C:**
```objc
// Enable verbose logging (call early in app lifecycle, before SDK initialization)
[CloudXCore setLoggingEnabled:YES];

// Initialize SDK
[[CloudXCore shared] initializeSDKWithAppKey:@"your-app-key" completion:^(BOOL success, NSError * _Nullable error) {
    // Handle initialization
}];
```

**Swift:**
```swift
// Enable verbose logging (call early in app lifecycle, before SDK initialization)
CloudXCore.setLoggingEnabled(true)

// Initialize SDK
CloudXCore.shared.initializeSDK(appKey: "your-app-key") { success, error in
    // Handle initialization
}
```

**When to Enable:**
- Call `setLoggingEnabled:` as early as possible (e.g., in `application:didFinishLaunchingWithOptions:`)
- Call it **before** SDK initialization to capture all diagnostic logs
- Only enable in development builds or when debugging issues

**Log Levels:**
- **Error** ❌ (Always visible): Critical failures, initialization errors, network issues
- **Info** ℹ️ (Verbose mode only): General SDK operations, ad loading, lifecycle events  
- **Debug** 🔍 (Verbose mode only): Detailed diagnostic information, state changes, internal operations

**Best Practice:** Keep verbose logging disabled in production to reduce console noise, but errors will still be visible for debugging user reports.

## Support

- **Documentation**: [CloudX iOS Docs](https://github.com/cloudx-io/cloudx-ios)
- **Issues**: [GitHub Issues](https://github.com/cloudx-io/cloudx-ios/issues)
- **Email**: eng@cloudx.io

## License

This project is licensed under the same license as the CloudX Core SDK.
