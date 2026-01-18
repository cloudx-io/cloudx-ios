/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file MockCLXSettings.h
 * @brief Mock CLXSettings for unit testing retry behavior
 *
 * DESIGN: SYNCHRONOUS mock - all methods return values immediately.
 * No dispatch_async, no delays, no timing dependencies.
 *
 * SOLID: Interface Segregation - only mocks retry-related methods needed by tests.
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXSettings.h>

NS_ASSUME_NONNULL_BEGIN

@interface MockCLXSettings : CLXSettings

/// Control retry behavior for each ad type
@property (nonatomic, assign) BOOL bannerRetriesEnabled;
@property (nonatomic, assign) BOOL interstitialRetriesEnabled;
@property (nonatomic, assign) BOOL rewardedRetriesEnabled;
@property (nonatomic, assign) BOOL nativeRetriesEnabled;

/// Optional: Control IFA return value for testing
@property (nonatomic, copy, nullable) NSString *mockIFA;

/// Convenience: Enable all retries at once
- (void)enableAllRetries;

/// Convenience: Disable all retries at once
- (void)disableAllRetries;

@end

NS_ASSUME_NONNULL_END
