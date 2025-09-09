//
//  CloudXTestVastNetworkBanner.m
//  CloudXTestVastNetworkAdapter
//
//  Created by bkorda on 06.03.2024.
//

#import "CLXTestVastNetworkBanner.h"
#import "CLXWKScriptHelper.h"
#import <SafariServices/SafariServices.h>
#import <CloudXCore/CLXLogger.h>

@interface CLXTestVastNetworkBanner () <WKNavigationDelegate, WKUIDelegate>

@property (nonatomic, strong) NSString *adm;
@property (nonatomic, strong) UIViewController *viewController;
@property (nonatomic, assign) CLXBannerType type;
@property (nonatomic, assign) BOOL hasClosedButton;
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UIButton *closeButton;

@end

@implementation CLXTestVastNetworkBanner

@synthesize delegate;
@synthesize timeout;

- (instancetype)initWithAdm:(NSString *)adm
             hasClosedButton:(BOOL)hasClosedButton
                        type:(CLXBannerType)type
               viewController:(UIViewController *)viewController
                     delegate:(id<CLXAdapterBannerDelegate>)delegate {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"TestVastNetworkBanner"];
    [logger debug:@"🔧 [TestVastNetworkBanner] initWithAdm called"];
    [logger debug:[NSString stringWithFormat:@"📊 [TestVastNetworkBanner] Adm: %@", adm]];
    [logger debug:[NSString stringWithFormat:@"📊 [TestVastNetworkBanner] HasClosedButton: %d", hasClosedButton]];
    [logger debug:[NSString stringWithFormat:@"📊 [TestVastNetworkBanner] Type: %ld", (long)type]];
    [logger debug:[NSString stringWithFormat:@"📊 [TestVastNetworkBanner] ViewController: %@", viewController]];
    [logger debug:[NSString stringWithFormat:@"📊 [TestVastNetworkBanner] Delegate: %@", delegate]];
    
    self = [super init];
    if (self) {
        [logger info:@"✅ [TestVastNetworkBanner] Super init successful"];
        self.delegate = delegate;
        self.adm = adm;
        self.viewController = viewController;
        self.type = type;
        self.hasClosedButton = hasClosedButton;
        
        [logger debug:@"📊 [TestVastNetworkBanner] Properties set:"];
        [logger debug:[NSString stringWithFormat:@"📊 [TestVastNetworkBanner] - delegate: %@", self.delegate]];
        [logger debug:[NSString stringWithFormat:@"📊 [TestVastNetworkBanner] - adm: %@", self.adm]];
        [logger debug:[NSString stringWithFormat:@"📊 [TestVastNetworkBanner] - viewController: %@", self.viewController]];
        [logger debug:[NSString stringWithFormat:@"📊 [TestVastNetworkBanner] - type: %ld", (long)self.type]];
        [logger debug:[NSString stringWithFormat:@"📊 [TestVastNetworkBanner] - hasClosedButton: %d", self.hasClosedButton]];
        
        // UI setup must be performed on the main thread.
        dispatch_sync(dispatch_get_main_queue(), ^{
            self.closeButton = [UIButton buttonWithType:UIButtonTypeClose];
            self.closeButton.translatesAutoresizingMaskIntoConstraints = NO;
            [logger info:@"✅ [TestVastNetworkBanner] Close button created"];
        });
    } else {
        [logger error:@"❌ [TestVastNetworkBanner] Super init failed"];
    }
    
    [logger info:[NSString stringWithFormat:@"✅ [TestVastNetworkBanner] initWithAdm completed: %@", self]];
    return self;
}

#pragma mark - CLXAdapterBanner

- (UIView *)bannerView {
    return self.webView;
}

- (NSString *)sdkVersion {
    return @"1.0.0";
}

