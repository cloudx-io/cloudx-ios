#import <Foundation/Foundation.h>
#import <CloudXCore/CLXBidTokenSource.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * CLXMintegralBidTokenSource - Mintegral Bid Token Generation
 *
 * Supports both basic and enhanced bid token generation.
 * Enhanced tokens include placement/unit ID and ad type for better targeting.
 */
@interface CLXMintegralBidTokenSource : NSObject <CLXBidTokenSource>

@property (nonatomic, strong, readonly) NSString *network;

+ (instancetype)sharedInstance;
+ (instancetype)createInstance;

/**
 * Get bid token with ad-specific information (enhanced, matching AppLovin implementation)
 * This provides better targeting by including placement, unit, and ad type info.
 */
- (void)getTokenWithPlacementId:(nullable NSString *)placementId
                         unitId:(nullable NSString *)unitId
                         adType:(nullable NSNumber *)adType
                     completion:(void (^)(NSDictionary<NSString *, NSString *> * _Nullable,
                                         NSError * _Nullable))completion;

#pragma mark - Ad Type Helpers

+ (NSNumber *)adTypeForBanner;
+ (NSNumber *)adTypeForInterstitial;
+ (NSNumber *)adTypeForRewarded;
+ (NSNumber *)adTypeForNative;
+ (NSNumber *)adTypeForSplash;

@end

NS_ASSUME_NONNULL_END

