/*
 * Copyright (c) 2025 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Platforms that can provide ILRD (Impression Level Revenue Data) events.
 */
typedef NS_ENUM(NSInteger, CLXIlrdPlatform) {
    CLXIlrdPlatformAl = 0,
};

/**
 * @brief ILRD provider event model used by the provider-to-tracker pipeline.
 *
 * This mirrors the Android split between raw provider fields and normalized SDK
 * fields. Provider implementations populate this model, then the tracker
 * serializes it into the backend payload.
 */
@interface CLXIlrdProviderEvent : NSObject

/**
 * @brief Creates an ILRD provider event with the required provider metadata.
 */
- (instancetype)initWithTimestamp:(NSNumber *)timestamp
                         platform:(NSString *)platform NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/**
 * @brief When the impression was captured (Unix epoch milliseconds).
 */
@property (nonatomic, copy) NSNumber *timestamp;
/**
 * @brief Mediation platform that reported the event.
 */
@property (nonatomic, copy) NSString *platform;
/**
 * @brief Estimated revenue in USD for this impression.
 */
@property (nonatomic, copy, nullable) NSNumber *revenue;
/**
 * @brief Revenue precision level reported by the mediation platform.
 */
@property (nonatomic, copy, nullable) NSString *precision;
/**
 * @brief User country code in ISO 3166-1 alpha-2 format.
 */
@property (nonatomic, copy, nullable) NSString *countryCode;
/**
 * @brief Ad network that served the winning impression.
 */
@property (nonatomic, copy, nullable) NSString *networkName;
/**
 * @brief Ad unit identifier from the mediation platform.
 */
@property (nonatomic, copy, nullable) NSString *adUnitId;
/**
 * @brief Network-side ad unit or placement identifier.
 */
@property (nonatomic, copy, nullable) NSString *thirdPartyAdPlacementId;
/**
 * @brief Raw ad format string reported by the mediation provider.
 *
 * This value is sent to the backend as the source of truth so unknown provider
 * formats remain visible instead of being dropped during SDK-side normalization.
 */
@property (nonatomic, copy, nullable) NSString *rawAdFormat;
/**
 * @brief Best-effort CX-normalized ad format derived from [rawAdFormat].
 *
 * This stays internal-only for SDK behavior that depends on known ad types,
 * such as matching ILRD impressions back to the most recent CX no-fill auction.
 */
@property (nonatomic, copy, nullable) NSString *adFormat;
/**
 * @brief Creative identifier reported by the ad network.
 */
@property (nonatomic, copy, nullable) NSString *creativeId;
/**
 * @brief Network placement identifier reported by the mediation platform.
 */
@property (nonatomic, copy, nullable) NSString *networkPlacement;
/**
 * @brief User segment string reported by the mediation platform.
 */
@property (nonatomic, copy, nullable) NSString *userSegment;
/**
 * @brief Unique impression identifier reported by the mediation platform.
 */
@property (nonatomic, copy, nullable) NSString *eventId;

@end

/**
 * Callback block invoked when an ILRD event is received.
 */
typedef void (^CLXIlrdEventCallback)(CLXIlrdProviderEvent *event);

/**
 * Protocol for ILRD event providers.
 * Each provider subscribes to a specific ad platform's revenue events
 * and forwards them via the event callback.
 */
@protocol CLXIlrdProvider <NSObject>

/**
 * The platform this provider handles.
 */
@property (nonatomic, readonly) CLXIlrdPlatform platform;

/**
 * Subscribe to ILRD events from the platform.
 * Returns YES on success, NO on failure (error details in outError).
 */
- (BOOL)subscribeWithError:(NSError **)outError;

/**
 * Unsubscribe from ILRD events.
 * Returns YES on success, NO on failure (error details in outError).
 */
- (BOOL)unsubscribeWithError:(NSError **)outError;

/**
 * Set the callback to receive ILRD events.
 * Pass nil to clear the callback.
 */
- (void)setEventCallback:(nullable CLXIlrdEventCallback)callback;

@end

NS_ASSUME_NONNULL_END