- (void)load {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"TestVastNetworkBanner"];
    [logger debug:@"🚀 [TestVastNetworkBanner] load() called"];
    [logger debug:[NSString stringWithFormat:@"📊 [TestVastNetworkBanner] Current thread: %@", [NSThread currentThread]]];
    [logger debug:[NSString stringWithFormat:@"📊 [TestVastNetworkBanner] Adm: %@", self.adm]];
    [logger debug:[NSString stringWithFormat:@"📊 [TestVastNetworkBanner] Type: %ld", (long)self.type]];
    [logger debug:[NSString stringWithFormat:@"📊 [TestVastNetworkBanner] HasClosedButton: %d", self.hasClosedButton]];
    [logger debug:[NSString stringWithFormat:@"📊 [TestVastNetworkBanner] ViewController: %@", self.viewController]];
    [logger debug:[NSString stringWithFormat:@"📊 [TestVastNetworkBanner] Delegate: %@", self.delegate]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [logger debug:@"🔧 [TestVastNetworkBanner] Starting banner load on main queue"];
        
        CGSize bannerSize = [self getBannerSizeForType:self.type];
        [logger debug:[NSString stringWithFormat:@"📊 [TestVastNetworkBanner] Banner size: %@", NSStringFromCGSize(bannerSize)]];
        
        CGRect frame = CGRectMake(0, 0, bannerSize.width, bannerSize.height);
        [logger debug:[NSString stringWithFormat:@"📊 [TestVastNetworkBanner] Frame: %@", NSStringFromCGRect(frame)]];
        
        [logger debug:@"🔧 [TestVastNetworkBanner] Creating WKWebView..."];
        self.webView = [[WKWebView alloc] initWithFrame:frame 
                                          configuration:[CLXWKScriptHelper shared].bannerConfiguration];
        
        if (self.webView) {
            [logger info:[NSString stringWithFormat:@"✅ [TestVastNetworkBanner] WKWebView created successfully: %@", self.webView]];
            self.webView.UIDelegate = self;
            self.webView.navigationDelegate = self;
            self.webView.scrollView.scrollEnabled = NO;
            
            NSString *style = @"<style>img{display:inline-block;max-width:100%;height:auto;}</style>";
            NSString *htmlString = [NSString stringWithFormat:@"%@%@", style, self.adm];
            
            [logger debug:[NSString stringWithFormat:@"🔧 [TestVastNetworkBanner] Loading HTML string: %@", htmlString]];
            [self.webView loadHTMLString:htmlString baseURL:nil];
            
            if (@available(iOS 16.4, *)) {
                self.webView.inspectable = YES;
                [logger debug:@"📊 [TestVastNetworkBanner] WebView inspectable enabled"];
            }
            
            if (self.hasClosedButton) {
                [logger debug:@"🔧 [TestVastNetworkBanner] Adding close button..."];
                [self.closeButton addTarget:self action:@selector(closeBanner:) forControlEvents:UIControlEventTouchUpInside];
                [self.webView addSubview:self.closeButton];
                
                [NSLayoutConstraint activateConstraints:@[
                    [self.webView.trailingAnchor constraintEqualToAnchor:self.closeButton.trailingAnchor],
                    [self.webView.topAnchor constraintEqualToAnchor:self.closeButton.topAnchor]
                ]];
                [logger info:@"✅ [TestVastNetworkBanner] Close button added and constrained"];
            } else {
                [logger debug:@"📊 [TestVastNetworkBanner] No close button needed"];
            }
            
            [logger info:@"✅ [TestVastNetworkBanner] Banner load setup completed"];
        } else {
            [logger error:@"❌ [TestVastNetworkBanner] Failed to create WKWebView"];
        }
    });
}

- (void)showFromViewController:(UIViewController *)viewController {
    // Banner is already shown when loaded, this method is called for consistency
    if ([self.delegate respondsToSelector:@selector(didShowBanner:)]) {
        [self.delegate didShowBanner:self];
    }
}

- (void)destroy {
    [self.webView removeFromSuperview];
    self.webView.UIDelegate = nil;
    self.webView.navigationDelegate = nil;
    self.webView = nil;
}

#pragma mark - Private Methods

- (void)closeBanner:(UIButton *)sender {
    [self destroy];
    if ([self.delegate respondsToSelector:@selector(closedByUserActionBanner:)]) {
        [self.delegate closedByUserActionBanner:self];
    }
}

// Helper method to get size for banner type
- (CGSize)getBannerSizeForType:(CLXBannerType)type {
    switch (type) {
        case CLXBannerTypeMREC:
            return CGSizeMake(300, 250);
        default:
            return CGSizeMake(320, 50);
    }
}

@end

#pragma mark - WKNavigationDelegate

