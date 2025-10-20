//
//  CLXSessionMetrics.m
//  CloudXCore
//
//  Created by CloudX iOS Team
//  Copyright (c) 2024 CloudX. All rights reserved.
//

#import <CloudXCore/CLXSessionMetrics.h>

@implementation CLXSessionMetrics

#pragma mark - Initialization

- (instancetype)initWithDepth:(float)depth
                  bannerDepth:(float)bannerDepth
         mediumRectangleDepth:(float)mediumRectangleDepth
                    fullDepth:(float)fullDepth
                  nativeDepth:(float)nativeDepth
                rewardedDepth:(float)rewardedDepth
              durationSeconds:(float)durationSeconds {
    self = [super init];
    if (self) {
        _depth = depth;
        _bannerDepth = bannerDepth;
        _mediumRectangleDepth = mediumRectangleDepth;
        _fullDepth = fullDepth;
        _nativeDepth = nativeDepth;
        _rewardedDepth = rewardedDepth;
        _durationSeconds = durationSeconds;
    }
    return self;
}

+ (instancetype)zeroMetrics {
    return [[self alloc] initWithDepth:0.0f
                           bannerDepth:0.0f
                  mediumRectangleDepth:0.0f
                             fullDepth:0.0f
                           nativeDepth:0.0f
                         rewardedDepth:0.0f
                       durationSeconds:0.0f];
}

#pragma mark - NSObject

- (NSString *)description {
    return [NSString stringWithFormat:@"<CLXSessionMetrics: depth=%.0f, banner=%.0f, mrec=%.0f, full=%.0f, native=%.0f, rewarded=%.0f, duration=%.1fs>",
            self.depth,
            self.bannerDepth,
            self.mediumRectangleDepth,
            self.fullDepth,
            self.nativeDepth,
            self.rewardedDepth,
            self.durationSeconds];
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    
    if (![object isKindOfClass:[CLXSessionMetrics class]]) {
        return NO;
    }
    
    CLXSessionMetrics *other = (CLXSessionMetrics *)object;
    return self.depth == other.depth &&
           self.bannerDepth == other.bannerDepth &&
           self.mediumRectangleDepth == other.mediumRectangleDepth &&
           self.fullDepth == other.fullDepth &&
           self.nativeDepth == other.nativeDepth &&
           self.rewardedDepth == other.rewardedDepth &&
           self.durationSeconds == other.durationSeconds;
}

- (NSUInteger)hash {
    NSUInteger hash = 17;
    hash = hash * 31 + (NSUInteger)self.depth;
    hash = hash * 31 + (NSUInteger)self.bannerDepth;
    hash = hash * 31 + (NSUInteger)self.mediumRectangleDepth;
    hash = hash * 31 + (NSUInteger)self.fullDepth;
    hash = hash * 31 + (NSUInteger)self.nativeDepth;
    hash = hash * 31 + (NSUInteger)self.rewardedDepth;
    hash = hash * 31 + (NSUInteger)self.durationSeconds;
    return hash;
}

@end

