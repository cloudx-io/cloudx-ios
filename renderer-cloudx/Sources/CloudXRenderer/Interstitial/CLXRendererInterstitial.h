//
//  CLXRendererInterstitial.h
//  CloudXRenderer
//
//  CloudX interstitial ad renderer implementation
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXRendererInterstitial : NSObject <CLXAdapterInterstitial>

- (instancetype)initWithAdm:(NSString *)adm
                      bidID:(NSString *)bidID
                   delegate:(nullable id<CLXAdapterInterstitialDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END 