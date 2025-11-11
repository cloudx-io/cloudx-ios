//
//  CLXInMobiBaseFactory.h
//  CloudXMediationInMobiAdapter
//
//  Created by CloudX Team.
//

#import <Foundation/Foundation.h>

@class CLXLogger;

NS_ASSUME_NONNULL_BEGIN

/**
 * Base factory with shared utility methods for InMobi adapter factories.
 */
@interface CLXInMobiBaseFactory : NSObject

/**
 * Shared logger instance for all factories
 */
@property (nonatomic, strong, readonly) CLXLogger *logger;

/**
 * Extracts InMobi placement ID from placement ID string
 * @param placementIDString Placement ID as string (e.g., "1234567890")
 * @return Placement ID as long long
 */
- (long long)extractPlacementID:(NSString *)placementIDString;

/**
 * Validates bid payload
 * @param bidPayload Bid payload string
 * @return YES if valid, NO otherwise
 */
- (BOOL)validateBidPayload:(nullable NSString *)bidPayload;

@end

NS_ASSUME_NONNULL_END

