//
//  CloudXWKScriptHelper.h
//  CloudXTestVastNetworkAdapter
//
//  Created by bkorda on 07.03.2024.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXWKScriptHelper : NSObject

+ (instancetype)shared;

@property (nonatomic, strong, readonly) WKWebViewConfiguration *bannerConfiguration;
@property (nonatomic, strong, readonly) WKWebViewConfiguration *fullscreenConfiguration;

@end

NS_ASSUME_NONNULL_END 