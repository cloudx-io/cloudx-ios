//
//  CLXPrebidRewarded.m
//  CloudXPrebidAdapter
//
//  Prebid 3.0 rewarded ad implementation
//

#import "CLXPrebidRewarded.h"
#import "CLXFullscreenStaticContainerViewController.h"
#import <CloudXCore/CLXLogger.h>

@interface CLXPrebidRewarded () <CLXFullscreenStaticContainerViewControllerDelegate>

@property (nonatomic, strong) NSString *adm;
@property (nonatomic, copy) NSString *bidID;
@property (nonatomic, strong) CLXFullscreenStaticContainerViewController *containerViewController;

@end

@implementation CLXPrebidRewarded

@synthesize delegate;

- (instancetype)initWithAdm:(NSString *)adm
                      bidID:(NSString *)bidID
                   delegate:(id<CLXAdapterRewardedDelegate>)delegate {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CLXPrebidRewarded"];
    [logger info:@"🚀 [INIT] CLXPrebidRewarded initialization started"];
    [logger debug:[NSString stringWithFormat:@"📊 [INIT] Ad markup length: %lu characters", (unsigned long)adm.length]];
    [logger debug:[NSString stringWithFormat:@"📊 [INIT] Bid ID: %@", bidID ?: @"nil"]];
    [logger debug:[NSString stringWithFormat:@"📊 [INIT] Delegate: %@", delegate ? @"Present" : @"nil"]];
    
    self = [super init];
    if (self) {
        [logger info:@"✅ [INIT] Super init successful"];
        
        self.adm = adm;
        self.bidID = bidID;
        self.delegate = delegate;
        
        [logger debug:@"📊 [INIT] Properties configured:"];
        [logger debug:[NSString stringWithFormat:@"  📍 Ad markup length: %lu", (unsigned long)self.adm.length]];
        [logger debug:[NSString stringWithFormat:@"  📍 Bid ID: %@", self.bidID ?: @"nil"]];
        [logger debug:[NSString stringWithFormat:@"  📍 Delegate: %@", self.delegate ? @"Set" : @"nil"]];
        
        [logger info:@"🎯 [INIT] CLXPrebidRewarded initialization completed successfully"];
    } else {
        [logger error:@"❌ [INIT] Super init failed"];
    }
    return self;
}

- (void)dealloc {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CLXPrebidRewarded"];
    [logger debug:[NSString stringWithFormat:@"AAA deinit %@", self]];
}

#pragma mark - CLXAdapterRewarded

- (NSString *)network {
    return @"TestVastNetwork";
}

- (BOOL)isReady {
    return self.containerViewController != nil;
}

- (NSString *)sdkVersion {
    return @"1.0.0";
}

- (void)load {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CLXPrebidRewarded"];
    [logger debug:@"🔧 [CLXPrebidRewarded] load called"];
    [logger debug:[NSString stringWithFormat:@"📊 [CLXPrebidRewarded] - ADM: %@", self.adm]];
    [logger debug:[NSString stringWithFormat:@"📊 [CLXPrebidRewarded] - Delegate: %@", self.delegate]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [logger debug:@"🔧 [CLXPrebidRewarded] Creating containerViewController..."];
        self.containerViewController = [[CLXFullscreenStaticContainerViewController alloc] initWithDelegate:self adm:self.adm];
        
        [logger debug:[NSString stringWithFormat:@"📊 [CLXPrebidRewarded] ContainerViewController created: %@", self.containerViewController]];
        [logger debug:@"📊 [CLXPrebidRewarded] Calling loadHTML..."];
        [self.containerViewController loadHTML];
        [logger info:@"✅ [CLXPrebidRewarded] loadHTML called"];
    });
}

- (void)showFromViewController:(UIViewController *)viewController {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CLXPrebidRewarded"];
    [logger debug:@"🔧 [CLXPrebidRewarded] showFromViewController called"];
    [logger debug:[NSString stringWithFormat:@"📊 [CLXPrebidRewarded] - ViewController: %@", viewController]];
    [logger debug:[NSString stringWithFormat:@"📊 [CLXPrebidRewarded] - ContainerViewController: %@", self.containerViewController]];
    [logger debug:[NSString stringWithFormat:@"📊 [CLXPrebidRewarded] - isReady: %d", self.isReady]];
    [logger debug:[NSString stringWithFormat:@"📊 [CLXPrebidRewarded] - Delegate: %@", self.delegate]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.containerViewController) {
            [logger info:@"✅ [CLXPrebidRewarded] ContainerViewController exists, presenting..."];
            [viewController presentViewController:self.containerViewController animated:YES completion:^{
                [logger info:@"✅ [CLXPrebidRewarded] Present completion called"];
            }];
            [self didShow];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [logger debug:@"🔧 [CLXPrebidRewarded] Calling impression after 1 second delay"];
                [self impression];
            });
        } else {
            [logger error:@"❌ [CLXPrebidRewarded] ContainerViewController is nil!"];
            NSError *error = [NSError errorWithDomain:@"CloudXTestVastNetworkAdapter" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Ad failed to show: containerViewController was nil."}];
            [self didFailToShowWithError:error];
        }
    });
}

- (void)destroy {
    [self.containerViewController destroy];
}

#pragma mark - CloudXFullscreenStaticContainerViewControllerDelegate

- (void)didShow {
    if ([self.delegate respondsToSelector:@selector(didShowWithRewarded:)]) {
        [self.delegate didShowWithRewarded:self];
    }
}

- (void)impression {
    if ([self.delegate respondsToSelector:@selector(impressionWithRewarded:)]) {
        [self.delegate impressionWithRewarded:self];
    }
}

- (void)didLoad {
    if ([self.delegate respondsToSelector:@selector(didLoadWithRewarded:)]) {
        [self.delegate didLoadWithRewarded:self];
    }
}

- (void)didFailToShowWithError:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(didFailToShowWithRewarded:error:)]) {
        [self.delegate didFailToShowWithRewarded:self error:error];
    }
}

- (void)didClickFullAdd {
    if ([self.delegate respondsToSelector:@selector(clickWithRewarded:)]) {
        [self.delegate clickWithRewarded:self];
    }
}

- (void)closeFullScreenAd {
    if ([self.delegate respondsToSelector:@selector(userRewardWithRewarded:)]) {
        [self.delegate userRewardWithRewarded:self];
    }
    if ([self.delegate respondsToSelector:@selector(didCloseWithRewarded:)]) {
        [self.delegate didCloseWithRewarded:self];
    }
}

@end 