#import <CloudXCore/CLXNativeAdView.h>

#import <CloudXCore/CLXNative.h>
#import <CloudXCore/CLXNativeTemplate.h>
#import <CloudXCore/CLXAdapterNative.h>
#import <CloudXCore/CLXPublisherNative.h>
#import <CloudXCore/CLXBidAdSource.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXDebugClickFeedback.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import <UIKit/UIKit.h>

// Category to expose internal properties of CLXPublisherNative
@interface CLXPublisherNative (CLXNativeAdViewAccess)
@property (nonatomic, strong, nullable, readonly) CLXBidAdSourceResponse *lastBidResponse;
@property (nonatomic, copy, readonly) NSString *placementID;
@property (nonatomic, copy, readonly) NSString *placementName;
@end

@interface CLXNativeAdView () <UIGestureRecognizerDelegate> {
    id<CLXNative> _native;
    CLXNativeTemplate _type;
}

@property (nonatomic, strong) id<CLXNative> native;
@property (nonatomic, assign) CLXNativeTemplate type;
@property (nonatomic, strong) UIGestureRecognizer *debugTapGesture;
@property (nonatomic, weak) UIView *currentNativeView;  // Track the actual third-party SDK view

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

        // Set up revenue delegate relay
        if ([_native respondsToSelector:@selector(setRevenueDelegate:)]) {
            [(CLXPublisherNative *)_native setRevenueDelegate:self];
        }

        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = YES;
        
        // Setup debug gesture only if visual debugging is enabled
        [self updateDebugGestureState];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateDebugGestureState)
                                                     name:NSUserDefaultsDidChangeNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSUserDefaultsDidChangeNotification object:nil];
}

- (void)updateDebugGestureState {
    // Visual debugging is completely separate from testMode
    BOOL isEnabled = [CloudXCore isVisualDebuggingEnabled];
    
    // Attach gesture to the ACTUAL native view (third-party SDK's view), not the container
    UIView *targetView = self.currentNativeView ?: self;
    
    if (isEnabled && !self.debugTapGesture && targetView) {
        // Use long press with 0 duration to fire immediately on touch down
        UILongPressGestureRecognizer *gesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleDebugTouch:)];
        gesture.minimumPressDuration = 0;
        gesture.cancelsTouchesInView = NO;
        gesture.delaysTouchesBegan = NO;
        gesture.delaysTouchesEnded = NO;
        gesture.delegate = self;  // Allow simultaneous recognition with third-party gestures
        self.debugTapGesture = gesture;
        [targetView addGestureRecognizer:gesture];
    } else if (!isEnabled && self.debugTapGesture) {
        UIView *gestureView = self.debugTapGesture.view;
        if (gestureView) {
            [gestureView removeGestureRecognizer:self.debugTapGesture];
        }
        self.debugTapGesture = nil;
    }
}

- (void)attachDebugGestureToNativeView:(UIView *)nativeView {
    // Store reference and re-attach gesture to the new native view
    self.currentNativeView = nativeView;
    
    // If we already have a gesture, move it to the new view
    if (self.debugTapGesture) {
        UIView *oldView = self.debugTapGesture.view;
        if (oldView) {
            [oldView removeGestureRecognizer:self.debugTapGesture];
        }
        [nativeView addGestureRecognizer:self.debugTapGesture];
    } else {
        // Re-check if we should add the gesture
        [self updateDebugGestureState];
    }
}

- (void)handleDebugTouch:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [CLXDebugClickFeedback showClickPendingOnView:self.currentNativeView ?: self];
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
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
            if ([self.delegate respondsToSelector:@selector(didFailToLoadAd:error:)]) {
                CLXError *error = [CLXError errorWithCode:CLXErrorCodeInvalidNativeView
                                               description:@"Native view is nil"];
                [self.delegate didFailToLoadAd:((CLXPublisherNative *)self.native).placementName error:error];
            }
        });
        return;
    }
    
    [logger debug:@"[CloudXNativeAdView] Adding native view to view hierarchy"];
    nativeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    nativeView.userInteractionEnabled = YES;
    [self addSubview:nativeView];
    
    // Attach debug gesture to the ACTUAL native view (third-party SDK's view)
    [self attachDebugGestureToNativeView:nativeView];
    
    // Set isReady to true so UI knows ad is ready (matching Swift behavior)
    self.isReady = YES;
    
    // Notify delegate that ad is loaded (this will update the status label to green)
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(didLoadAd:)]) {
            CLXPublisherNative *publisherNative = (CLXPublisherNative *)self.native;
            CLXAd *delegateAd = [CLXAd adFromBid:publisherNative.lastBidResponse.bid placementId:publisherNative.placementID placementName:publisherNative.placementName];
            [self.delegate didLoadAd:delegateAd];
        }
    });
}

- (void)failToLoadWithNative:(nullable id<CLXAdapterNative>)native error:(nullable NSError *)error {
    [logger error:[NSString stringWithFormat:@"[CloudXNativeAdView] failToLoadWithNative called with error: %@", error.localizedDescription]];

    // Notify delegate on main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(didFailToLoadAd:error:)]) {
            // Ensure we always have a valid CLXError for delegate (fallback if error is nil)
            CLXError *clxError = [CLXError errorFromError:error withFallbackCode:CLXErrorCodeLoadFailed];
            if (!clxError) {
                clxError = [CLXError errorWithCode:CLXErrorCodeLoadFailed];
            }
            [self.delegate didFailToLoadAd:((CLXPublisherNative *)self.native).placementName error:clxError];
        }
    });
}

- (void)didShowWithNative:(id<CLXAdapterNative>)native {
    [logger debug:@"[CloudXNativeAdView] didShowWithNative called"];
}

- (void)impressionWithNative:(id<CLXAdapterNative>)native {
    [logger debug:@"[CloudXNativeAdView] impressionWithNative called"];
}

// Revenue callback bridge method - called by CLXPublisherNative completion block
- (void)didPayRevenueForAd:(CLXAd *)ad {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.revenueDelegate respondsToSelector:@selector(didPayRevenueForAd:)]) {
            [self.revenueDelegate didPayRevenueForAd:ad];
        }
    });
}

- (void)clickWithNative:(id<CLXAdapterNative>)native {
    [logger debug:@"[CloudXNativeAdView] clickWithNative called"];
    
    // Show green border on same view where white pending border was shown
    [CLXDebugClickFeedback showClickConfirmedOnView:self.currentNativeView ?: self];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(didClickAd:)]) {
            [self.delegate didClickAd:[CLXAd adFromBid:((CLXPublisherNative *)self.native).lastBidResponse.bid placementId:((CLXPublisherNative *)self.native).placementID placementName:((CLXPublisherNative *)self.native).placementName]];
        }
    });
}

- (void)closeWithNative:(id<CLXAdapterNative>)native {
    [logger debug:@"[CloudXNativeAdView] closeWithNative called"];
}


@end 
