//
//  CLXMolocoRewarded.m
//  CloudXMolocoAdapter
//
//  Created by CloudX on 2024.
//

#if __has_include(<CloudXMolocoAdapter/CLXMolocoRewarded.h>)
#import <CloudXMolocoAdapter/CLXMolocoRewarded.h>
#else
#import "CLXMolocoRewarded.h"
#endif

#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>

#if __has_include(<CloudXMolocoAdapter/CLXMolocoInitializer.h>)
#import <CloudXMolocoAdapter/CLXMolocoInitializer.h>
#else
#import "../Initializers/CLXMolocoInitializer.h"
#endif

#if __has_include(<CloudXMolocoAdapter/CLXMolocoErrorHandler.h>)
#import <CloudXMolocoAdapter/CLXMolocoErrorHandler.h>
#else
#import "../Utils/CLXMolocoErrorHandler.h"
#endif

@interface CLXMolocoRewarded () {
    NSString *_bidID;
}

@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, assign) BOOL hasGrantedReward;

@end

@implementation CLXMolocoRewarded

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                             bidID:(NSString *)bidID
                          delegate:(id<CLXAdapterRewardedDelegate>)delegate {
    self = [super init];
    if (self) {
        _bidPayload = [bidPayload copy];
        _placementID = [placementID copy];  // Now nullable - validation in load()
        _bidID = [bidID copy];
        _delegate = delegate;
        _sdkVersion = [CLXMolocoInitializer sdkVersion];
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXMolocoRewarded"];
        _hasGrantedReward = NO;
        
        [self.logger debug:[NSString stringWithFormat:@"Init - PlacementID: %@, BidID: %@", 
                           placementID ?: @"(nil)", bidID]];
        
        // Only create rewarded ad if placementID is valid
        // Otherwise defer to load() for validation
        if (placementID && placementID.length > 0) {
            _rewardedAd = [[MolocoRewardedAd alloc] initWithPlacementID:placementID];
            _rewardedAd.delegate = self;
        }
    }
    return self;
}

- (NSString *)bidID {
    return _bidID;
}

- (NSString *)network {
    return @"moloco";
}

- (BOOL)isReady {
    BOOL ready = _rewardedAd && [_rewardedAd isReady];
    [self.logger debug:[NSString stringWithFormat:@"isReady: %@", ready ? @"YES" : @"NO"]];
    return ready;
}

- (void)load {
    // Validate placement ID at load time (deferred validation pattern)
    if (!_placementID || _placementID.length == 0) {
        NSError *error = [CLXError errorWithCode:CLXErrorCodeInvalidAdUnitID
                                     description:@"[Moloco] Invalid or missing placement ID for rewarded ad"];
        [self.logger error:error.localizedDescription];
        
        if ([self.delegate respondsToSelector:@selector(didFailToLoadWithRewarded:error:)]) {
            [self.delegate didFailToLoadWithRewarded:self error:error];
        }
        return;
    }
    
    // Create rewarded ad now if not already created (deferred from init)
    if (!_rewardedAd) {
        _rewardedAd = [[MolocoRewardedAd alloc] initWithPlacementID:_placementID];
        _rewardedAd.delegate = self;
        [self.logger debug:@"Created rewarded ad with validated placement ID"];
    }
    
    if (_isLoading) {
        [self.logger debug:@"Load already in progress"];
        return;
    }
    
    _isLoading = YES;
    [self.logger debug:[NSString stringWithFormat:@"Loading rewarded ad - Placement: %@", _placementID]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.bidPayload) {
            [self.rewardedAd loadWithBidPayload:self.bidPayload];
        } else {
            [self.rewardedAd load];
        }
    });
}

- (void)loadAd {
    [self load];
}

