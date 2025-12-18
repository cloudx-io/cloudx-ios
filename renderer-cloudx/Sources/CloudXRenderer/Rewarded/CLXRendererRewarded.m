//
//  CLXRendererRewarded.m
//  CloudXRenderer
//
//  Renderer rewarded ad implementation
//

#import "CLXRendererRewarded.h"
#import "CLXFullscreenStaticContainerViewController.h"
#import "CLXRendererVersion.h"
#import <CloudXCore/CLXLogger.h>

@interface CLXRendererRewarded () <CLXFullscreenStaticContainerViewControllerDelegate>

@property (nonatomic, strong) NSString *adm;
@property (nonatomic, copy) NSString *bidID;
@property (nonatomic, strong) CLXFullscreenStaticContainerViewController *containerViewController;

@end

@implementation CLXRendererRewarded

@synthesize delegate;

- (instancetype)initWithAdm:(NSString *)adm
                      bidID:(NSString *)bidID
                   delegate:(id<CLXAdapterRewardedDelegate>)delegate {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CLXRendererRewarded"];
    [logger debug:[NSString stringWithFormat:@"[INIT] CLXRendererRewarded initialization - Markup: %lu chars, BidID: %@", (unsigned long)adm.length, bidID ?: @"nil"]];
    
    self = [super init];
    if (self) {
        self.adm = adm;
        self.bidID = bidID;
        self.delegate = delegate;
        
        [logger info:@"CLXRendererRewarded initialization completed successfully"];
    } else {
        [logger error:@"Super init failed"];
    }
    return self;
}

- (void)dealloc {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CLXRendererRewarded"];
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
    return CLXRendererVersion;
}

- (void)load {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CLXRendererRewarded"];
    [logger debug:@"[LOAD] CLXRendererRewarded load called"];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.containerViewController = [[CLXFullscreenStaticContainerViewController alloc] initWithDelegate:self adm:self.adm];
        [self.containerViewController loadHTML];
        [logger info:@"Container created and HTML load initiated"];
    });
}

- (void)showFromViewController:(UIViewController *)viewController {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CLXRendererRewarded"];
    [logger debug:@"[SHOW] CLXRendererRewarded showFromViewController called"];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.containerViewController) {
            [viewController presentViewController:self.containerViewController animated:YES completion:nil];
            [self didShow];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self impression];
            });
            [logger info:@"Ad presentation initiated successfully"];
        } else {
            [logger error:@"ContainerViewController is nil!"];
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