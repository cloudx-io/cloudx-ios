//
//  CLXBannerMocks.h
//  CloudXCoreTests
//
//  Shared mock objects for banner-related unit tests
//  Note: Implementations are inline to avoid linker issues
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

// Forward declarations
@class CLXBidResponse;
@class CLXAdConfiguration;

// MARK: - Mock Banner Delegate

@interface MockBannerDelegate : NSObject <CLXBannerDelegate>
@property (nonatomic, assign) BOOL didExpandCalled;
@property (nonatomic, assign) BOOL didCollapseCalled;
@property (nonatomic, assign) BOOL didLoadCalled;
@property (nonatomic, assign) BOOL failToLoadCalled;
@property (nonatomic, assign) BOOL didShowCalled;
@property (nonatomic, assign) BOOL impressionCalled;
@property (nonatomic, assign) BOOL clickCalled;
@property (nonatomic, strong, nullable) NSError *lastError;
@property (nonatomic, copy, nullable) NSString *lastPlacementName;
@property (nonatomic, strong, nullable) CLXAd *lastAd;
@property (nonatomic, strong, nullable) id<CLXAdapterBanner> lastBanner;
// Additional properties for expand/collapse tracking
@property (nonatomic, strong, nullable) CLXAd *lastExpandedAd;
@property (nonatomic, strong, nullable) CLXAd *lastCollapsedAd;
// Callback blocks for async test expectations
@property (nonatomic, copy, nullable) void (^failToLoadCallback)(void);
@property (nonatomic, copy, nullable) void (^didLoadCallback)(void);
@end

// MARK: - Mock Banner Adapter

@interface MockBannerAdapter : NSObject <CLXAdapterBanner>
@property (nonatomic, weak, nullable) id<CLXAdapterBannerDelegate> delegate;
@property (nonatomic, assign) BOOL timeout;
@property (nonatomic, strong, nullable, readonly) UIView *bannerView;
@property (nonatomic, copy, readonly) NSString *sdkVersion;
@property (nonatomic, copy, readonly) NSString *adapterID;
@property (nonatomic, assign) BOOL shouldFailLoad;
@property (nonatomic, assign) BOOL loadCalled;
@property (nonatomic, assign) BOOL showCalled;
@property (nonatomic, assign) BOOL destroyCalled;

- (instancetype)initWithID:(NSString *)adapterID;
@end

// MARK: - Mock Publisher Banner

@interface MockPublisherBanner : NSObject <CLXBanner>
@property (nonatomic, copy) NSString *adUnitId;
@property (nonatomic, weak) id<CLXBannerDelegate> delegate;
@property (nonatomic, assign) BOOL startAutoRefreshCalled;
@property (nonatomic, assign) BOOL stopAutoRefreshCalled;
@property (nonatomic, assign) BOOL setVisibleCalled;
@property (nonatomic, assign) BOOL lastVisibleValue;
@end

NS_ASSUME_NONNULL_END

// MARK: - Inline Implementations (to avoid linker issues)

#ifdef CLXBANNER_MOCKS_IMPLEMENTATION

@implementation MockBannerDelegate

- (void)didLoadAd:(CLXAd *)ad {
    self.didLoadCalled = YES;
    self.lastAd = ad;
    if (self.didLoadCallback) {
        self.didLoadCallback();
    }
}

- (void)didFailToLoadAd:(NSString *)placementName error:(NSError *)error {
    self.failToLoadCalled = YES;
    self.lastPlacementName = placementName;
    self.lastError = error;
    if (self.failToLoadCallback) {
        self.failToLoadCallback();
    }
}

- (void)didClickAd:(CLXAd *)ad {
    self.clickCalled = YES;
    self.lastAd = ad;
}

- (void)didExpandAd:(CLXAd *)ad {
    self.didExpandCalled = YES;
    self.lastAd = ad;
    self.lastExpandedAd = ad;
}

- (void)didCollapseAd:(CLXAd *)ad {
    self.didCollapseCalled = YES;
    self.lastAd = ad;
    self.lastCollapsedAd = ad;
}

- (void)didLoadBanner:(id<CLXAdapterBanner>)banner {
    self.didLoadCalled = YES;
    self.lastBanner = banner;
}

- (void)didFailToLoadBanner:(id<CLXAdapterBanner>)banner error:(NSError *)error {
    self.failToLoadCalled = YES;
    self.lastBanner = banner;
    self.lastError = error;
}

- (void)didShowBanner:(id<CLXAdapterBanner>)banner {
    self.didShowCalled = YES;
    self.lastBanner = banner;
}

- (void)didClickBanner:(id<CLXAdapterBanner>)banner {
    self.clickCalled = YES;
    self.lastBanner = banner;
}

- (void)didExpandBanner:(id<CLXAdapterBanner>)banner {
    self.didExpandCalled = YES;
    self.lastBanner = banner;
}

- (void)didCollapseBanner:(id<CLXAdapterBanner>)banner {
    self.didCollapseCalled = YES;
    self.lastBanner = banner;
}

@end

@implementation MockBannerAdapter

- (instancetype)init {
    return [self initWithID:@"default-test-id"];
}

- (instancetype)initWithID:(NSString *)adapterID {
    self = [super init];
    if (self) {
        _bannerView = [[UIView alloc] init];
        _sdkVersion = @"1.0.0";
        _adapterID = [adapterID copy];
        _shouldFailLoad = NO;
        _loadCalled = NO;
        _showCalled = NO;
        _destroyCalled = NO;
    }
    return self;
}

- (void)load {
    self.loadCalled = YES;
    
    if (self.shouldFailLoad) {
        NSError *error = [NSError errorWithDomain:@"MockError" code:1001 userInfo:@{NSLocalizedDescriptionKey: @"Mock load failure"}];
        if ([self.delegate respondsToSelector:@selector(failToLoadBanner:error:)]) {
            [self.delegate failToLoadBanner:self error:error];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(didLoadBanner:)]) {
            [self.delegate didLoadBanner:self];
        }
    }
}

- (void)showFromViewController:(UIViewController *)viewController {
    self.showCalled = YES;
    if ([self.delegate respondsToSelector:@selector(didShowBanner:)]) {
        [self.delegate didShowBanner:self];
    }
}

- (void)destroy {
    self.destroyCalled = YES;
}

@end

@implementation MockPublisherBanner

- (void)startAutoRefresh {
    self.startAutoRefreshCalled = YES;
}

- (void)stopAutoRefresh {
    self.stopAutoRefreshCalled = YES;
}

- (void)setVisible:(BOOL)visible {
    self.setVisibleCalled = YES;
    self.lastVisibleValue = visible;
}

// CLXBanner protocol methods
- (void)setDelegate:(id<CLXBannerDelegate>)delegate {
    _delegate = delegate;
}

- (void)load {
    // Mock implementation - does nothing
}

- (void)destroy {
    // Mock implementation - does nothing
}

- (BOOL)isDestroyed {
    return NO; // Mock never destroyed
}

@end

#endif // CLXBANNER_MOCKS_IMPLEMENTATION
