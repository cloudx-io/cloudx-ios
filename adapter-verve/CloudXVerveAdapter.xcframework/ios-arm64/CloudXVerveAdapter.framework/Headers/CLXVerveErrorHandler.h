/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXError;

@interface CLXVerveErrorHandler : NSObject

+ (CLXError *)toCloudXError:(nullable NSError *)verveError;

@end

NS_ASSUME_NONNULL_END
