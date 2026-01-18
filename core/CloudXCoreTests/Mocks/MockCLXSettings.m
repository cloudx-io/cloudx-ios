/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import "MockCLXSettings.h"

@implementation MockCLXSettings

#pragma mark - Initialization

- (instancetype)init {
    self = [super init];
    if (self) {
        // Default: all retries disabled (matches production default)
        _bannerRetriesEnabled = NO;
        _interstitialRetriesEnabled = NO;
        _rewardedRetriesEnabled = NO;
        _nativeRetriesEnabled = NO;
        _mockIFA = nil;
    }
    return self;
}

#pragma mark - CLXSettings Overrides (SYNCHRONOUS)

- (BOOL)shouldEnableBannerRetries {
    // SYNCHRONOUS: Returns immediately, no UserDefaults lookup
    return self.bannerRetriesEnabled;
}

- (BOOL)shouldEnableInterstitialRetries {
    // SYNCHRONOUS: Returns immediately, no UserDefaults lookup
    return self.interstitialRetriesEnabled;
}

- (BOOL)shouldEnableRewardedRetries {
    // SYNCHRONOUS: Returns immediately, no UserDefaults lookup
    return self.rewardedRetriesEnabled;
}

- (BOOL)shouldEnableNativeRetries {
    // SYNCHRONOUS: Returns immediately, no UserDefaults lookup
    return self.nativeRetriesEnabled;
}

- (NSString *)getIFA {
    // SYNCHRONOUS: Returns mock value or calls super
    if (self.mockIFA) {
        return self.mockIFA;
    }
    return [super getIFA];
}

#pragma mark - Convenience Methods

- (void)enableAllRetries {
    self.bannerRetriesEnabled = YES;
    self.interstitialRetriesEnabled = YES;
    self.rewardedRetriesEnabled = YES;
    self.nativeRetriesEnabled = YES;
}

- (void)disableAllRetries {
    self.bannerRetriesEnabled = NO;
    self.interstitialRetriesEnabled = NO;
    self.rewardedRetriesEnabled = NO;
    self.nativeRetriesEnabled = NO;
}

@end
