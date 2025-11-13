//
//  CLXRendererInterstitial.m
//  CloudXRenderer
//
//  Renderer interstitial ad implementation
//

#import "CLXRendererInterstitial.h"
#import "CLXFullscreenStaticContainerViewController.h"
#import <CloudXCore/CLXLogger.h>

@interface CLXRendererInterstitial () <CLXFullscreenStaticContainerViewControllerDelegate>

@property (nonatomic, strong) NSString *adm;
@property (nonatomic, copy) NSString *bidID;
@property (nonatomic, strong) CLXFullscreenStaticContainerViewController *containerViewController;

@end

@implementation CLXRendererInterstitial

@synthesize delegate;

- (instancetype)initWithAdm:(NSString *)adm
                      bidID:(NSString *)bidID
                   delegate:(id<CLXAdapterInterstitialDelegate>)delegate {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CLXRendererInterstitial"];
    [logger debug:[NSString stringWithFormat:@"[INIT] CLXRendererInterstitial initialization - Markup: %lu chars, BidID: %@", (unsigned long)adm.length, bidID ?: @"nil"]];
    
    self = [super init];
    if (self) {
        self.adm = adm;
        self.bidID = bidID;
        self.delegate = delegate;
        
        [logger info:@"CLXRendererInterstitial initialization completed successfully"];
    } else {
        [logger error:@"Super init failed"];
    }
    return self;
}

- (void)dealloc {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CLXTestVastNetworkInterstitial"];
    [logger debug:[NSString stringWithFormat:@"AAA deinit %@", self]];
}

#pragma mark - CLXAdapterInterstitial

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
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CLXRendererInterstitial"];
    [logger debug:@"[LOAD] CLXRendererInterstitial load() method called"];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.containerViewController = [[CLXFullscreenStaticContainerViewController alloc] initWithDelegate:self adm:self.adm];
        [self.containerViewController loadHTML];
        [logger info:@"Container created and HTML load initiated"];
    });
}

- (void)showFromViewController:(UIViewController *)viewController {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CLXRendererInterstitial"];
    [logger debug:@"[SHOW] CLXRendererInterstitial show() method called"];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.containerViewController) {
            [viewController presentViewController:self.containerViewController animated:YES completion:nil];
            [self didShow];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self impression];
            });
            [logger info:@"Ad presentation initiated successfully"];
        } else {
            [logger error:@"FAILED to show ad: containerViewController is NIL"];
            NSError *error = [NSError errorWithDomain:@"CloudXRenderer" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Ad failed to show: containerViewController was nil."}];
            [self didFailToShowWithError:error];
        }
    });
}

- (void)destroy {
    [self.containerViewController destroy];
}

#pragma mark - CloudXFullscreenStaticContainerViewControllerDelegate

- (void)didShow {
    if ([self.delegate respondsToSelector:@selector(didShowWithInterstitial:)]) {
        [self.delegate didShowWithInterstitial:self];
    }
}

- (void)impression {
    if ([self.delegate respondsToSelector:@selector(impressionWithInterstitial:)]) {
        [self.delegate impressionWithInterstitial:self];
    }
}

- (void)didLoad {
    if ([self.delegate respondsToSelector:@selector(didLoadWithInterstitial:)]) {
        [self.delegate didLoadWithInterstitial:self];
    }
}

- (void)didFailToShowWithError:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(didFailToShowWithInterstitial:error:)]) {
        [self.delegate didFailToShowWithInterstitial:self error:error];
    }
}

- (void)didClickFullAdd {
    if ([self.delegate respondsToSelector:@selector(clickWithInterstitial:)]) {
        [self.delegate clickWithInterstitial:self];
    }
}

- (void)closeFullScreenAd {
    if ([self.delegate respondsToSelector:@selector(didCloseWithInterstitial:)]) {
        [self.delegate didCloseWithInterstitial:self];
    }
}

@end 