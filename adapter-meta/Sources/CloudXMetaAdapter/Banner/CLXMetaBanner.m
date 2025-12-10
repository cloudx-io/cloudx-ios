//
//  CLXMetaBanner.m
//  CloudXMetaAdapter
//
//  Created by CLX on 2024-02-14.
//

#import "CLXMetaBanner.h"
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>

// Import internal headers
#if __has_include(<CloudXMetaAdapter/CLXMetaInitializer.h>)
#import <CloudXMetaAdapter/CLXMetaInitializer.h>
#else
#if __has_include("Initializers/CLXMetaInitializer.h")
#import "Initializers/CLXMetaInitializer.h"
#endif
#endif

// Import centralized error handler
#if __has_include(<CloudXMetaAdapter/CLXMetaErrorHandler.h>)
#import <CloudXMetaAdapter/CLXMetaErrorHandler.h>
#else
#import "../Utils/CLXMetaErrorHandler.h"
#endif

@interface CLXMetaBanner ()

@property (nonatomic, copy) NSString *bidID;
@property (nonatomic, copy, nullable) NSString *placementID;  // Now nullable
@property (nonatomic, copy) NSString *bidPayload;
@property (nonatomic, strong) UIViewController *viewController;
@property (nonatomic, assign) CLXBannerType type;
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, assign) NSInteger deferredTemplate;  // Store for deferred creation

@end

@implementation CLXMetaBanner

- (instancetype)initWithBidPayload:(NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                            bidID:(NSString *)bidID
                             type:(CLXBannerType)type
                    viewController:(UIViewController *)viewController
                         delegate:(id<CLXAdapterBannerDelegate>)delegate {
    
    self = [super init];
    if (self) {
        _bidPayload = bidPayload;
        _placementID = placementID;  // Now nullable - validation in load()
        _bidID = bidID;
        _type = type;
        _viewController = viewController;
        _delegate = delegate;
        _sdkVersion = FB_AD_SDK_VERSION;
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXMetaBanner"];
        
        // Parse template from bid payload to ensure exact size match with Meta's bid
        _deferredTemplate = [self parseTemplateFromBidPayload:bidPayload];
        FBAdSize fbAdSize = [self fbAdSizeForTemplate:_deferredTemplate fallbackType:type];
        
        [self.logger debug:[NSString stringWithFormat:@"Init - PlacementID: %@, BidID: %@, Type: %ld, Template: %ld, HasBidPayload: %@", 
                           placementID ?: @"(nil)", bidID, (long)type, (long)_deferredTemplate, bidPayload ? @"YES" : @"NO"]];
        
        // Only create banner view if placementID is valid
        // Otherwise defer to load() for validation
        if (placementID && placementID.length > 0) {
            // Ensure Facebook SDK initialization happens on main thread to prevent crashes
            if ([NSThread isMainThread]) {
                _bannerView = [[FBAdView alloc] initWithPlacementID:placementID
                                                              adSize:fbAdSize
                                                  rootViewController:viewController];
                _bannerView.delegate = self;
            } else {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    self->_bannerView = [[FBAdView alloc] initWithPlacementID:placementID
                                                                        adSize:fbAdSize
                                                            rootViewController:viewController];
                    self->_bannerView.delegate = self;
                });
            }
        }
    }
    return self;
}

- (NSString *)network {
    return @"meta";
}

- (BOOL)isReady {
    BOOL ready = self.bannerView != nil && self.bannerView.isAdValid;
    [self.logger debug:[NSString stringWithFormat:@"isReady: %@ (view: %@, valid: %@)", 
                       ready ? @"YES" : @"NO", self.bannerView ? @"YES" : @"NO", self.bannerView.isAdValid ? @"YES" : @"NO"]];
    return ready;
}

- (BOOL)clx_isFlexibleSize {
    return YES;  // Meta banners are flexible and expand to container width
}

- (BOOL)isFlexibleSize {
    return [self clx_isFlexibleSize];
}

