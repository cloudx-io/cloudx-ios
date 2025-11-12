#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXSettings : NSObject

+ (instancetype)sharedInstance;

// MARK: - IFA Configuration

/// Retrieves the Identifier for Advertising (IFA) based on a priority system.
/// Priority: UserDefaults override > Real device IDFA > Placeholder (if no IDFA available)
- (NSString *)getIFA;

// MARK: - Retry Configuration

/// Checks if banner ad retries should be enabled (defaults to NO for IDFA protection).
- (BOOL)shouldEnableBannerRetries;

/// Checks if interstitial ad retries should be enabled (defaults to NO for IDFA protection).
- (BOOL)shouldEnableInterstitialRetries;

/// Checks if rewarded ad retries should be enabled (defaults to NO for IDFA protection).
- (BOOL)shouldEnableRewardedRetries;

/// Checks if native ad retries should be enabled (defaults to NO for IDFA protection).
- (BOOL)shouldEnableNativeRetries;

@end

NS_ASSUME_NONNULL_END
