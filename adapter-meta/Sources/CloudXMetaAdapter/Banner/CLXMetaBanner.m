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
@property (nonatomic, copy, nullable) NSString *placementID;
@property (nonatomic, copy, nullable) NSString *placementName;
@property (nonatomic, copy) NSString *bidPayload;
@property (nonatomic, strong) UIViewController *viewController;
@property (nonatomic, assign) CLXBannerType type;
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, assign) NSInteger deferredTemplate;

@end

@implementation CLXMetaBanner

- (instancetype)initWithBidPayload:(NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                     placementName:(nullable NSString *)placementName
                            bidID:(NSString *)bidID
                             type:(CLXBannerType)type
                    viewController:(UIViewController *)viewController
                         delegate:(id<CLXAdapterBannerDelegate>)delegate {
    
    self = [super init];
    if (self) {
        _bidPayload = bidPayload;
        _placementID = placementID;
        _placementName = placementName;
        _bidID = bidID;
        _type = type;
        _viewController = viewController;
        _delegate = delegate;
        _sdkVersion = FB_AD_SDK_VERSION;
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXMetaBanner"];
        
        // Parse template from bid payload to ensure exact size match with Meta's bid
        _deferredTemplate = [self parseTemplateFromBidPayload:bidPayload];
        
        [self.logger debug:[NSString stringWithFormat:@"Init - Placement: %@ (%@), BidID: %@, Type: %ld, Template: %ld, HasBidPayload: %@", 
                           placementName ?: @"(unknown)", placementID ?: @"(nil)", bidID, (long)type, (long)_deferredTemplate, bidPayload ? @"YES" : @"NO"]];
        
        // NOTE: FBAdView creation is deferred to load() to ensure it happens on main thread.
        // This is because init may be called from a background thread (network callback).
    }
    return self;
}

- (NSString *)network {
    return @"meta";
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
        NSString *placementContext = _placementName ? [NSString stringWithFormat:@" for placement '%@'", _placementName] : @"";
        NSString *errorMessage = [NSString stringWithFormat:@"Meta placement ID is empty%@. "
                                  "Make sure to configure the Meta placement ID in your CloudX dashboard under Ad Unit Settings > Meta.",
                                  placementContext];
        NSError *error = [CLXError errorWithCode:CLXErrorCodeAdapterInvalidServerExtras
                                     description:errorMessage];
        [self.logger error:error.localizedDescription];
        
        if ([self.delegate respondsToSelector:@selector(failToLoadBanner:error:)]) {
            [self.delegate failToLoadBanner:self error:error];
        }
        return;
    }
    
    [self.logger debug:[NSString stringWithFormat:@"Loading ad - Placement: %@ (%@), HasBidPayload: %@", 
                       _placementName ?: @"(unknown)", _placementID, self.bidPayload ? @"YES" : @"NO"]];
    
    // FBAdView is a UIView and MUST be created on main thread
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        typeof(self) strongSelf = weakSelf;
        if (!strongSelf) return;
        
        // Create banner view on main thread if not already created
        if (!strongSelf.bannerView) {
            FBAdSize fbAdSize = [strongSelf fbAdSizeForTemplate:strongSelf.deferredTemplate fallbackType:strongSelf.type];
            strongSelf.bannerView = [[FBAdView alloc] initWithPlacementID:strongSelf.placementID
                                                                   adSize:fbAdSize
                                                       rootViewController:strongSelf.viewController];
            strongSelf.bannerView.delegate = strongSelf;
            [strongSelf.logger debug:@"Created banner view on main thread"];
        }
        
        if (strongSelf.bidPayload) {
            [strongSelf.bannerView loadAdWithBidPayload:strongSelf.bidPayload];
        } else {
            [strongSelf.bannerView loadAd];
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
    
    if (!self.bannerView.isAdValid) {
        [self.logger error:@"Cannot show ad - not valid"];
        return;
    }
    
    [self.logger info:@"Banner showFromViewController called"];
}

- (void)destroy {
    [self.logger debug:@"Destroying banner"];
    
    // FBAdView is a UIView - must be cleaned up on main thread
    FBAdView *viewToDestroy = self.bannerView;
    self.bannerView = nil;
    
    if (viewToDestroy) {
        if ([NSThread isMainThread]) {
            viewToDestroy.delegate = nil;
            [viewToDestroy removeFromSuperview];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                viewToDestroy.delegate = nil;
                [viewToDestroy removeFromSuperview];
            });
        }
    }
    
    [self.logger debug:@"Destruction complete"];
}

#pragma mark - FBAdViewDelegate

