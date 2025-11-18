/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import "CLXAdapterBanner.h"

/**
 * Default implementation for optional protocol methods.
 * This ensures the method is always available, even in framework builds.
 */
@implementation NSObject (CLXAdapterBannerDefaults)

- (BOOL)isFlexibleSize {
    // Default implementation: banners are fixed-size unless overridden
    return NO;
}

@end

