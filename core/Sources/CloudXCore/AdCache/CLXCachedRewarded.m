/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CachedRewarded.m
 * @brief Cached rewarded wrapper implementation
 */

#import <CloudXCore/CLXCachedRewarded.h>
#import <CloudXCore/CLXAdapterRewarded.h>
#import <CloudXCore/CLXDestroyable.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXCachedRewarded () <CLXAdapterRewardedDelegate>

@property (nonatomic, strong, nullable) NSTimer *loadingTimer;
@property (nonatomic, copy, nullable) void (^loadCompletion)(NSError * _Nullable error);

@end

static CLXLogger *logger;

__attribute__((constructor))
static void initializeLogger() {
    logger = [[CLXLogger alloc] initWithCategory:@"CachedRewarded.m"];
}

@implementation CLXCachedRewarded

@synthesize bidResponse = _bidResponse;

- (instancetype)initWithRewarded:(id<CLXAdapterRewarded>)rewarded
                        delegate:(id<CLXAdapterRewardedDelegate>)delegate {
    self = [super init];
    if (self) {
        _rewarded = rewarded;
        _delegate = delegate;
        _impressionID = @"";
        
        // Set self as the delegate for the wrapped rewarded
        _rewarded.delegate = self;
    }
    return self;
}

- (void)dealloc {
    [logger debug:@"🔧 [CachedRewarded] dealloc called"];
    [self destroy];
}

#pragma mark - CacheableAd

- (NSString *)network {
    return self.rewarded.network;
}

- (void)loadWithTimeout:(NSTimeInterval)timeout
             completion:(void (^)(NSError * _Nullable error))completion {
    [logger debug:[NSString stringWithFormat:@"🔧 [CachedRewarded] loadWithTimeout: %f called", timeout]];
    
    self.loadCompletion = completion;
    
    // Set up loading timer
    self.loadingTimer = [NSTimer scheduledTimerWithTimeInterval:timeout
                                                         repeats:NO
                                                           block:^(NSTimer * _Nonnull timer) {
        [logger debug:@"🔧 [CachedRewarded] Loading timer fired"];
        if (self.loadCompletion) {
            NSError *error = [CLXError errorWithCode:CLXErrorCodeLoadTimeout 
                                                 description:@"Loading timeout"];
            self.loadCompletion(error);
            self.loadCompletion = nil;
        }
        [self.loadingTimer invalidate];
        self.loadingTimer = nil;
    }];
    
    // Start loading the rewarded
    [self.rewarded load];
}

- (void)showFromViewController:(UIViewController *)viewController {
    [logger debug:[NSString stringWithFormat:@"🔧 [CachedRewarded] showFromViewController called - Ready: %d", self.rewarded.isReady]];
    
    [self.rewarded showFromViewController:viewController];
    [logger info:@"✅ [CachedRewarded] showFromViewController call completed"];
}

- (void)destroy {
    [logger debug:@"🔧 [CachedRewarded] destroy called"];
    
    // Invalidate timer
    [self.loadingTimer invalidate];
    self.loadingTimer = nil;
    
    // Clear completion block
    self.loadCompletion = nil;
    
    // Destroy the wrapped rewarded
    if ([self.rewarded respondsToSelector:@selector(destroy)]) {
        [(id<CLXDestroyable>)self.rewarded destroy];
    }
}

#pragma mark - CloudXAdapterRewardedDelegate

- (void)didLoadWithRewarded:(id<CLXAdapterRewarded>)rewarded {
    [logger debug:@"🔧 [CachedRewarded] didLoadWithRewarded called"];
    
    // Invalidate timer
    [self.loadingTimer invalidate];
    self.loadingTimer = nil;
    
    // Call completion with success
    if (self.loadCompletion) {
        self.loadCompletion(nil);
        self.loadCompletion = nil;
    }
    
    // Forward to delegate
    if ([self.delegate respondsToSelector:@selector(didLoadWithRewarded:)]) {
        [self.delegate didLoadWithRewarded:rewarded];
    }
}

- (void)didFailToLoadWithRewarded:(id<CLXAdapterRewarded>)rewarded error:(NSError *)error {
    [logger error:[NSString stringWithFormat:@"🔧 [CachedRewarded] didFailToLoadWithRewarded called with error: %@", error]];
    
    // Invalidate timer
    [self.loadingTimer invalidate];
    self.loadingTimer = nil;
    
    // Call completion with error
    if (self.loadCompletion) {
        self.loadCompletion(error);
        self.loadCompletion = nil;
    }
    
    // Forward to delegate
    if ([self.delegate respondsToSelector:@selector(didFailToLoadWithRewarded:error:)]) {
        [self.delegate didFailToLoadWithRewarded:rewarded error:error];
    }
}

- (void)didShowWithRewarded:(id<CLXAdapterRewarded>)rewarded {
    [logger debug:@"🔧 [CachedRewarded] didShowWithRewarded called"];
    
    // Forward to delegate
    if ([self.delegate respondsToSelector:@selector(didShowWithRewarded:)]) {
        [self.delegate didShowWithRewarded:rewarded];
    }
}

- (void)impressionWithRewarded:(id<CLXAdapterRewarded>)rewarded {
    [logger debug:@"🔧 [CachedRewarded] impressionWithRewarded called"];
    
    // Forward to delegate
    if ([self.delegate respondsToSelector:@selector(impressionWithRewarded:)]) {
        [self.delegate impressionWithRewarded:rewarded];
    }
}

- (void)didCloseWithRewarded:(id<CLXAdapterRewarded>)rewarded {
    [logger debug:@"🔧 [CachedRewarded] didCloseWithRewarded called"];
    
    // Forward to delegate
    if ([self.delegate respondsToSelector:@selector(didCloseWithRewarded:)]) {
        [self.delegate didCloseWithRewarded:rewarded];
    }
}

- (void)clickWithRewarded:(id<CLXAdapterRewarded>)rewarded {
    [logger debug:@"🔧 [CachedRewarded] clickWithRewarded called"];
    
    // Forward to delegate
    if ([self.delegate respondsToSelector:@selector(clickWithRewarded:)]) {
        [self.delegate clickWithRewarded:rewarded];
    }
}

- (void)userRewardWithRewarded:(id<CLXAdapterRewarded>)rewarded {
    [logger debug:@"🔧 [CachedRewarded] userRewardWithRewarded called"];
    
    // Forward to delegate
    if ([self.delegate respondsToSelector:@selector(userRewardWithRewarded:)]) {
        [self.delegate userRewardWithRewarded:rewarded];
    }
}

- (void)didFailToShowWithRewarded:(id<CLXAdapterRewarded>)rewarded error:(NSError *)error {
    [logger error:[NSString stringWithFormat:@"🔧 [CachedRewarded] didFailToShowWithRewarded called with error: %@", error]];
    
    // Forward to delegate
    if ([self.delegate respondsToSelector:@selector(didFailToShowWithRewarded:error:)]) {
        [self.delegate didFailToShowWithRewarded:rewarded error:error];
    }
}

- (void)expiredWithRewarded:(id<CLXAdapterRewarded>)rewarded {
    [logger debug:@"🔧 [CachedRewarded] expiredWithRewarded called"];
    
    // Forward to delegate
    if ([self.delegate respondsToSelector:@selector(expiredWithRewarded:)]) {
        [self.delegate expiredWithRewarded:rewarded];
    }
}

@end

NS_ASSUME_NONNULL_END 
