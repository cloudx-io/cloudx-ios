//
//  CLXRendererInterstitialFactory.m
//  CloudXRenderer
//
//  Renderer interstitial factory implementation
//

#import "CLXRendererInterstitialFactory.h"
#import "CLXRendererInterstitial.h"

@implementation CLXRendererInterstitialFactory

+ (instancetype)createInstance {
    return [[self alloc] init];
}

- (nullable id<CLXAdapterInterstitial>)createWithAdId:(NSString *)adId
                                                   bidId:(NSString *)bidId
                                                     adm:(NSString *)adm
                                                   extras:(NSDictionary<NSString *, NSString *> *)extras
                                                 delegate:(id<CLXAdapterInterstitialDelegate>)delegate {
    return [[CLXRendererInterstitial alloc] initWithAdm:adm
                                                  bidID:bidId
                                                delegate:delegate];
}

@end 