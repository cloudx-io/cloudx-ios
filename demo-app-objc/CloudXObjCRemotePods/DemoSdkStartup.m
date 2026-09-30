#import "DemoSdkStartup.h"
#import <CloudXCore/CloudXCore.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import "AppTrackingPermission.h"
#import "CLXDemoConfigManager.h"
#import "DemoAppLogger.h"

static NSTimeInterval const kInitializationTimeout = 15;

@interface DemoSdkStartup ()
@property (nonatomic, copy) void (^onStatus)(NSString *status);
@property (nonatomic, copy) void (^onCloudXSettled)(BOOL cloudXAvailable);
@property (nonatomic, copy) NSString *cloudXStatus;
@property (nonatomic, copy) NSString *adMobStatus;
@property (nonatomic, copy, nullable) dispatch_block_t timeoutWork;
@property (nonatomic) BOOL settled;
@end

@implementation DemoSdkStartup

- (instancetype)initWithStatusHandler:(void (^)(NSString *status))onStatus
                 cloudXSettledHandler:(void (^)(BOOL cloudXAvailable))onCloudXSettled {
    self = [super init];
    if (self) {
        _onStatus = [onStatus copy];
        _onCloudXSettled = [onCloudXSettled copy];
        _cloudXStatus = @"CloudX: Initializing";
        _adMobStatus = @"AdMob: Initializing";
    }
    return self;
}

- (void)dealloc {
    if (_timeoutWork) dispatch_block_cancel(_timeoutWork);
}

- (void)start {
    [self publishStatus];
    [self startAdMob];
    __weak typeof(self) weakSelf = self;
    [AppTrackingPermission requestWithCompletion:^{
        [weakSelf initializeCloudX];
    }];
}

/*
 * Loads do not wait for this. Google asks apps to wait for the completion handler only when they
 * use AdMob mediation, which these flows do not.
 */
- (void)startAdMob {
    __weak typeof(self) weakSelf = self;
    [[GADMobileAds sharedInstance] startWithCompletionHandler:^(GADInitializationStatus *status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;
            strongSelf.adMobStatus = @"AdMob: Ready";
            [strongSelf publishStatus];
        });
    }];
}

- (void)initializeCloudX {
    CLXDemoConfig *config = [CLXDemoConfigManager sharedManager].currentConfig;
    if (config.hashedUserId.length > 0) {
        [[CloudXCore shared] setHashedUserID:config.hashedUserId];
    }
    [[DemoAppLogger sharedInstance] logMessage:@"Initializing CloudX SDK"];

    __weak typeof(self) weakSelf = self;
    dispatch_block_t timeoutWork = dispatch_block_create(0, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        strongSelf.cloudXStatus = @"CloudX: No response, AdMob only";
        [strongSelf publishStatus];
        [strongSelf settleWithCloudXAvailable:NO];
    });
    self.timeoutWork = timeoutWork;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kInitializationTimeout * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), timeoutWork);

    CLXInitializationConfiguration *initConfig = [CLXInitializationConfiguration configurationWithAppKey:config.appKey];
    [[CloudXCore shared] initializeWithConfiguration:initConfig
                                          completion:^(CLXSdkConfiguration * _Nullable sdkConfig, CLXError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;
            if (strongSelf.timeoutWork) {
                dispatch_block_cancel(strongSelf.timeoutWork);
                strongSelf.timeoutWork = nil;
            }
            if (sdkConfig) {
                [[DemoAppLogger sharedInstance] logMessage:@"CloudX SDK initialized"];
                strongSelf.cloudXStatus = strongSelf.settled
                    ? @"CloudX: Initialized late, AdMob only"
                    : @"CloudX: Initialized";
                [strongSelf publishStatus];
                [strongSelf settleWithCloudXAvailable:YES];
            } else {
                NSString *message = error.localizedDescription ?: @"Unknown error";
                [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"CloudX SDK initialization failed: %@", message]];
                strongSelf.cloudXStatus = [NSString stringWithFormat:@"CloudX: Failed (%@)", message];
                [strongSelf publishStatus];
                [strongSelf settleWithCloudXAvailable:NO];
            }
        });
    }];
}

- (void)settleWithCloudXAvailable:(BOOL)cloudXAvailable {
    if (self.settled) return;
    self.settled = YES;
    self.onCloudXSettled(cloudXAvailable);
}

- (void)publishStatus {
    self.onStatus([NSString stringWithFormat:@"%@ | %@", self.cloudXStatus, self.adMobStatus]);
}

@end
