/*
 * Copyright (c) 2025 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdType.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Notification posted by publisher ad classes after every CX auction.
 * userInfo keys: CLXAuctionResultAdTypeKey (NSNumber wrapping CLXAdType),
 *                CLXAuctionResultAuctionIdKey (NSString),
 *                CLXAuctionResultAdUnitIdKey (NSString),
 *                CLXAuctionResultFilledKey (NSNumber wrapping BOOL),
 *                CLXAuctionResultAuctionPayloadKey (NSString, optional sealed auction token).
 */
FOUNDATION_EXPORT NSNotificationName const CLXAuctionResultNotification;

/** userInfo key for CLXAdType (NSNumber). */
FOUNDATION_EXPORT NSString *const CLXAuctionResultAdTypeKey;
/** userInfo key for auction ID (NSString). */
FOUNDATION_EXPORT NSString *const CLXAuctionResultAuctionIdKey;
/** userInfo key for ad unit ID (NSString). */
FOUNDATION_EXPORT NSString *const CLXAuctionResultAdUnitIdKey;
/** userInfo key for filled flag (NSNumber wrapping BOOL). */
FOUNDATION_EXPORT NSString *const CLXAuctionResultFilledKey;

/// Sealed auction telemetry token for the auction; absent when the response carried none.
FOUNDATION_EXPORT NSString *const CLXAuctionResultAuctionPayloadKey;

NS_ASSUME_NONNULL_END
