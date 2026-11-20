/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "CLXAppHarbrSDKBridge.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Production bridge over @c AppHarbrAdQuality.shared. This is the only class in
 * the module that imports the AppHarbr SDK; it is excluded from the unit-test
 * target so tests never require AppHarbr.
 */
@interface CLXAppHarbrSDKProductionBridge : NSObject <CLXAppHarbrSDKBridge>

@end

NS_ASSUME_NONNULL_END
