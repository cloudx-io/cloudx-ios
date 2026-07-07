/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdapterInitializationParams.h>
#import <CloudXCore/CLXExport.h>

NS_ASSUME_NONNULL_BEGIN

/// Abstract base class for adapter initializers.
/// Subclass MUST override @c -initializeWithParams:.
CLX_PUBLIC_ADAPTER
@interface CLXAdapterInitializer : NSObject

+ (instancetype)createInstance;

/// CloudX SDK calls this method to initialize the adapter SDK.
- (void)initializeWithParams:(CLXAdapterInitializationParams *)params;

@end

NS_ASSUME_NONNULL_END
