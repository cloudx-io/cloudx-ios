//
//  CLXMolocoErrorHandler.h
//  CloudXMolocoAdapter
//
//  Created by CloudX on 2024.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXLogger;

/**
 * Centralized error handling for Moloco adapter.
 * Maps Moloco SDK errors to CloudX error codes.
 */
@interface CLXMolocoErrorHandler : NSObject

/**
 * Maps a Moloco SDK error to a CloudX error.
 * @param molocoError The error from Moloco SDK
 * @param logger Logger instance for error logging
 * @param context Context description (e.g., "Interstitial Load")
 * @param placementID The placement ID for logging
 * @return Mapped CloudX error
 */
+ (NSError *)handleMolocoError:(NSError *)molocoError
                    withLogger:(CLXLogger *)logger
                       context:(NSString *)context
                   placementID:(nullable NSString *)placementID;

@end

NS_ASSUME_NONNULL_END

