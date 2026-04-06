/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXMetaNativeFactory : NSObject <CLXAdapterNativeFactory>

+ (instancetype)createInstance;

@end

NS_ASSUME_NONNULL_END
