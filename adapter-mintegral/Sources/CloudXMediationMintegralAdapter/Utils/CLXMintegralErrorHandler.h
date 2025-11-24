#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXLogger;

@interface CLXMintegralErrorHandler : NSObject

+ (NSError *)handleNetworkError:(NSError *)networkError
                     withLogger:(CLXLogger *)logger
                        context:(NSString *)context
                    placementID:(nullable NSString *)placementID;

@end

NS_ASSUME_NONNULL_END

