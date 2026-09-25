/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdFormat.h>
#import <CloudXCore/CLXExport.h>

NS_ASSUME_NONNULL_BEGIN

/// The thread on which Core must call a mediator operation.
typedef NS_ENUM(NSInteger, CLXMediatorThreadRequirement) {
    CLXMediatorThreadRequirementMain = 0,
    CLXMediatorThreadRequirementBackground = 1,
    CLXMediatorThreadRequirementAny = 2,
};

/// A floor in US dollars for one impression.
CLX_PUBLIC_MEDIATOR
@interface CLXMediatorFloor : NSObject

@property (nonatomic, assign, readonly) double revenuePerImpressionUSD;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

/**
 * An immutable ad-information snapshot.
 *
 * A mediator must create a new snapshot when realized revenue changes. It must
 * not mutate an object that it already sent to Core.
 * Core assigns the mediator identity from the configured load-plan attempt.
 */
CLX_PUBLIC_MEDIATOR
@interface CLXMediatorAdInfo : NSObject

@property (nonatomic, assign, readonly) CLXAdFormat adFormat;
@property (nonatomic, copy, readonly, nullable) NSString *mediatorAdUnitId;
@property (nonatomic, copy, readonly, nullable) NSString *placement;
@property (nonatomic, copy, readonly) NSString *networkName;
@property (nonatomic, copy, readonly, nullable) NSString *networkPlacement;
@property (nonatomic, copy, readonly, nullable) NSString *creativeId;
@property (nonatomic, assign, readonly) double revenuePerImpressionUSD;
@property (nonatomic, copy, readonly) NSString *revenuePrecision;

/**
 * Returns nil for missing required values, unsupported ad formats, or invalid revenue.
 * V1 accepts interstitial and rewarded formats and finite, non-negative revenue.
 * An empty revenuePrecision means precision is unavailable and is preserved.
 */
- (nullable instancetype)initWithAdFormat:(CLXAdFormat)adFormat
                    mediatorAdUnitId:(nullable NSString *)mediatorAdUnitId
                           placement:(nullable NSString *)placement
                         networkName:(NSString *)networkName
                    networkPlacement:(nullable NSString *)networkPlacement
                          creativeId:(nullable NSString *)creativeId
             revenuePerImpressionUSD:(double)revenuePerImpressionUSD
                    revenuePrecision:(NSString *)revenuePrecision NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
