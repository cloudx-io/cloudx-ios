//
//  CLXInMobiErrorHandler.h
//  CloudXMediationInMobiAdapter
//
//  Created by CloudX Team.
//

#import <Foundation/Foundation.h>

@class CLXLogger;

NS_ASSUME_NONNULL_BEGIN

/**
 * Centralized error handling for InMobi adapter.
 * Maps InMobi error codes to CloudX error codes and provides enhanced error descriptions.
 */
@interface CLXInMobiErrorHandler : NSObject

/**
 * Maps InMobi error to CloudX error with enhanced description
 * @param error InMobi error
 * @param logger Logger for error recording
 * @param context Error context (e.g., "Interstitial Load")
 * @param placementID Placement ID for logging
 * @return Enhanced CloudX error
 */
+ (NSError *)handleInMobiError:(NSError *)error
                    withLogger:(CLXLogger *)logger
                       context:(NSString *)context
                   placementID:(NSString *)placementID;

@end

NS_ASSUME_NONNULL_END

