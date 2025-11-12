//
//  CLXRetryHelper.h
//  CloudXCore
//
//  Created by CloudX Team.
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdType.h>

@class CLXSettings;
@class CLXLogger;

NS_ASSUME_NONNULL_BEGIN

/**
 * Centralized retry logic helper to follow DRY principles
 */
@interface CLXRetryHelper : NSObject

/**
 * Check if retries should be enabled for the given ad type
 * @param adType The ad type to check
 * @param settings CLXSettings instance
 * @param logger Logger for debug output
 * @param failureBlock Block to execute if retries are disabled (optional)
 * @return YES if retries should continue, NO if disabled
 */
+ (BOOL)shouldRetryForAdType:(CLXAdType)adType
                    settings:(CLXSettings *)settings
                      logger:(nullable CLXLogger *)logger
                failureBlock:(nullable void (^)(NSError *error))failureBlock;

/**
 * Create an error for disabled retries
 * @param adType The ad type
 * @param errorCode Error code to use
 * @return NSError instance
 */
+ (NSError *)retriesDisabledErrorForAdType:(CLXAdType)adType errorCode:(NSInteger)errorCode;

/**
 * Get human-readable name for ad type
 * @param adType The ad type
 * @return String name
 */
+ (NSString *)nameForAdType:(CLXAdType)adType;

@end

NS_ASSUME_NONNULL_END