//
//  CloudXFullscreenStaticContainerViewController.m
//  CloudXTestVastNetworkAdapter
//
//  Created by bkorda on 07.03.2024.
//

#import "CLXFullscreenStaticContainerViewController.h"
#import "CLXWKScriptHelper.h"
#import <SafariServices/SafariServices.h>

@interface CLXFullscreenStaticContainerViewController () <WKNavigationDelegate, WKUIDelegate>

@property (nonatomic, weak) id<CLXFullscreenStaticContainerViewControllerDelegate> delegate;
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) NSString *adm;
@property (nonatomic, assign) CGFloat topConstant;
@property (nonatomic, assign) CGFloat trailingConstant;

@end

@implementation CLXFullscreenStaticContainerViewController

- (instancetype)initWithDelegate:(id<CLXFullscreenStaticContainerViewControllerDelegate>)delegate
                            adm:(NSString *)adm {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.delegate = delegate;
        self.adm = adm;
        self.topConstant = 12.0;
        self.trailingConstant = 12.0;
        
        self.webView = [[WKWebView alloc] initWithFrame:CGRectZero 
                                          configuration:[CLXWKScriptHelper shared].fullscreenConfiguration];
        self.webView.UIDelegate = self;
        self.webView.navigationDelegate = self;
        
        self.modalPresentationStyle = UIModalPresentationFullScreen;
        [self setupUI];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

#pragma mark - Public Methods

- (void)destroy {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.webView removeFromSuperview];
        self.webView.navigationDelegate = nil;
        self.webView.UIDelegate = nil;
    });
}

- (void)loadHTML {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.webView loadHTMLString:self.adm baseURL:nil];
    });
}

#pragma mark - Private Methods

- (void)setupUI {
    self.closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.closeButton addTarget:self action:@selector(clickClose) forControlEvents:UIControlEventTouchUpInside];
    
    UIImage *image = [UIImage systemImageNamed:@"xmark.circle" 
                            withConfiguration:[UIImageSymbolConfiguration configurationWithFont:[UIFont systemFontOfSize:14] 
                                                                                         scale:UIImageSymbolScaleLarge]];
    [self.closeButton setImage:image forState:UIControlStateNormal];
    
    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    self.closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addSubview:self.webView];
    [self.view addSubview:self.closeButton];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.webView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.webView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.webView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.webView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        
        [self.closeButton.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:self.topConstant],
        [self.closeButton.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-self.trailingConstant]
    ]];
}

- (void)clickClose {
    [self dismissViewControllerAnimated:YES completion:^{
        if ([self.delegate respondsToSelector:@selector(closeFullScreenAd)]) {
            [self.delegate closeFullScreenAd];
        }
    }];
}

@end

#pragma mark - WKNavigationDelegate

@implementation CLXFullscreenStaticContainerViewController (WKNavigationDelegate)

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    if ([self.delegate respondsToSelector:@selector(didLoad)]) {
        [self.delegate didLoad];
    }
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(didFailToShowWithError:)]) {
        [self.delegate didFailToShowWithError:error];
    }
}

@end

#pragma mark - WKUIDelegate

@implementation CLXFullscreenStaticContainerViewController (WKUIDelegate)

- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    if (navigationAction.targetFrame == nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSURL *url = navigationAction.request.URL;
            if (url) {
                if ([self.delegate respondsToSelector:@selector(didClickFullAdd)]) {
                    [self.delegate didClickFullAdd];
                }
                
                SFSafariViewControllerConfiguration *config = [[SFSafariViewControllerConfiguration alloc] init];
                config.entersReaderIfAvailable = YES;
                
                SFSafariViewController *safariVC = [[SFSafariViewController alloc] initWithURL:url configuration:config];
                [self presentViewController:safariVC animated:YES completion:nil];
            }
        });
    }
    return nil;
}

@end 