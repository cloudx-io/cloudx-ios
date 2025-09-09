//
//  CLXPrebidInterstitial.h
//  CloudXPrebidAdapter
//
//  Prebid 3.0 interstitial ad implementation
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXPrebidInterstitial : NSObject <CLXAdapterInterstitial>

- (instancetype)initWithAdm:(NSString *)adm
                      bidID:(NSString *)bidID
                   delegate:(nullable id<CLXAdapterInterstitialDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END 