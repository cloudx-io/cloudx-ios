#import <CloudXCore/CLXNativeAdView.h>

#import <CloudXCore/CLXNative.h>
#import <CloudXCore/CLXNativeTemplate.h>
#import <CloudXCore/CLXAdapterNative.h>
#import <CloudXCore/CLXPublisherNative.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>
#import <UIKit/UIKit.h>

// Category to expose internal properties of CLXPublisherNative
@interface CLXPublisherNative (CLXNativeAdViewAccess)
@property (nonatomic, strong, nullable, readonly) CLXBidAdSourceResponse *lastBidResponse;
@property (nonatomic, copy, readonly) NSString *placementID;
@end

@interface CLXNativeAdView () {
    id<CLXNative> _native;
    CLXNativeTemplate _type;
}

@property (nonatomic, strong) id<CLXNative> native;
@property (nonatomic, assign) CLXNativeTemplate type;


@end

static CLXLogger *logger;

__attribute__((constructor))
static void initializeLogger() {
    logger = [[CLXLogger alloc] initWithCategory:@"NativeAdView.m"];
}

@implementation CLXNativeAdView

- (instancetype)initWithNative:(id<CLXNative>)native type:(NSInteger)type delegate:(id<CLXNativeDelegate>)delegate {
    // Set frame based on template size (matching Swift version)
    CGSize size = [self sizeForTemplateType:type];
    self = [super initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    if (self) {
        _native = native;
        _type = type;
        self.delegate = delegate;
        self.isReady = NO;
        self.suspendPreloadWhenInvisible = YES;
        
        // Set up native delegate
        if ([_native respondsToSelector:@selector(setDelegate:)]) {
            [_native setDelegate:(id)self];
        }
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = YES;
    }
    return self;
}

- (CGSize)sizeForTemplateType:(NSInteger)type {
    switch (type) {
        case 0: // small
        case 2: // smallWithCloseButton
            return CGSizeMake(320, 90);
        case 1: // medium
        case 3: // mediumWithCloseButton
            return CGSizeMake(320, 250);
        default:
            return CGSizeMake(320, 90);
    }
}

- (void)setSuspendPreloadWhenInvisible:(BOOL)suspendPreloadWhenInvisible {
    _suspendPreloadWhenInvisible = suspendPreloadWhenInvisible;
    if ([_native respondsToSelector:@selector(setSuspendPreloadWhenInvisible:)]) {
        [_native setSuspendPreloadWhenInvisible:suspendPreloadWhenInvisible];
    }
}

- (void)load {
    if ([_native respondsToSelector:@selector(load)]) {
        [_native load];
    }
}

- (void)destroy {
    [self removeFromSuperview];
    if ([_native respondsToSelector:@selector(destroy)]) {
        [_native destroy];
    }
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    
    if (self.superview != nil) {
        [self load];
    }
}

#pragma mark - CLXAdapterNativeDelegate

- (void)didLoadWithNative:(id<CLXAdapterNative>)native {
    [logger debug:@"[CloudXNativeAdView] didLoadWithNative called"];
    
    // Check if native view exists
    UIView *nativeView = native.nativeView;
    if (!nativeView) {
        [logger error:@"[CloudXNativeAdView] didLoadWithNative failed: nativeView is nil"];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(failToLoadWithAd:error:)]) {
                NSError *error = [CLXError errorWithCode:CLXErrorCodeInvalidNativeView 
                                               description:@"Native view is nil"];
                [self.delegate failToLoadWithAd:[CLXAd adFromBid:((CLXPublisherNative *)self.native).lastBidResponse.bid placementId:((CLXPublisherNative *)self.native).placementID] error:error];
            }
        });
        return;
    }
    
    [logger debug:@"[CloudXNativeAdView] Adding native view to view hierarchy"];
    nativeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    nativeView.userInteractionEnabled = YES;
    [self addSubview:nativeView];
    
    // Set isReady to true so UI knows ad is ready (matching Swift behavior)
    self.isReady = YES;
    
    // Notify delegate that ad is loaded (this will update the status label to green)
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(didLoadWithAd:)]) {
            CLXPublisherNative *publisherNative = (CLXPublisherNative *)self.native;
            CLXAd *delegateAd = [CLXAd adFromBid:publisherNative.lastBidResponse.bid placementId:publisherNative.placementID];
            [self.delegate didLoadWithAd:delegateAd];
        }
    });
}

- (void)failToLoadWithNative:(nullable id<CLXAdapterNative>)native error:(nullable NSError *)error {
    [logger error:[NSString stringWithFormat:@"[CloudXNativeAdView] failToLoadWithNative called with error: %@", error.localizedDescription]];
    
    // Notify delegate on main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(failToLoadWithAd:error:)]) {
            [self.delegate failToLoadWithAd:[CLXAd adFromBid:((CLXPublisherNative *)self.native).lastBidResponse.bid placementId:((CLXPublisherNative *)self.native).placementID] error:error];
        }
    });
}

- (void)didShowWithNative:(id<CLXAdapterNative>)native {
    [logger debug:@"[CloudXNativeAdView] didShowWithNative called"];
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(didShowWithAd:)]) {
            [self.delegate didShowWithAd:[CLXAd adFromBid:((CLXPublisherNative *)self.native).lastBidResponse.bid placementId:((CLXPublisherNative *)self.native).placementID]];
        }
    });
}

- (void)impressionWithNative:(id<CLXAdapterNative>)native {
    [logger debug:@"[CloudXNativeAdView] impressionWithNative called"];
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(impressionOn:)]) {
            CLXPublisherNative *publisherNative = (CLXPublisherNative *)self.native;
            CLXAd *impressionAd = [CLXAd adFromBid:publisherNative.lastBidResponse.bid placementId:publisherNative.placementID];
            [self.delegate impressionOn:impressionAd];
        }
    });
}

// Revenue callback bridge method - called by CLXPublisherNative completion block
- (void)revenuePaid:(CLXAd *)ad {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(revenuePaid:)]) {
            [self.delegate revenuePaid:ad];
        }
    });
}

- (void)clickWithNative:(id<CLXAdapterNative>)native {
    [logger debug:@"[CloudXNativeAdView] clickWithNative called"];
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(didClickWithAd:)]) {
            [self.delegate didClickWithAd:[CLXAd adFromBid:((CLXPublisherNative *)self.native).lastBidResponse.bid placementId:((CLXPublisherNative *)self.native).placementID]];
        }
    });
}

- (void)closeWithNative:(id<CLXAdapterNative>)native {
    [logger debug:@"[CloudXNativeAdView] closeWithNative called"];
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(closedByUserActionWithAd:)]) {
            [self.delegate closedByUserActionWithAd:[CLXAd adFromBid:((CLXPublisherNative *)self.native).lastBidResponse.bid placementId:((CLXPublisherNative *)self.native).placementID]];
        }
    });
}


@end 
