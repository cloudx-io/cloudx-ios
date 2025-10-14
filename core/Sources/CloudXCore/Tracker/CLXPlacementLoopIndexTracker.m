//
//  CLXPlacementLoopIndexTracker.m
//  CloudXCore
//
//  Created by CloudX on 2025-01-13.
//

#import "CLXPlacementLoopIndexTracker.h"

@interface CLXPlacementLoopIndexTracker ()
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *loopIndexMap;
@property (nonatomic, strong) dispatch_queue_t queue;
@end

@implementation CLXPlacementLoopIndexTracker

+ (instancetype)shared {
    static CLXPlacementLoopIndexTracker *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _loopIndexMap = [NSMutableDictionary dictionary];
        _queue = dispatch_queue_create("io.cloudx.placement-loop-index", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (NSInteger)getCountForPlacement:(NSString *)placementName {
    if (!placementName || placementName.length == 0) {
        return 0;
    }
    
    __block NSInteger count = 0;
    dispatch_sync(self.queue, ^{
        NSNumber *counter = self.loopIndexMap[placementName];
        if (counter) {
            // Match Android: return counter - 1 (the current index before next increment)
            count = [counter integerValue] - 1;
        } else {
            // First time for this placement - initialize to 0
            self.loopIndexMap[placementName] = @0;
            count = 0;
        }
    });
    return count;
}

- (NSInteger)getAndIncrementForPlacement:(NSString *)placementName {
    if (!placementName || placementName.length == 0) {
        return 0;
    }
    
    __block NSInteger current = 0;
    dispatch_sync(self.queue, ^{
        NSNumber *counter = self.loopIndexMap[placementName];
        current = counter ? [counter integerValue] : 0;
        
        // Increment for next time
        self.loopIndexMap[placementName] = @(current + 1);
    });
    return current;
}

- (void)resetForPlacement:(NSString *)placementName {
    if (!placementName || placementName.length == 0) {
        return;
    }
    
    dispatch_sync(self.queue, ^{
        [self.loopIndexMap removeObjectForKey:placementName];
    });
}

- (void)resetAll {
    dispatch_sync(self.queue, ^{
        [self.loopIndexMap removeAllObjects];
    });
}

@end

