/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

#import <CloudXCore/CLXAdapterParams.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Initialization status reported by an adapter after attempting SDK initialization.
 */
typedef NS_ENUM(NSInteger, CLXAdapterInitializationStatus) {
    /// The adapter is not initialized.
    CLXAdapterInitializationStatusAdapterNotInitialized = -4,

    /// The adapter SDK does not have a meaningful initialization callback/status.
    CLXAdapterInitializationStatusDoesNotApply = -3,

    /// The adapter SDK is currently initializing.
    CLXAdapterInitializationStatusInitializing = -2,

    /// The adapter SDK initialized, but without an explicit success/failure status.
    CLXAdapterInitializationStatusInitializedUnknown = -1,

    /// The adapter SDK initialization failed.
    CLXAdapterInitializationStatusInitializedFailure = 0,

    /// The adapter SDK initialization was successful.
    CLXAdapterInitializationStatusInitializedSuccess = 1
};

/**
 Completion block adapters call exactly once after initialization.

 Pass a terminal initialization status, an error when initialization failed, and
 optional adapter-provided extras for future metadata.
 */
typedef void (^CLXAdapterInitializationCompletion)(CLXAdapterInitializationStatus status,
                                                  NSError * _Nullable error,
                                                  NSDictionary<NSString *, id> * _Nullable extras);

CLX_PUBLIC_ADAPTER
@interface CLXAdapterInitializationParams : CLXAdapterParams

@property (nonatomic, assign, readonly, getter=isTestMode) BOOL testMode;
@property (nonatomic, copy, readonly) CLXAdapterInitializationCompletion completion;

@end

NS_ASSUME_NONNULL_END
