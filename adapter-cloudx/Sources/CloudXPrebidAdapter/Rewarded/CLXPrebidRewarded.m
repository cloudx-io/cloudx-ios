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
    [logger info:[NSString stringWithFormat:@"🚀 [INIT] CLXPrebidRewarded initialization - Markup: %lu chars, BidID: %@", (unsigned long)adm.length, bidID ?: @"nil"]];
    
    self = [super init];
    if (self) {
        self.adm = adm;
        self.bidID = bidID;
        self.delegate = delegate;
        
        [logger info:@"✅ [INIT] CLXPrebidRewarded initialization completed successfully"];
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
    [logger info:@"🚀 [LOAD] CLXPrebidRewarded load called"];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.containerViewController = [[CLXFullscreenStaticContainerViewController alloc] initWithDelegate:self adm:self.adm];
        [self.containerViewController loadHTML];
        [logger info:@"✅ [LOAD] Container created and HTML load initiated"];
    });
}

- (void)showFromViewController:(UIViewController *)viewController {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CLXPrebidRewarded"];
    [logger info:@"🚀 [SHOW] CLXPrebidRewarded showFromViewController called"];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.containerViewController) {
            [viewController presentViewController:self.containerViewController animated:YES completion:nil];
            [self didShow];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self impression];
            });
            [logger info:@"✅ [SHOW] Ad presentation initiated successfully"];
        } else {
            [logger error:@"❌ [SHOW] ContainerViewController is nil!"];
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