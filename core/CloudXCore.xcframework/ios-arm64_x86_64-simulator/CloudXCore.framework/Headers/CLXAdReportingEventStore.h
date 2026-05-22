/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXAdReportingEventStore.h
 * @brief SQLite-backed durable storage for the legacy Rill SDKIMP and legacy
 *        metrics POST events that flow through CLXAdReportingNetworkService.
 *
 * Mirrors the persist-before-send pattern from CLXWinLossTracker. Two tables
 * (cached_rill_events_table, cached_metrics_events_table) coexist in the
 * cloudx_ad_reporting_pending.sqlite file (in ~/Documents). The file lives
 * alongside (but is independent of) cloudx_winloss.sqlite so deprecation
 * lifecycles for the two AdReporting surfaces and win/loss can move
 * separately.
 *
 * NOT to be confused with the first-party telemetry pipeline (CXD-804) under
 * Sources/CloudXCore/Telemetry: that pipeline has its own JSONL store
 * (CLXPendingTelemetryEventStore → ~/Library/Application Support/CloudX/
 * pending_telemetry.jsonl). The two persistence layers do not share code,
 * disk paths, or wire URLs.
 *
 * Production callers use the default initializer (db name
 * @"cloudx_ad_reporting_pending"). Tests pass a unique-per-test name via
 * initWithDatabaseName: to avoid file collisions.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXSQLiteDatabase;

#pragma mark - Cached Event DTOs (lightweight, no business logic)

/** Cached Rill event row — corresponds to one row in cached_rill_events_table. */
@interface CLXCachedRillEvent : NSObject
@property (nonatomic, copy, readonly) NSNumber *eventId;
@property (nonatomic, copy, readonly) NSString *action;
@property (nonatomic, copy, readonly) NSString *encodedPayload;
@property (nonatomic, copy, readonly) NSString *campaignId;
@property (nonatomic, copy, readonly) NSString *baseUrl;
@property (nonatomic, assign, readonly) int64_t createdAt;

- (instancetype)initWithEventId:(NSNumber *)eventId
                         action:(NSString *)action
                 encodedPayload:(NSString *)encodedPayload
                     campaignId:(NSString *)campaignId
                        baseUrl:(NSString *)baseUrl
                      createdAt:(int64_t)createdAt NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

/** Cached metrics event row — corresponds to one row in cached_metrics_events_table. */
@interface CLXCachedMetricsEvent : NSObject
@property (nonatomic, copy, readonly) NSNumber *eventId;
@property (nonatomic, copy, readonly) NSData *requestBody;
@property (nonatomic, copy, readonly) NSString *baseUrl;
@property (nonatomic, assign, readonly) int64_t createdAt;

- (instancetype)initWithEventId:(NSNumber *)eventId
                    requestBody:(NSData *)requestBody
                        baseUrl:(NSString *)baseUrl
                      createdAt:(int64_t)createdAt NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

#pragma mark - Store

/**
 * Per-pipeline save / getAll / delete trio for Rill SDKIMP and metrics POST events.
 * Owns its own CLXSQLiteDatabase instance keyed by databaseName.
 */
@interface CLXAdReportingEventStore : NSObject

@property (nonatomic, strong, readonly) CLXSQLiteDatabase *database;

/** Production callers use this — defaults to db name @"cloudx_ad_reporting_pending". */
- (instancetype)init;

/** Tests inject a unique-per-test db name; production passes @"cloudx_ad_reporting_pending". */
- (instancetype)initWithDatabaseName:(NSString *)databaseName NS_DESIGNATED_INITIALIZER;

/** SQLite file path for this store (forwarded from underlying CLXSQLiteDatabase). */
- (NSString *)databasePath;

/** Closes the SQLite handle (forwarded from underlying CLXSQLiteDatabase). */
- (void)close;

#pragma mark - Rill pipeline

/**
 * Saves a Rill event row before sending. Returns the new row's auto-incremented id
 * for later deletion on success. Returns nil if any required field is nil/empty.
 */
- (nullable NSNumber *)saveRillEventWithAction:(NSString *)action
                                encodedPayload:(NSString *)encodedPayload
                                    campaignId:(NSString *)campaignId
                                       baseUrl:(NSString *)baseUrl;

/** Returns all currently-cached Rill events, ordered by id ascending. Never nil. */
- (NSArray<CLXCachedRillEvent *> *)getAllCachedRillEvents;

/** Deletes the row with the given id (no-op if not found or id is nil). */
- (void)deleteRillEventWithId:(nullable NSNumber *)eventId;

#pragma mark - Metrics pipeline

/**
 * Saves a metrics event row before sending. The requestBody is the **raw JSON
 * payload bytes** (NOT the source dictionary, NOT pre-gzipped). The send path
 * (CLXBaseNetworkService) applies gzip deterministically on every send, so live
 * sends and replay-on-launch send byte-equivalent gzipped bodies even after
 * NSUserDefaults rotation between sessions.
 *
 * We persist raw JSON (rather than pre-gzipped bytes) because:
 *   - The gzip step is owned by CLXBaseNetworkService and is identical for live
 *     and replay paths, so wire-byte equivalence is preserved either way.
 *   - Persisting the post-gzip bytes would couple the store to a specific
 *     compression implementation; persisting raw JSON keeps the contract simple.
 *
 * Returns the new row's auto-incremented id, or nil if any required field is invalid.
 */
- (nullable NSNumber *)saveMetricsEventWithRequestBody:(NSData *)requestBody
                                               baseUrl:(NSString *)baseUrl;

/** Returns all currently-cached metrics events, ordered by id ascending. Never nil. */
- (NSArray<CLXCachedMetricsEvent *> *)getAllCachedMetricsEvents;

/** Deletes the row with the given id (no-op if not found or id is nil). */
- (void)deleteMetricsEventWithId:(nullable NSNumber *)eventId;

@end

NS_ASSUME_NONNULL_END