@implementation CLXTestVastNetworkBanner (WKNavigationDelegate)

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"TestVastNetworkBanner"];
    [logger info:@"✅ [TestVastNetworkBanner] webView:didFinishNavigation called"];
    [logger debug:[NSString stringWithFormat:@"📊 [TestVastNetworkBanner] WebView: %@", webView]];
    [logger debug:[NSString stringWithFormat:@"📊 [TestVastNetworkBanner] Navigation: %@", navigation]];
    [logger debug:[NSString stringWithFormat:@"📊 [TestVastNetworkBanner] Delegate: %@", self.delegate]];
    
    [logger debug:@"🔧 [TestVastNetworkBanner] Calling delegate didLoadBanner..."];
    if ([self.delegate respondsToSelector:@selector(didLoadBanner:)]) {
        [logger info:@"✅ [TestVastNetworkBanner] Delegate responds to didLoadBanner, calling..."];
        [self.delegate didLoadBanner:self];
    } else {
        [logger debug:@"⚠️ [TestVastNetworkBanner] Delegate does not respond to didLoadBanner"];
    }
    
    [logger debug:@"🔧 [TestVastNetworkBanner] Calling delegate didShowBanner..."];
    if ([self.delegate respondsToSelector:@selector(didShowBanner:)]) {
        [logger info:@"✅ [TestVastNetworkBanner] Delegate responds to didShowBanner, calling..."];
        [self.delegate didShowBanner:self];
    } else {
        [logger debug:@"⚠️ [TestVastNetworkBanner] Delegate does not respond to didShowBanner"];
    }
    
    [logger debug:@"🔧 [TestVastNetworkBanner] Calling delegate impressionBanner..."];
    if ([self.delegate respondsToSelector:@selector(impressionBanner:)]) {
        [logger info:@"✅ [TestVastNetworkBanner] Delegate responds to impressionBanner, calling..."];
        [self.delegate impressionBanner:self];
    } else {
        [logger debug:@"⚠️ [TestVastNetworkBanner] Delegate does not respond to impressionBanner"];
    }
    
    [logger info:@"✅ [TestVastNetworkBanner] webView:didFinishNavigation completed"];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"TestVastNetworkBanner"];
    [logger error:@"❌ [TestVastNetworkBanner] webView:didFailNavigation called"];
    [logger debug:[NSString stringWithFormat:@"📊 [TestVastNetworkBanner] WebView: %@", webView]];
    [logger debug:[NSString stringWithFormat:@"📊 [TestVastNetworkBanner] Navigation: %@", navigation]];
    [logger debug:[NSString stringWithFormat:@"📊 [TestVastNetworkBanner] Error: %@", error]];
    [logger debug:[NSString stringWithFormat:@"📊 [TestVastNetworkBanner] Error domain: %@", error.domain]];
    [logger debug:[NSString stringWithFormat:@"📊 [TestVastNetworkBanner] Error code: %ld", (long)error.code]];
    [logger debug:[NSString stringWithFormat:@"📊 [TestVastNetworkBanner] Error description: %@", error.localizedDescription]];
    [logger debug:[NSString stringWithFormat:@"📊 [TestVastNetworkBanner] Error user info: %@", error.userInfo]];
    
    [logger debug:@"🔧 [TestVastNetworkBanner] Calling delegate failToLoadBanner..."];
    if ([self.delegate respondsToSelector:@selector(failToLoadBanner:error:)]) {
        [logger info:@"✅ [TestVastNetworkBanner] Delegate responds to failToLoadBanner:error:, calling..."];
        [self.delegate failToLoadBanner:self error:error];
    } else {
        [logger debug:@"⚠️ [TestVastNetworkBanner] Delegate does not respond to failToLoadBanner:error:"];
    }
    
    [logger info:@"✅ [TestVastNetworkBanner] webView:didFailNavigation completed"];
}

@end

#pragma mark - WKUIDelegate

@implementation CLXTestVastNetworkBanner (WKUIDelegate)

- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    if (navigationAction.targetFrame == nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSURL *url = navigationAction.request.URL;
            if (url) {
                if ([self.delegate respondsToSelector:@selector(clickBanner:)]) {
                    [self.delegate clickBanner:self];
                }
                
                SFSafariViewControllerConfiguration *config = [[SFSafariViewControllerConfiguration alloc] init];
                config.entersReaderIfAvailable = YES;
                
                SFSafariViewController *safariVC = [[SFSafariViewController alloc] initWithURL:url configuration:config];
                [self.viewController presentViewController:safariVC animated:YES completion:nil];
            }
        });
    }
    return nil;
}

@end 