- (void)showFromViewController:(UIViewController *)viewController {
    BOOL ready = [self isReady];
    
    if (ready) {
        [self.logger info:@"Showing rewarded ad"];
        _hasGrantedReward = NO;
        
        if ([self.delegate respondsToSelector:@selector(didShowWithRewarded:)]) {
            [self.delegate didShowWithRewarded:self];
        }
        
        [_rewardedAd showFromViewController:viewController];
    } else {
        [self.logger error:@"Cannot show ad - not ready"];
        
        NSError *showError = [CLXError errorWithCode:CLXErrorCodeAdNotReady 
                                        description:@"Cannot show rewarded ad - not ready"];
        
        if ([self.delegate respondsToSelector:@selector(didFailToShowWithRewarded:error:)]) {
            [self.delegate didFailToShowWithRewarded:self error:showError];
        }
    }
}

- (void)destroy {
    [self.logger debug:@"Destroying rewarded ad"];
    
    if (self.rewardedAd) {
        self.rewardedAd.delegate = nil;
        self.rewardedAd = nil;
    }
    
    self.delegate = nil;
    _isLoading = NO;
    _hasGrantedReward = NO;
    
    [self.logger debug:@"Destruction complete"];
}

#pragma mark - MolocoRewardedDelegate

- (void)molocoRewardedDidLoad:(MolocoRewardedAd *)rewardedAd {
    [self.logger info:@"Rewarded ad loaded successfully"];
    _isLoading = NO;
    
    if ([self.delegate respondsToSelector:@selector(didLoadWithRewarded:)]) {
        [self.delegate didLoadWithRewarded:self];
    }
}

- (void)molocoRewarded:(MolocoRewardedAd *)rewardedAd didFailToLoadWithError:(NSError *)error {
    [self.logger error:[NSString stringWithFormat:@"Failed to load: %@", error.localizedDescription]];
    _isLoading = NO;
    
    NSError *mappedError = [CLXMolocoErrorHandler handleMolocoError:error
                                                         withLogger:self.logger
                                                            context:@"Rewarded Load"
                                                        placementID:_placementID];
    
    if ([self.delegate respondsToSelector:@selector(didFailToLoadWithRewarded:error:)]) {
        [self.delegate didFailToLoadWithRewarded:self error:mappedError];
    }
}

- (void)molocoRewardedWillAppear:(MolocoRewardedAd *)rewardedAd {
    [self.logger debug:@"Rewarded ad will appear"];
    
    if ([self.delegate respondsToSelector:@selector(impressionWithRewarded:)]) {
        [self.delegate impressionWithRewarded:self];
    }
}

- (void)molocoRewardedDidDisappear:(MolocoRewardedAd *)rewardedAd {
    [self.logger info:@"Rewarded ad did disappear"];
    
    if ([self.delegate respondsToSelector:@selector(didCloseWithRewarded:)]) {
        [self.delegate didCloseWithRewarded:self];
    }
}

- (void)molocoRewardedDidClick:(MolocoRewardedAd *)rewardedAd {
    [self.logger info:@"Rewarded ad clicked"];
    
    if ([self.delegate respondsToSelector:@selector(clickWithRewarded:)]) {
        [self.delegate clickWithRewarded:self];
    }
}

- (void)molocoRewarded:(MolocoRewardedAd *)rewardedAd didFailToShowWithError:(NSError *)error {
    [self.logger error:[NSString stringWithFormat:@"Failed to show: %@", error.localizedDescription]];
    
    NSError *mappedError = [CLXMolocoErrorHandler handleMolocoError:error
                                                         withLogger:self.logger
                                                            context:@"Rewarded Show"
                                                        placementID:_placementID];
    
    if ([self.delegate respondsToSelector:@selector(didFailToShowWithRewarded:error:)]) {
        [self.delegate didFailToShowWithRewarded:self error:mappedError];
    }
}

- (void)molocoRewardedDidRewardUser:(MolocoRewardedAd *)rewardedAd {
    [self.logger info:@"User earned reward"];
    _hasGrantedReward = YES;
    
    if ([self.delegate respondsToSelector:@selector(userRewardWithRewarded:)]) {
        [self.delegate userRewardWithRewarded:self];
    }
}

@end

