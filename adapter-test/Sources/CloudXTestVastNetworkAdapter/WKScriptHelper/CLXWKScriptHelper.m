//
//  CloudXWKScriptHelper.m
//  CloudXTestVastNetworkAdapter
//
//  Created by bkorda on 07.03.2024.
//

#import "CLXWKScriptHelper.h"

@interface CLXWKScriptHelper ()

@property (nonatomic, strong) WKWebViewConfiguration *bannerConfiguration;
@property (nonatomic, strong) WKWebViewConfiguration *fullscreenConfiguration;

@end

@implementation CLXWKScriptHelper

+ (instancetype)shared {
    static CLXWKScriptHelper *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupConfigurations];
    }
    return self;
}

#pragma mark - Private Methods

- (void)setupConfigurations {
    _bannerConfiguration = [self createBannerConfiguration];
    _fullscreenConfiguration = [self createFullscreenConfiguration];
}

- (WKWebViewConfiguration *)createBannerConfiguration {
    WKUserContentController *userContentController = [[WKUserContentController alloc] init];
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    configuration.userContentController = userContentController;
    
    [userContentController addUserScript:[self getZoomDisableScript]];
    [userContentController addUserScript:[self marginFixScript]];
    
    return configuration;
}

- (WKWebViewConfiguration *)createFullscreenConfiguration {
    WKUserContentController *userContentController = [[WKUserContentController alloc] init];
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    configuration.userContentController = userContentController;
    
    [userContentController addUserScript:[self marginFixScript]];
    
    return configuration;
}

- (WKUserScript *)getZoomDisableScript {
    NSString *source = @"var meta = document.createElement('meta');meta.setAttribute('name', 'viewport');meta.setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no');document.getElementsByTagName('head')[0].appendChild(meta);";
    return [[WKUserScript alloc] initWithSource:source injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
}

- (WKUserScript *)marginFixScript {
    NSString *cssString = @"body { margin: 0px }";
    NSString *jstring = [NSString stringWithFormat:@"var style = document.createElement('style'); style.innerHTML = '%@'; document.head.appendChild(style)", cssString];
    return [[WKUserScript alloc] initWithSource:jstring injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
}

@end 