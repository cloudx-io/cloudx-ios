//
//  CLXMolocoNative.m
//  CloudXMolocoAdapter
//
//  Created by CloudX on 2024.
//

#if __has_include(<CloudXMolocoAdapter/CLXMolocoNative.h>)
#import <CloudXMolocoAdapter/CLXMolocoNative.h>
#else
#import "CLXMolocoNative.h"
#endif

#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXNativeAdData.h>

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

@interface CLXMolocoNative () {
    NSString *_bidID;
}

@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, assign) BOOL isLoading;

@end

@implementation CLXMolocoNative

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(NSString *)placementID
                             bidID:(NSString *)bidID
                          delegate:(id<CLXAdapterNativeDelegate>)delegate {
    self = [super init];
    if (self) {
        _bidPayload = [bidPayload copy];
        _placementID = [placementID copy];
        _bidID = [bidID copy];
        _delegate = delegate;
        _sdkVersion = [CLXMolocoInitializer sdkVersion];
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXMolocoNative"];
        
        [self.logger debug:[NSString stringWithFormat:@"Init - PlacementID: %@, BidID: %@", placementID, bidID]];
        
        _nativeAd = [[MolocoNativeAd alloc] initWithPlacementID:placementID];
        _nativeAd.delegate = self;
    }
    return self;
}

- (NSString *)bidID {
    return _bidID;
}

- (NSString *)network {
    return @"moloco";
}

- (void)load {
    if (_isLoading) {
        [self.logger debug:@"Load already in progress"];
        return;
    }
    
    _isLoading = YES;
    [self.logger debug:[NSString stringWithFormat:@"Loading native ad - Placement: %@", _placementID]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.bidPayload) {
            [self.nativeAd loadWithBidPayload:self.bidPayload];
        } else {
            [self.nativeAd load];
        }
    });
}

- (void)loadAd {
    [self load];
}

- (void)destroy {
    [self.logger debug:@"Destroying native ad"];
    
    if (self.nativeAd) {
        self.nativeAd.delegate = nil;
        self.nativeAd = nil;
    }
    
    self.delegate = nil;
    _isLoading = NO;
    
    [self.logger debug:@"Destruction complete"];
}

- (void)registerViewForInteraction:(UIView *)view
                    withClickableViews:(NSArray<UIView *> *)clickableViews {
    if (!self.nativeAd) {
        [self.logger error:@"Cannot register view - native ad is nil"];
        return;
    }
    
    [self.logger debug:@"Registering view for interaction"];
    [self.nativeAd registerViewForInteraction:view withClickableViews:clickableViews];
}

#pragma mark - MolocoNativeDelegate

- (void)molocoNativeDidLoad:(MolocoNativeAd *)nativeAd {
    [self.logger info:@"Native ad loaded successfully"];
    _isLoading = NO;
    
    // Convert Moloco native ad data to CloudX format
    CLXNativeAdData *adData = [[CLXNativeAdData alloc] init];
    adData.title = nativeAd.title;
    adData.body = nativeAd.body;
    adData.callToAction = nativeAd.callToAction;
    adData.advertiser = nativeAd.advertiser;
    adData.iconURL = nativeAd.iconURL;
    adData.imageURL = nativeAd.imageURL;
    adData.starRating = nativeAd.starRating;
    
    if ([self.delegate respondsToSelector:@selector(didLoadWithNative:nativeAdData:)]) {
        [self.delegate didLoadWithNative:self nativeAdData:adData];
    }
}

- (void)molocoNative:(MolocoNativeAd *)nativeAd didFailToLoadWithError:(NSError *)error {
    [self.logger error:[NSString stringWithFormat:@"Failed to load: %@", error.localizedDescription]];
    _isLoading = NO;
    
    NSError *mappedError = [CLXMolocoErrorHandler handleMolocoError:error
                                                         withLogger:self.logger
                                                            context:@"Native Load"
                                                        placementID:_placementID];
    
    if ([self.delegate respondsToSelector:@selector(didFailToLoadWithNative:error:)]) {
        [self.delegate didFailToLoadWithNative:self error:mappedError];
    }
}

- (void)molocoNativeDidRecordImpression:(MolocoNativeAd *)nativeAd {
    [self.logger info:@"Native ad impression recorded"];
    
    if ([self.delegate respondsToSelector:@selector(impressionWithNative:)]) {
        [self.delegate impressionWithNative:self];
    }
}

- (void)molocoNativeDidClick:(MolocoNativeAd *)nativeAd {
    [self.logger info:@"Native ad clicked"];
    
    if ([self.delegate respondsToSelector:@selector(clickWithNative:)]) {
        [self.delegate clickWithNative:self];
    }
}

@end

