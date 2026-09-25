/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CloudXCore/CLXAdapterLogger.h>
#import <CloudXCore/CLXExport.h>
#import <CloudXCore/CLXMediatorTypes.h>

NS_ASSUME_NONNULL_BEGIN

/** Base parameters that Core passes to mediator modules. */
CLX_PUBLIC_MEDIATOR
@interface CLXMediatorParams : NSObject

@property (nonatomic, strong, readonly) id<CLXAdapterLogger> logger;
@property (nonatomic, copy, readonly) NSString *sdkVersion;
/// Comparable version code: major * 1,000,000 + minor * 1,000 + patch.
@property (nonatomic, assign, readonly) NSInteger sdkVersionCode;
/// Immutable snapshots of Foundation value types. Unsupported values reject construction.
@property (nonatomic, copy, readonly) NSDictionary<NSString *, id> *serverExtras;
@property (nonatomic, copy, readonly) NSDictionary<NSString *, id> *localExtras;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

/**
 * Reports mediator initialization completion.
 *
 * A module must call this block exactly once. A nil error reports success; a
 * non-null error reports failure. The extras dictionary must be immutable and
 * non-null. Use an empty dictionary when no extras exist.
 */
typedef void (^CLXMediatorInitializationCompletion)(NSError * _Nullable error,
                                                    NSDictionary<NSString *, id> *extras);

/** Parameters for mediator initialization. */
CLX_PUBLIC_MEDIATOR
@interface CLXMediatorInitializationParams : CLXMediatorParams

@property (nonatomic, assign, readonly, getter=isTestMode) BOOL testMode;
@property (nonatomic, copy, readonly) CLXMediatorInitializationCompletion completion;

@end

/** Parameters used to create one interstitial mediator attempt. */
CLX_PUBLIC_MEDIATOR
@interface CLXInterstitialMediatorParams : CLXMediatorParams

@property (nonatomic, copy, readonly) NSString *adUnitId;

@end

/** Parameters used to create one rewarded mediator attempt. */
CLX_PUBLIC_MEDIATOR
@interface CLXRewardedMediatorParams : CLXMediatorParams

@property (nonatomic, copy, readonly) NSString *adUnitId;

@end

/** Parameters for a mediator load operation. */
CLX_PUBLIC_MEDIATOR
@interface CLXMediatorLoadParams : NSObject

@property (nonatomic, strong, readonly, nullable) CLXMediatorFloor *floor;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

/** Parameters for a mediator show operation. */
CLX_PUBLIC_MEDIATOR
@interface CLXMediatorShowParams : NSObject

@property (nonatomic, strong, readonly) UIViewController *viewController;
@property (nonatomic, copy, readonly, nullable) NSString *placement;
@property (nonatomic, copy, readonly, nullable) NSString *customData;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
