//
//  CLXPangleErrorHandler.h
//  CloudXPangleAdapter
//

#import <Foundation/Foundation.h>

#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 * Error handler for mapping Pangle SDK error codes to CloudX error codes.
 */
@interface CLXPangleErrorHandler : NSObject

/**
 * Maps a Pangle SDK error to a CloudX error
 * @param pangleError The Pangle SDK error
 * @param isShowError Whether the error occurred during show (vs load)
 * @return A CloudX error with the appropriate error code
 */
+ (CLXError *)toCloudXError:(NSError *)pangleError isShowError:(BOOL)isShowError;

@end

NS_ASSUME_NONNULL_END
