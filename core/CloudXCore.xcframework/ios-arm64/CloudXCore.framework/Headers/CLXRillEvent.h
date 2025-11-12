/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXRillEvent.h
 * @brief Rill event model matching Android CachedTrackingEvents exactly
 * 
 * Extends CLXBaseEvent with Rill-specific properties
 * Maps to cached_tracking_events_table in SQLite database
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXBaseEvent.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Rill event model matching Android CachedTrackingEvents structure
 * Fields: id, encoded, campaignId, eventValue, eventName, type
 */
@interface CLXRillEvent : CLXBaseEvent

/**
 * Rill-specific properties (matching Android exactly)
 */
@property (nonatomic, strong) NSString *encoded;        // Encrypted/encoded payload
@property (nonatomic, strong) NSString *campaignId;     // Campaign identifier
@property (nonatomic, strong) NSString *eventValue;     // Event value/data
@property (nonatomic, strong) NSString *eventName;      // Event name/type
@property (nonatomic, strong) NSString *type;           // Event category type

/**
 * Initialization
 */
- (instancetype)initWithEventId:(NSString *)eventId
                      sessionId:(NSString *)sessionId
                        encoded:(NSString *)encoded
                     campaignId:(NSString *)campaignId
                     eventValue:(NSString *)eventValue
                      eventName:(NSString *)eventName
                           type:(NSString *)type;

- (instancetype)initWithSessionId:(NSString *)sessionId
                          encoded:(NSString *)encoded
                       campaignId:(NSString *)campaignId
                       eventValue:(NSString *)eventValue
                        eventName:(NSString *)eventName
                             type:(NSString *)type;

/**
 * Factory methods for common Rill events
 */
+ (instancetype)impressionEventWithSessionId:(NSString *)sessionId
                                  campaignId:(NSString *)campaignId
                                     payload:(NSString *)payload;

+ (instancetype)clickEventWithSessionId:(NSString *)sessionId
                             campaignId:(NSString *)campaignId
                                payload:(NSString *)payload;

+ (instancetype)conversionEventWithSessionId:(NSString *)sessionId
                                  campaignId:(NSString *)campaignId
                                     payload:(NSString *)payload;

/**
 * Payload management
 */
- (void)updateEncodedPayload:(NSString *)payload;
- (BOOL)hasValidPayload;

/**
 * Database column names (matching Android table structure)
 */
+ (NSArray<NSString *> *)sqlColumnNames;
+ (NSString *)sqlTableName;

@end

NS_ASSUME_NONNULL_END