- (void)load {
    // Validate placement ID at load time (deferred validation pattern)
    if (!_placementID || _placementID.length == 0) {
        NSError *error = [CLXError errorWithCode:CLXErrorCodeInvalidAdUnitID
                                     description:@"[Meta] Invalid or missing placement ID for banner ad"];
        [self.logger error:error.localizedDescription];
        
        if ([self.delegate respondsToSelector:@selector(failToLoadBanner:error:)]) {
            [self.delegate failToLoadBanner:self error:error];
        }
        return;
    }
    
    // Create banner view now if not already created (deferred from init)
    if (!_bannerView) {
        FBAdSize fbAdSize = [self fbAdSizeForTemplate:_deferredTemplate fallbackType:_type];
        [self.logger debug:@"Creating banner view with validated placement ID"];
        
        // Ensure Facebook SDK initialization happens on main thread to prevent crashes
        if ([NSThread isMainThread]) {
            _bannerView = [[FBAdView alloc] initWithPlacementID:_placementID
                                                          adSize:fbAdSize
                                              rootViewController:_viewController];
            _bannerView.delegate = self;
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                self->_bannerView = [[FBAdView alloc] initWithPlacementID:self->_placementID
                                                                    adSize:fbAdSize
                                                        rootViewController:self->_viewController];
                self->_bannerView.delegate = self;
            });
        }
    }
    
    [self.logger debug:[NSString stringWithFormat:@"Loading ad - Placement: %@, HasBidPayload: %@", 
                       _placementID, self.bidPayload ? @"YES" : @"NO"]];
    
    // Ensure Meta SDK calls happen on main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.bidPayload) {
            [self.bannerView loadAdWithBidPayload:self.bidPayload];
        } else {
            [self.bannerView loadAd];
        }
    });
}

- (void)loadAd {
    [self load];
}

- (UIView *)adView {
    return _bannerView;
}

- (void)showFromViewController:(UIViewController *)viewController {
    UIViewController *vc = viewController ?: self.viewController;
    if (!vc || !self.bannerView) {
        [self.logger error:@"Cannot show ad - missing view controller or banner view"];
        return;
    }
    
    // Check if ad is valid before showing (per Meta official guidelines)
    if (!self.bannerView.isAdValid) {
        [self.logger error:@"Cannot show ad - not valid"];
        return;
    }
    
    [vc.view addSubview:self.bannerView];
    
    // Position banner at bottom of screen (can be customized)
    CGFloat bannerHeight = (_type == CLXBannerTypeMREC) ? 250 : 50;
    self.bannerView.frame = CGRectMake(0, vc.view.bounds.size.height - bannerHeight, vc.view.bounds.size.width, bannerHeight);
    
    [self.logger info:[NSString stringWithFormat:@"Banner displayed with frame: %@", NSStringFromCGRect(self.bannerView.frame)]];
}

- (void)destroy {
    if (self.bannerView) {
        [self.bannerView removeFromSuperview];
        self.bannerView = nil;
    }
}

#pragma mark - FBAdViewDelegate

- (void)adViewDidLoad:(FBAdView *)adView {
    // Check if ad is valid before proceeding (per Meta official guidelines)
    if (!adView.isAdValid) {
        [self.logger error:@"Ad loaded but invalid"];
        
        // Create an error for invalid ad and call failure delegate
        NSError *invalidAdError = [CLXError errorWithCode:CLXErrorCodeInvalidAd 
                                                      description:@"Banner ad loaded but is not valid"];
        
        if ([self.delegate respondsToSelector:@selector(failToLoadBanner:error:)]) {
            [self.delegate failToLoadBanner:self error:invalidAdError];
        }
        return;
    }
    
    [self.logger info:[NSString stringWithFormat:@"Ad loaded successfully and is valid | Delegate responds to didLoadBanner: %@", 
                       [self.delegate respondsToSelector:@selector(didLoadBanner:)] ? @"YES" : @"NO"]];
    
    if ([self.delegate respondsToSelector:@selector(didLoadBanner:)]) {
        [self.delegate didLoadBanner:self];
    } else {
        [self.logger error:@"Delegate does not respond to didLoadBanner"];
    }
}

- (void)adView:(FBAdView *)adView didFailWithError:(NSError *)error {
    // Use centralized error handler for comprehensive logging and error enhancement
    NSError *enhancedError = [CLXMetaErrorHandler handleMetaError:error
                                                       withLogger:self.logger
                                                          context:@"Banner"
                                                      placementID:self.placementID];
    
    if ([self.delegate respondsToSelector:@selector(failToLoadBanner:error:)]) {
        [self.delegate failToLoadBanner:self error:enhancedError];
    }
}

- (void)adViewDidClick:(FBAdView *)adView {
    [self.logger info:@"👆 [CLXMetaBanner] Ad clicked"];
    
    if ([self.delegate respondsToSelector:@selector(clickBanner:)]) {
        [self.delegate clickBanner:self];
    }
}

- (void)adViewDidFinishHandlingClick:(FBAdView *)adView {
    // No logging needed for this callback
}

