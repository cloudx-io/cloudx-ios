//
//  CLXInMobiInterstitial.m
//  CloudXInMobiAdapter
//
//  Created by CloudX Team.
//

#if __has_include(<CloudXInMobiAdapter/CLXInMobiInterstitial.h>)
#import <CloudXInMobiAdapter/CLXInMobiInterstitial.h>
#else
#import "CLXInMobiInterstitial.h"
#endif

#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>

#if __has_include(<CloudXInMobiAdapter/CLXInMobiErrorHandler.h>)
#import <CloudXInMobiAdapter/CLXInMobiErrorHandler.h>
#else
#import "../Utils/CLXInMobiErrorHandler.h"
#endif

#if __has_include(<CloudXInMobiAdapter/CLXInMobiInitializer.h>)
#import <CloudXInMobiAdapter/CLXInMobiInitializer.h>
#else
#import "../Initializers/CLXInMobiInitializer.h"
#endif

@interface CLXInMobiInterstitial () {
    NSString *_bidID;
}
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, strong, nullable) IMInterstitial *interstitial;
@property (nonatomic, strong, nullable) NSData *bidPayload;
@property (nonatomic, assign) long long placementID;
@property (nonatomic, copy, nullable) NSString *adUnitName;
@end

@implementation CLXInMobiInterstitial

- (instancetype)initWithBidPayload:(nullable NSData *)bidPayload
                       placementID:(long long)placementID
                     adUnitName:(nullable NSString *)adUnitName
                             bidID:(NSString *)bidID
                          delegate:(id<CLXAdapterInterstitialDelegate>)delegate {
    self = [super init];
    if (self) {
        _bidPayload = bidPayload;
        _placementID = placementID;  // May be 0 (invalid) - validation in load()
        _adUnitName = [adUnitName copy];  // For error messages
        _bidID = [bidID copy];
        _delegate = delegate;
        _sdkVersion = [CLXInMobiInitializer sdkVersion];
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXInMobiInterstitial"];
        
        [self.logger debug:[NSString stringWithFormat:@"Init - Placement: %@ (%lld%@), BidID: %@, HasBidPayload: %@",
                           adUnitName ?: @"(unknown)", placementID, (placementID == 0 ? @" - invalid" : @""), bidID, bidPayload ? @"YES" : @"NO"]];
    }
    return self;
}

- (NSString *)bidID {
    return _bidID;
}

- (NSString *)network {
    return @"inmobi";
}

- (void)load {
    // Validate placement ID at load time (deferred validation pattern)
    if (_placementID == 0) {
        NSString *adUnitContext = _adUnitName ? [NSString stringWithFormat:@" for ad unit '%@'", _adUnitName] : @"";
        NSString *errorMessage = [NSString stringWithFormat:@"InMobi placement ID is empty%@. "
                                  "Make sure to configure the InMobi placement ID in your CloudX dashboard under Ad Unit Settings > InMobi.",
                                  adUnitContext];
        NSError *error = [CLXError errorWithCode:CLXErrorCodeAdapterInvalidServerExtras
                                     description:errorMessage];
        [self.logger error:error.localizedDescription];

        id<CLXAdapterInterstitialDelegate> delegate = self.delegate;
        if (delegate) {
            [delegate didFailToLoadWithInterstitial:self error:error];
        }
        return;
    }
    
    if (!_interstitial) {
        _interstitial = [[IMInterstitial alloc] initWithPlacementId:_placementID];
        _interstitial.delegate = self;
    }
    
    [self.logger debug:[NSString stringWithFormat:@"Loading ad - Placement: %lld, HasBidPayload: %@",
                       _placementID, self.bidPayload ? @"YES" : @"NO"]];

    [self.interstitial setExtras:[CLXInMobiInitializer extras]];
    if (self.bidPayload) {
        [self.interstitial load:self.bidPayload];
    } else {
        [self.interstitial load];
    }
}

- (void)showFromViewController:(UIViewController *)viewController {
    if ([_interstitial isReady]) {
        [self.logger info:@"Showing interstitial ad"];
        [_interstitial showFrom:viewController];
    } else {
        [self.logger error:@"Cannot show ad - not ready"];

        NSError *showError = [CLXError errorWithCode:CLXErrorCodeAdapterAdNotReady
                                         description:@"Cannot show interstitial - ad not ready"];
        CLXError *clxError = [CLXInMobiErrorHandler toCloudXError:showError];
        id<CLXAdapterInterstitialDelegate> delegate = self.delegate;
        if (delegate) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate didFailToShowWithInterstitial:self error:clxError];
            });
        }
    }
}

#pragma mark - IMInterstitialDelegate

- (void)interstitialDidFinishLoading:(IMInterstitial *)interstitial {
    [self.logger info:[NSString stringWithFormat:@"Loaded successfully - Ready: %@", [interstitial isReady] ? @"YES" : @"NO"]];

    [self.delegate didLoadWithInterstitial:self];
}

- (void)interstitial:(IMInterstitial *)interstitial didFailToLoadWithError:(IMRequestStatus *)error {
    [self.logger error:[NSString stringWithFormat:@"Failed to load: %@", error.localizedDescription]];

    CLXError *clxError = [CLXInMobiErrorHandler toCloudXError:error];
    [self.delegate didFailToLoadWithInterstitial:self error:clxError];
}

- (void)interstitialDidPresent:(IMInterstitial *)interstitial {
    [self.logger info:@"Interstitial presented"];
}

- (void)interstitial:(IMInterstitial *)interstitial didFailToPresentWithError:(IMRequestStatus *)error {
    [self.logger error:[NSString stringWithFormat:@"Failed to show: %@", error.localizedDescription]];
    
    CLXError *clxError = [CLXInMobiErrorHandler toCloudXError:error];
    [self.delegate didFailToShowWithInterstitial:self error:clxError];
}

- (void)interstitialWillPresent:(IMInterstitial *)interstitial {
    [self.logger debug:@"Interstitial will present"];
}

- (void)interstitialDidDismiss:(IMInterstitial *)interstitial {
    [self.logger info:@"Interstitial dismissed"];
    
    [self.delegate didCloseWithInterstitial:self];
}

- (void)interstitialAdImpressed:(IMInterstitial *)interstitial {
    // Native SDK impression callback - fires when ad is actually displayed/rendered
    [self.logger info:@"Interstitial impression tracked"];

    // Fire show callback on impression (when ad is actually visible)
    [self.delegate didShowWithInterstitial:self];
    [self.delegate impressionWithInterstitial:self];
}

- (void)interstitial:(IMInterstitial *)interstitial didInteractWithParams:(nullable NSDictionary *)params {
    [self.logger info:@"Interstitial clicked"];
    
    [self.delegate clickWithInterstitial:self];
}

- (void)userWillLeaveApplicationFromInterstitial:(IMInterstitial *)interstitial {
    [self.logger debug:@"User will leave application"];
}

- (void)interstitial:(IMInterstitial *)interstitial didReceiveWithMetaInfo:(IMAdMetaInfo *)metaInfo {
    [self.logger debug:@"Interstitial request succeeded"];
}

@end

