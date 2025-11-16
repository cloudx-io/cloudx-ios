//
//  CLXMolocoInterstitial.m
//  CloudXMolocoAdapter
//
//  Created by CloudX on 2024.
//

#if __has_include(<CloudXMolocoAdapter/CLXMolocoInterstitial.h>)
#import <CloudXMolocoAdapter/CLXMolocoInterstitial.h>
#else
#import "CLXMolocoInterstitial.h"
#endif

#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>

#if __has_include(<CloudXMolocoAdapter/CLXMolocoInitializer.h>)
#import <CloudXMolocoAdapter/CLXMolocoInitializer.h>
#else
#import "Initializers/CLXMolocoInitializer.h"
#endif

#if __has_include(<CloudXMolocoAdapter/CLXMolocoErrorHandler.h>)
#import <CloudXMolocoAdapter/CLXMolocoErrorHandler.h>
#else
#import "../Utils/CLXMolocoErrorHandler.h"
#endif

@interface CLXMolocoInterstitial () {
    NSString *_bidID;
}

@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, assign) BOOL isLoading;

@end

@implementation CLXMolocoInterstitial

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(NSString *)placementID
                             bidID:(NSString *)bidID
                          delegate:(id<CLXAdapterInterstitialDelegate>)delegate {
    self = [super init];
    if (self) {
        _bidPayload = [bidPayload copy];
        _placementID = [placementID copy];
        _bidID = [bidID copy];
        _delegate = delegate;
        _sdkVersion = [CLXMolocoInitializer sdkVersion];
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXMolocoInterstitial"];
        
        [self.logger debug:[NSString stringWithFormat:@"Init - PlacementID: %@, BidID: %@, HasBidPayload: %@", 
                           placementID, bidID, bidPayload ? @"YES" : @"NO"]];
        
        _interstitial = [[MolocoInterstitial alloc] initWithPlacementID:placementID];
        _interstitial.delegate = self;
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
    BOOL ready = _interstitial && [_interstitial isReady];
    [self.logger debug:[NSString stringWithFormat:@"isReady: %@", ready ? @"YES" : @"NO"]];
    return ready;
}

- (void)load {
    if (_isLoading) {
        [self.logger debug:@"Load already in progress"];
        return;
    }
    
    _isLoading = YES;
    [self.logger debug:[NSString stringWithFormat:@"Loading ad - Placement: %@, HasBidPayload: %@", 
                       _placementID, self.bidPayload ? @"YES" : @"NO"]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.bidPayload) {
            [self.interstitial loadWithBidPayload:self.bidPayload];
        } else {
            [self.interstitial load];
        }
    });
}

- (void)loadAd {
    [self load];
}

- (void)showFromViewController:(UIViewController *)viewController {
    BOOL ready = [self isReady];
    
    if (ready) {
        [self.logger info:@"Showing interstitial ad"];
        
        if ([self.delegate respondsToSelector:@selector(didShowWithInterstitial:)]) {
            [self.delegate didShowWithInterstitial:self];
        }
        
        [_interstitial showFromViewController:viewController];
    } else {
        [self.logger error:@"Cannot show ad - not ready"];
        
        NSError *showError = [CLXError errorWithCode:CLXErrorCodeAdNotReady 
                                        description:@"Cannot show interstitial - ad not ready"];
        
        if ([self.delegate respondsToSelector:@selector(didFailToShowWithInterstitial:error:)]) {
            [self.delegate didFailToShowWithInterstitial:self error:showError];
        }
    }
}

- (void)destroy {
    [self.logger debug:@"Destroying interstitial"];
    
    if (self.interstitial) {
        self.interstitial.delegate = nil;
        self.interstitial = nil;
    }
    
    self.delegate = nil;
    _isLoading = NO;
    
    [self.logger debug:@"Destruction complete"];
}

#pragma mark - MolocoInterstitialDelegate

- (void)molocoInterstitialDidLoad:(MolocoInterstitial *)interstitial {
    [self.logger info:@"Loaded successfully"];
    _isLoading = NO;
    
    if ([self.delegate respondsToSelector:@selector(didLoadWithInterstitial:)]) {
        [self.delegate didLoadWithInterstitial:self];
    }
}

- (void)molocoInterstitial:(MolocoInterstitial *)interstitial didFailToLoadWithError:(NSError *)error {
    [self.logger error:[NSString stringWithFormat:@"Failed to load: %@", error.localizedDescription]];
    _isLoading = NO;
    
    NSError *mappedError = [CLXMolocoErrorHandler handleMolocoError:error
                                                         withLogger:self.logger
                                                            context:@"Interstitial Load"
                                                        placementID:_placementID];
    
    if ([self.delegate respondsToSelector:@selector(didFailToLoadWithInterstitial:error:)]) {
        [self.delegate didFailToLoadWithInterstitial:self error:mappedError];
    }
}

- (void)molocoInterstitialWillAppear:(MolocoInterstitial *)interstitial {
    [self.logger debug:@"Will appear"];
    
    if ([self.delegate respondsToSelector:@selector(impressionWithInterstitial:)]) {
        [self.delegate impressionWithInterstitial:self];
    }
}

- (void)molocoInterstitialDidDisappear:(MolocoInterstitial *)interstitial {
    [self.logger info:@"Did disappear"];
    
    if ([self.delegate respondsToSelector:@selector(didCloseWithInterstitial:)]) {
        [self.delegate didCloseWithInterstitial:self];
    }
}

- (void)molocoInterstitialDidClick:(MolocoInterstitial *)interstitial {
    [self.logger info:@"Did click"];
    
    if ([self.delegate respondsToSelector:@selector(clickWithInterstitial:)]) {
        [self.delegate clickWithInterstitial:self];
    }
}

- (void)molocoInterstitial:(MolocoInterstitial *)interstitial didFailToShowWithError:(NSError *)error {
    [self.logger error:[NSString stringWithFormat:@"Failed to show: %@", error.localizedDescription]];
    
    NSError *mappedError = [CLXMolocoErrorHandler handleMolocoError:error
                                                         withLogger:self.logger
                                                            context:@"Interstitial Show"
                                                        placementID:_placementID];
    
    if ([self.delegate respondsToSelector:@selector(didFailToShowWithInterstitial:error:)]) {
        [self.delegate didFailToShowWithInterstitial:self error:mappedError];
    }
}

@end

