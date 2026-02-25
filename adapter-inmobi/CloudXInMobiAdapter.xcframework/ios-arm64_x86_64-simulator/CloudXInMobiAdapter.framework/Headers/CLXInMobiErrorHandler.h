//
//  CLXInMobiErrorHandler.h
//  CloudXInMobiAdapter
//

#import <Foundation/Foundation.h>

@class CLXError;

NS_ASSUME_NONNULL_BEGIN

@interface CLXInMobiErrorHandler : NSObject

+ (CLXError *)toCloudXError:(NSError *)inMobiError;

@end

NS_ASSUME_NONNULL_END
