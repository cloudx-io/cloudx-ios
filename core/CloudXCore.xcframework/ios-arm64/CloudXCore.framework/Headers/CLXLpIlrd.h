/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXIlrdProvider.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * ILRD provider for Unity LevelPlay.
 *
 * Uses runtime selector lookup so CloudXCore can capture LevelPlay ILRD when the
 * host app integrates LevelPlay, without taking a hard link dependency on it.
 * Mirrors [CLXAlIlrd] and Android's LevelPlayIlrd.
 */
@interface CLXLpIlrd : NSObject <CLXIlrdProvider>

- (instancetype)init;

/**
 * Test-only initializer for injecting a fake provider class and retry cadence.
 */
- (instancetype)initWithClassName:(NSString *)className
                      retryDelays:(NSArray<NSNumber *> *)retryDelays NS_DESIGNATED_INITIALIZER;

/**
 * Normalizes raw LevelPlay ad format labels to CX canonical ad type names.
 * Exposed for testing.
 */
- (nullable NSString *)normalizeAdFormat:(NSString *)raw;

@end

NS_ASSUME_NONNULL_END
