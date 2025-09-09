//
//  InitMetrics.m
//  CloudXCore
//
//  Created by Bryan Boyko on 6/20/25.
//

#import <CloudXCore/CLXInitMetrics.h>

@interface CLXInitMetrics ()
@property (nonatomic, copy, readwrite) NSString *appKey;
@property (nonatomic, strong, readwrite) NSDate *startedAt;
@end

@implementation CLXInitMetrics

- (instancetype)initWithAppKey:(NSString *)appKey {
    self = [super init];
    if (self) {
        _appKey = [appKey copy];
        _startedAt = [NSDate date];
        _success = NO;
    }
    return self;
}

- (void)finishWithSessionId:(nullable NSString *)sessionId {
    self.endedAt = [NSDate date];
    if (sessionId) {
        self.success = YES;
    }
    self.sessionId = sessionId;
}

@end 