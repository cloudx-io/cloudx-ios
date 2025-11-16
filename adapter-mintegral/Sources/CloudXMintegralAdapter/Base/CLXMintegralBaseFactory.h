#import <Foundation/Foundation.h>

@class CLXLogger;

NS_ASSUME_NONNULL_BEGIN

@interface CLXMintegralBaseFactory : NSObject

@property (nonatomic, strong, readonly) CLXLogger *logger;

- (long long)extractPlacementID:(NSString *)placementIDString;
- (BOOL)validateBidPayload:(nullable NSString *)bidPayload;

@end

NS_ASSUME_NONNULL_END

