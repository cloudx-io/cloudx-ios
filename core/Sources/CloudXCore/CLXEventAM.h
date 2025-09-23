/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXEventAM.h
 * @brief Event model for bulk API matching Android's EventAM exactly
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Event model for bulk API requests
 * Matches Android's data class EventAM exactly
 */
@interface CLXEventAM : NSObject

@property (nonatomic, copy) NSString *impression;    // XOR encrypted payload
@property (nonatomic, copy) NSString *campaignId;    // Base64 campaign ID
@property (nonatomic, copy) NSString *eventValue;    // "N/A" for metrics
@property (nonatomic, copy) NSString *eventName;     // "SDK_METRICS"
@property (nonatomic, copy) NSString *type;          // "SDK_METRICS"

- (instancetype)initWithImpression:(NSString *)impression
                         campaignId:(NSString *)campaignId
                         eventValue:(NSString *)eventValue
                          eventName:(NSString *)eventName
                               type:(NSString *)type;

/**
 * Convert to dictionary for JSON serialization
 */
- (NSDictionary *)toDictionary;

@end

NS_ASSUME_NONNULL_END