- (void)adViewWillLogImpression:(FBAdView *)adView {
    [self.logger info:@"Ad impression logged"];
    
    // Forward the display callback to the SDK
    if ([self.delegate respondsToSelector:@selector(didShowBanner:)]) {
        [self.delegate didShowBanner:self];
    }
    
    // Forward to CloudX delegate if it supports impression tracking
    if ([self.delegate respondsToSelector:@selector(impressionBanner:)]) {
        [self.delegate impressionBanner:self];
    }
}

/**
 * Parses the Meta template number from the bid payload JSON.
 * Meta template numbers:
 * - 3: Rectangle 300x250 (MREC)
 * - 4: Banner 320x50 (fixed size) - uses deprecated kFBAdSize320x50
 * - 5: Banner adaptive height 50 (flexible width)
 * - 6: Banner 728x90 (tablet leaderboard)
 * - 7: Rectangle 300x250 (MREC alternate)
 *
 * Note: Template 4 requires the deprecated kFBAdSize320x50 for fixed sizing.
 *       kFBAdSizeHeight50Banner is adaptive/flexible and maps to template 5.
 */
- (NSInteger)parseTemplateFromBidPayload:(NSString *)bidPayload {
    if (!bidPayload || bidPayload.length == 0) {
        return -1;
    }
    
    NSError *error = nil;
    NSData *jsonData = [bidPayload dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *payload = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    
    if (error || !payload) {
        [self.logger debug:[NSString stringWithFormat:@"⚠️ [CLXMetaBanner] Failed to parse bid payload JSON: %@", error.localizedDescription]];
        return -1;
    }
    
    NSNumber *templateNum = payload[@"template"];
    if (templateNum && [templateNum isKindOfClass:[NSNumber class]]) {
        NSInteger template = templateNum.integerValue;
        [self.logger debug:[NSString stringWithFormat:@"Parsed template from bid payload: %ld", (long)template]];
        return template;
    }
    
    [self.logger debug:@"⚠️ [CLXMetaBanner] No template field found in bid payload"];
    return -1;
}

/**
 * Maps Meta template number to the exact FBAdSize required by Meta Audience Network.
 * This ensures the FBAdView size exactly matches the bid template to prevent
 * "Bid for type X being used on template Y" errors.
 */
- (FBAdSize)fbAdSizeForTemplate:(NSInteger)template fallbackType:(CLXBannerType)fallbackType {
    FBAdSize fbAdSize;
    
    switch (template) {
        case 3: // MREC 300x250
        case 7: // MREC 300x250 (alternate template)
            fbAdSize = kFBAdSizeHeight250Rectangle;
            [self.logger debug:[NSString stringWithFormat:@"📏 [CLXMetaBanner] Using kFBAdSizeHeight250Rectangle (template %ld - MREC)", (long)template]];
            break;
            
        case 4: // Banner 320x50 (fixed size)
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Wdeprecated-declarations"
            fbAdSize = kFBAdSize320x50;
            #pragma clang diagnostic pop
            [self.logger debug:@"📏 [CLXMetaBanner] Using kFBAdSize320x50 (template 4 - fixed 320x50)"];
            break;
            
        case 5: // Adaptive height 50 banner
            fbAdSize = kFBAdSizeHeight50Banner;
            [self.logger debug:@"📏 [CLXMetaBanner] Using kFBAdSizeHeight50Banner (template 5 - adaptive 50)"];
            break;
            
        case 6: // Banner 728x90 (tablet leaderboard)
            fbAdSize = kFBAdSizeHeight90Banner;
            [self.logger debug:@"📏 [CLXMetaBanner] Using kFBAdSizeHeight90Banner (template 6 - 728x90)"];
            break;
            
        default: // Fallback to CloudX banner type if template not found
            [self.logger debug:[NSString stringWithFormat:@"⚠️ [CLXMetaBanner] Unknown template %ld, falling back to CloudX type: %ld", (long)template, (long)fallbackType]];
            fbAdSize = [self fbAdSizeForType:fallbackType];
            break;
    }
    
    return fbAdSize;
}

- (FBAdSize)fbAdSizeForType:(CLXBannerType)type {
    switch (type) {
        case CLXBannerTypeW320H50:
            return kFBAdSizeHeight50Banner;
        case CLXBannerTypeMREC:
            return kFBAdSizeHeight250Rectangle;
        default:
            [self.logger error:[NSString stringWithFormat:@"⚠️ [CLXMetaBanner] Unknown banner type: %ld, defaulting to 50Banner", (long)type]];
            return kFBAdSizeHeight50Banner;
    }
}

@end 
