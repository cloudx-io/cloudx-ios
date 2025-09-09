//
//  CloudXWKScriptHelper.h
//  CloudXTestVastNetworkAdapter
//
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