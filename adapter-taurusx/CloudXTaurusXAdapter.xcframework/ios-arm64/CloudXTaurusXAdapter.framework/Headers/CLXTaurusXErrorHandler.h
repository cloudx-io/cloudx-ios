#import <Foundation/Foundation.h>

#if __has_include(<CloudXCore/CLXError.h>)
#import <CloudXCore/CLXError.h>
#else
#import "CLXError.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface CLXTaurusXErrorHandler : NSObject

+ (CLXError *)toCloudXError:(nullable NSError *)sdkError;
+ (CLXError *)errorWithCode:(CLXErrorCode)code message:(nullable NSString *)message;

@end

NS_ASSUME_NONNULL_END
