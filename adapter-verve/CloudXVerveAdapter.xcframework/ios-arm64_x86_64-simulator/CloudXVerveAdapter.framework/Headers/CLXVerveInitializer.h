/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdNetworkInitializer.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXVerveInitializer : CLXAdNetworkInitializer

+ (NSString *)sdkVersion;
+ (nullable NSString *)appToken;

@end

NS_ASSUME_NONNULL_END
