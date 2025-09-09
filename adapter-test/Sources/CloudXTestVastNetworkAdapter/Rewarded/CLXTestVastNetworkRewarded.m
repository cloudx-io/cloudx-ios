//
//  CloudXTestVastNetworkRewarded.m
//  CloudXTestVastNetworkAdapter
//
//  Created by bkorda on 06.03.2024.
//

#import "CLXTestVastNetworkRewarded.h"
#import "CLXFullscreenStaticContainerViewController.h"
#import <CloudXCore/CLXLogger.h>

@interface CLXTestVastNetworkRewarded () <CLXFullscreenStaticContainerViewControllerDelegate>

@property (nonatomic, strong) NSString *adm;
@property (nonatomic, copy, readwrite) NSString *bidID;
@property (nonatomic, strong) CLXFullscreenStaticContainerViewController *containerViewController;

@end

@implementation CLXTestVastNetworkRewarded

@synthesize delegate;

- (instancetype)initWithAdm:(NSString *)adm
                      bidID:(NSString *)bidID
                   delegate:(id<CLXAdapterRewardedDelegate>)delegate {
    self = [super init];
    if (self) {
        self.adm = adm;
        self.bidID = bidID;
        self.delegate = delegate;
    }
    return self;
}

- (void)dealloc {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CloudXTestVastNetworkRewarded"];
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
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CloudXTestVastNetworkRewarded"];
    [logger debug:@"🔧 [CloudXTestVastNetworkRewarded] load called"];
    [logger debug:[NSString stringWithFormat:@"📊 [CloudXTestVastNetworkRewarded] - ADM: %@", self.adm]];
    [logger debug:[NSString stringWithFormat:@"📊 [CloudXTestVastNetworkRewarded] - Delegate: %@", self.delegate]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [logger debug:@"🔧 [CloudXTestVastNetworkRewarded] Creating containerViewController..."];
        self.containerViewController = [[CLXFullscreenStaticContainerViewController alloc] initWithDelegate:self adm:self.adm];
        
        [logger debug:[NSString stringWithFormat:@"📊 [CloudXTestVastNetworkRewarded] ContainerViewController created: %@", self.containerViewController]];
        [logger debug:@"📊 [CloudXTestVastNetworkRewarded] Calling loadHTML..."];
        [self.containerViewController loadHTML];
        [logger info:@"✅ [CloudXTestVastNetworkRewarded] loadHTML called"];
    });
}

- (void)showFromViewController:(UIViewController *)viewController {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CloudXTestVastNetworkRewarded"];
    [logger debug:@"🔧 [CloudXTestVastNetworkRewarded] showFromViewController called"];
    [logger debug:[NSString stringWithFormat:@"📊 [CloudXTestVastNetworkRewarded] - ViewController: %@", viewController]];
    [logger debug:[NSString stringWithFormat:@"📊 [CloudXTestVastNetworkRewarded] - ContainerViewController: %@", self.containerViewController]];
    [logger debug:[NSString stringWithFormat:@"📊 [CloudXTestVastNetworkRewarded] - isReady: %d", self.isReady]];
    [logger debug:[NSString stringWithFormat:@"📊 [CloudXTestVastNetworkRewarded] - Delegate: %@", self.delegate]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.containerViewController) {
            [logger info:@"✅ [CloudXTestVastNetworkRewarded] ContainerViewController exists, presenting..."];
            [viewController presentViewController:self.containerViewController animated:YES completion:^{
                [logger info:@"✅ [CloudXTestVastNetworkRewarded] Present completion called"];
            }];
            [self didShow];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [logger debug:@"🔧 [CloudXTestVastNetworkRewarded] Calling impression after 1 second delay"];
                [self impression];
            });
        } else {
            [logger error:@"❌ [CloudXTestVastNetworkRewarded] ContainerViewController is nil!"];
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