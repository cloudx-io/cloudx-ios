//
//  CLXMockInitService.m
//  CloudXCoreTests
//
//  Mock implementation of CLXInitService for unit testing
//

#import "CLXMockInitService.h"

@implementation CLXMockInitService

- (instancetype)initWithSuccess:(BOOL)shouldSucceed {
    self = [super init];
    if (self) {
        _shouldSucceed = shouldSucceed;
        _mockDelay = 0.1; // Fast for unit tests
        
        if (shouldSucceed) {
            // Create a minimal mock config
            _mockConfig = [[CLXSDKConfigResponse alloc] init];
            _mockConfig.accountID = @"test-account-123";
        } else {
            _mockError = [NSError errorWithDomain:@"MockInitService" 
                                             code:-1 
                                         userInfo:@{NSLocalizedDescriptionKey: @"Mock initialization failed"}];
        }
    }
    return self;
}

- (instancetype)initWithError:(NSError *)error {
    self = [super init];
    if (self) {
        _shouldSucceed = NO;
        _mockError = error;
        _mockDelay = 0.1;
    }
    return self;
}

- (instancetype)initWithConfig:(CLXSDKConfigResponse *)config {
    self = [super init];
    if (self) {
        _shouldSucceed = YES;
        _mockConfig = config;
        _mockDelay = 0.1;
    }
    return self;
}

#pragma mark - CLXInitService Protocol

- (void)initSDKWithAppKey:(NSString *)appKey completion:(void (^)(CLXSDKConfigResponse * _Nullable, NSError * _Nullable))completion {
    NSLog(@"🧪 [CLXMockInitService] Mock initSDKWithAppKey called - NO NETWORK REQUEST!");
    
    // Simulate async behavior but keep it fast for unit tests
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_mockDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.shouldSucceed) {
            NSLog(@"🧪 [CLXMockInitService] Mock returning success - NO NETWORK REQUEST!");
            completion(self.mockConfig, nil);
        } else {
            NSLog(@"🧪 [CLXMockInitService] Mock returning error - NO NETWORK REQUEST!");
            completion(nil, self.mockError);
        }
    });
}

@end