- (void)adViewDidLoad:(FBAdView *)adView {
    [self.logger info:[NSString stringWithFormat:@"✅ Loaded successfully - Valid: %@", adView.isAdValid ? @"YES" : @"NO"]];
    
    if (!adView.isAdValid) {
        [self.logger error:@"Ad loaded but invalid"];
        
        NSError *invalidAdError = [CLXError errorWithCode:CLXErrorCodeInvalidAd 
                                              description:@"Banner ad loaded but is not valid"];
        
        if ([self.delegate respondsToSelector:@selector(failToLoadBanner:error:)]) {
            [self.delegate failToLoadBanner:self error:invalidAdError];
        }
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(didLoadBanner:)]) {
        [self.delegate didLoadBanner:self];
    }
}

- (void)adView:(FBAdView *)adView didFailWithError:(NSError *)error {
    NSError *enhancedError = [CLXMetaErrorHandler handleMetaError:error
                                                       withLogger:self.logger
                                                          context:@"Banner"
                                                      placementID:self.placementID];
    
    if ([self.delegate respondsToSelector:@selector(failToLoadBanner:error:)]) {
        [self.delegate failToLoadBanner:self error:enhancedError];
    }
}

- (void)adViewDidClick:(FBAdView *)adView {
    [self.logger info:@"👆 Ad clicked"];
    
    if ([self.delegate respondsToSelector:@selector(clickBanner:)]) {
        [self.delegate clickBanner:self];
    }
}

- (void)adViewDidFinishHandlingClick:(FBAdView *)adView {
    // Click handling finished
}

- (void)adViewWillLogImpression:(FBAdView *)adView {
    [self.logger info:@"Ad impression logged"];
    
    if ([self.delegate respondsToSelector:@selector(didShowBanner:)]) {
        [self.delegate didShowBanner:self];
    }
    
    if ([self.delegate respondsToSelector:@selector(impressionBanner:)]) {
        [self.delegate impressionBanner:self];
    }
}

- (UIViewController *)viewControllerForPresentingModalView {
    return self.viewController ?: [self topViewController];
}

#pragma mark - Template Parsing

/**
 * Parses the Meta template number from the bid payload JSON.
 * Meta template numbers:
 * - 3: Rectangle 300x250 (MREC)
 * - 4: Banner 320x50 (fixed size)
 * - 5: Banner adaptive height 50 (flexible width)
 * - 6: Banner 728x90 (tablet leaderboard)
 * - 7: Rectangle 300x250 (MREC alternate)
 */
- (NSInteger)parseTemplateFromBidPayload:(NSString *)bidPayload {
    if (!bidPayload || bidPayload.length == 0) {
        return -1;
    }
    
    NSError *error = nil;
    NSData *jsonData = [bidPayload dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *payload = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    
    if (error || !payload) {
        return -1;
    }
    
    NSNumber *templateNum = payload[@"template"];
    if (templateNum && [templateNum isKindOfClass:[NSNumber class]]) {
        NSInteger template = templateNum.integerValue;
        [self.logger debug:[NSString stringWithFormat:@"Parsed template from bid payload: %ld", (long)template]];
        return template;
    }
    
    return -1;
}

/**
 * Maps Meta template number to the exact FBAdSize required by Meta Audience Network.
 */
- (FBAdSize)fbAdSizeForTemplate:(NSInteger)template fallbackType:(CLXBannerType)fallbackType {
    switch (template) {
        case 3:
        case 7:
            return kFBAdSizeHeight250Rectangle;
            
        case 4:
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Wdeprecated-declarations"
            return kFBAdSize320x50;
            #pragma clang diagnostic pop
            
        case 5:
            return kFBAdSizeHeight50Banner;
            
        case 6:
            return kFBAdSizeHeight90Banner;
            
        default:
            return [self fbAdSizeForType:fallbackType];
    }
}

- (FBAdSize)fbAdSizeForType:(CLXBannerType)type {
    switch (type) {
        case CLXBannerTypeW320H50:
            return kFBAdSizeHeight50Banner;
        case CLXBannerTypeMREC:
            return kFBAdSizeHeight250Rectangle;
        default:
            return kFBAdSizeHeight50Banner;
    }
}

#pragma mark - Helpers

- (UIViewController *)topViewController {
    UIViewController *rootVC = nil;
    
    if (@available(iOS 13.0, *)) {
        NSSet *scenes = [UIApplication sharedApplication].connectedScenes;
        for (UIWindowScene *scene in scenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *window in scene.windows) {
                    if (window.isKeyWindow) {
                        rootVC = window.rootViewController;
                        break;
                    }
                }
                if (rootVC) break;
            }
        }
    }
    
    if (!rootVC) {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wdeprecated-declarations"
        rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
        #pragma clang diagnostic pop
    }
    
    while (rootVC.presentedViewController) {
        rootVC = rootVC.presentedViewController;
    }
    
    return rootVC;
}

@end
