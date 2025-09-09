//
//  CloudXTestVastNetworkInterstitial.m
//  CloudXTestVastNetworkAdapter
//
//  Created by bkorda on 06.03.2024.
//

#import "CLXTestVastNetworkInterstitial.h"
#import "CLXFullscreenStaticContainerViewController.h"
#import <CloudXCore/CLXLogger.h>

@interface CLXTestVastNetworkInterstitial () <CLXFullscreenStaticContainerViewControllerDelegate>

@property (nonatomic, strong) NSString *adm;
@property (nonatomic, copy, readwrite) NSString *bidID;
@property (nonatomic, strong) CLXFullscreenStaticContainerViewController *containerViewController;

@end

@implementation CLXTestVastNetworkInterstitial

@synthesize delegate;

- (instancetype)initWithAdm:(NSString *)adm
                      bidID:(NSString *)bidID
                   delegate:(id<CLXAdapterInterstitialDelegate>)delegate {
    self = [super init];
    if (self) {
        self.adm = adm;
        self.bidID = bidID;
        self.delegate = delegate;
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
    dispatch_async(dispatch_get_main_queue(), ^{
        self.containerViewController = [[CLXFullscreenStaticContainerViewController alloc] initWithDelegate:self adm:self.adm];
        [self.containerViewController loadHTML];
    });
}

- (void)showFromViewController:(UIViewController *)viewController {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"🔴🔴🔴 [CLXTestVastNetworkInterstitial] showFromViewController called");
        printf("🔴🔴🔴 [CLXTestVastNetworkInterstitial] showFromViewController called\n");
        
        if (self.containerViewController) {
            NSLog(@"🔴🔴🔴 [CLXTestVastNetworkInterstitial] containerViewController is valid, creating logger");
            printf("🔴🔴🔴 [CLXTestVastNetworkInterstitial] containerViewController is valid, creating logger\n");
            
            CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CLXTestVastNetworkInterstitial"];
            NSLog(@"🔴🔴🔴 [CLXTestVastNetworkInterstitial] logger created, calling info method");
            printf("🔴🔴🔴 [CLXTestVastNetworkInterstitial] logger created, calling info method\n");
            
            [logger info:@"✅ [CLXTestVastNetworkInterstitial] Showing ad: containerViewController is valid."];
            NSLog(@"🔴🔴🔴 [CLXTestVastNetworkInterstitial] info method called");
            printf("🔴🔴🔴 [CLXTestVastNetworkInterstitial] info method called\n");
            
            [viewController presentViewController:self.containerViewController animated:YES completion:nil];
            [self didShow];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self impression];
            });
        } else {
            NSLog(@"🔴🔴🔴 [CLXTestVastNetworkInterstitial] containerViewController is NIL, creating logger");
            printf("🔴🔴🔴 [CLXTestVastNetworkInterstitial] containerViewController is NIL, creating logger\n");
            
            CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CLXTestVastNetworkInterstitial"];
            NSLog(@"🔴🔴🔴 [CLXTestVastNetworkInterstitial] logger created, calling error method");
            printf("🔴🔴🔴 [CLXTestVastNetworkInterstitial] logger created, calling error method\n");
            
            [logger error:@"❌ [CLXTestVastNetworkInterstitial] FAILED to show ad: containerViewController is NIL."];
            NSLog(@"🔴🔴🔴 [CLXTestVastNetworkInterstitial] error method called");
            printf("🔴🔴🔴 [CLXTestVastNetworkInterstitial] error method called\n");
            
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