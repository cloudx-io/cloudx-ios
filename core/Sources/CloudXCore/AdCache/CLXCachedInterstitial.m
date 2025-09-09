/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CachedInterstitial.m
 * @brief Cached interstitial wrapper implementation
 */

#import <CloudXCore/CLXCachedInterstitial.h>
#import <CloudXCore/CLXAdapterInterstitial.h>
#import <CloudXCore/CLXDestroyable.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXCachedInterstitial () <CLXAdapterInterstitialDelegate>

@property (nonatomic, strong, nullable) NSTimer *loadingTimer;
@property (nonatomic, copy, nullable) void (^loadCompletion)(NSError * _Nullable error);

@end

static CLXLogger *logger;

__attribute__((constructor))
static void initializeLogger() {
    logger = [[CLXLogger alloc] initWithCategory:@"CachedInterstitial.m"];
}

@implementation CLXCachedInterstitial

@synthesize bidResponse = _bidResponse;

- (instancetype)initWithInterstitial:(id<CLXAdapterInterstitial>)interstitial
                            delegate:(id<CLXAdapterInterstitialDelegate>)delegate {
    self = [super init];
    if (self) {
        _interstitial = interstitial;
        _delegate = delegate;
        _impressionID = @"";
        
        // Set self as the delegate for the wrapped interstitial
        _interstitial.delegate = self;
    }
    return self;
}

- (void)dealloc {
    [logger debug:@"🔧 [CachedInterstitial] dealloc called"];
    [self destroy];
}

#pragma mark - CacheableAd

- (NSString *)network {
    return self.interstitial.network;
}

- (void)loadWithTimeout:(NSTimeInterval)timeout
             completion:(void (^)(NSError * _Nullable error))completion {
    [logger debug:[NSString stringWithFormat:@"🔧 [CachedInterstitial] loadWithTimeout: %f called", timeout]];
    
    self.loadCompletion = completion;
    
    // Set up loading timer
    self.loadingTimer = [NSTimer scheduledTimerWithTimeInterval:timeout
                                                         repeats:NO
                                                           block:^(NSTimer * _Nonnull timer) {
        [logger debug:@"🔧 [CachedInterstitial] Loading timer fired"];
        if (self.loadCompletion) {
            NSError *error = [CLXError errorWithCode:CLXErrorCodeLoadTimeout 
                                                 description:@"Loading timeout"];
            self.loadCompletion(error);
            self.loadCompletion = nil;
        }
        [self.loadingTimer invalidate];
        self.loadingTimer = nil;
    }];
    
    // Start loading the interstitial
    [self.interstitial load];
}

- (void)showFromViewController:(UIViewController *)viewController {
    [logger debug:@"🔧 [CachedInterstitial] showFromViewController called"];
    [self.interstitial showFromViewController:viewController];
}

- (void)destroy {
    [logger debug:@"🔧 [CachedInterstitial] destroy called"];
    
    // Invalidate timer
    [self.loadingTimer invalidate];
    self.loadingTimer = nil;
    
    // Clear completion block
    self.loadCompletion = nil;
    
    // Destroy the wrapped interstitial
    if ([self.interstitial respondsToSelector:@selector(destroy)]) {
        [(id<CLXDestroyable>)self.interstitial destroy];
    }
}

#pragma mark - CloudXAdapterInterstitialDelegate

- (void)didLoadWithInterstitial:(id<CLXAdapterInterstitial>)interstitial {
    [logger debug:@"🔧 [CachedInterstitial] didLoadWithInterstitial called"];
    
    // Invalidate timer
    [self.loadingTimer invalidate];
    self.loadingTimer = nil;
    
    // Call completion with success
    if (self.loadCompletion) {
        self.loadCompletion(nil);
        self.loadCompletion = nil;
    }
    
    // Forward to delegate
    if ([self.delegate respondsToSelector:@selector(didLoadWithInterstitial:)]) {
        [self.delegate didLoadWithInterstitial:interstitial];
    }
}

- (void)didFailToLoadWithInterstitial:(id<CLXAdapterInterstitial>)interstitial error:(NSError *)error {
    [logger error:[NSString stringWithFormat:@"🔧 [CachedInterstitial] didFailToLoadWithInterstitial called with error: %@", error]];
    
    // Invalidate timer
    [self.loadingTimer invalidate];
    self.loadingTimer = nil;
    
    // Call completion with error
    if (self.loadCompletion) {
        self.loadCompletion(error);
        self.loadCompletion = nil;
    }
    
    // Forward to delegate
    if ([self.delegate respondsToSelector:@selector(didFailToLoadWithInterstitial:error:)]) {
        [self.delegate didFailToLoadWithInterstitial:interstitial error:error];
    }
}

- (void)didShowWithInterstitial:(id<CLXAdapterInterstitial>)interstitial {
    [logger debug:@"🔧 [CachedInterstitial] didShowWithInterstitial called"];
    
    // Forward to delegate
    if ([self.delegate respondsToSelector:@selector(didShowWithInterstitial:)]) {
        [self.delegate didShowWithInterstitial:interstitial];
    }
}

- (void)impressionWithInterstitial:(id<CLXAdapterInterstitial>)interstitial {
    [logger debug:@"🔧 [CachedInterstitial] impressionWithInterstitial called"];
    
    // Forward to delegate
    if ([self.delegate respondsToSelector:@selector(impressionWithInterstitial:)]) {
        [self.delegate impressionWithInterstitial:interstitial];
    }
}

- (void)didCloseWithInterstitial:(id<CLXAdapterInterstitial>)interstitial {
    [logger debug:@"🔧 [CachedInterstitial] didCloseWithInterstitial called"];
    
    // Forward to delegate
    if ([self.delegate respondsToSelector:@selector(didCloseWithInterstitial:)]) {
        [self.delegate didCloseWithInterstitial:interstitial];
    }
}

- (void)clickWithInterstitial:(id<CLXAdapterInterstitial>)interstitial {
    [logger debug:@"🔧 [CachedInterstitial] clickWithInterstitial called"];
    
    // Forward to delegate
    if ([self.delegate respondsToSelector:@selector(clickWithInterstitial:)]) {
        [self.delegate clickWithInterstitial:interstitial];
    }
}

- (void)didFailToShowWithInterstitial:(id<CLXAdapterInterstitial>)interstitial error:(NSError *)error {
    [logger error:[NSString stringWithFormat:@"🔧 [CachedInterstitial] didFailToShowWithInterstitial called with error: %@", error]];
    
    // Forward to delegate
    if ([self.delegate respondsToSelector:@selector(didFailToShowWithInterstitial:error:)]) {
        [self.delegate didFailToShowWithInterstitial:interstitial error:error];
    }
}

- (void)expiredWithInterstitial:(id<CLXAdapterInterstitial>)interstitial {
    [logger debug:@"🔧 [CachedInterstitial] expiredWithInterstitial called"];
    
    // Forward to delegate
    if ([self.delegate respondsToSelector:@selector(expiredWithInterstitial:)]) {
        [self.delegate expiredWithInterstitial:interstitial];
    }
}

@end

NS_ASSUME_NONNULL_END 
