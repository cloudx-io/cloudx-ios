//
//  CLXRendererInterstitialFactory.m
//  CloudXRenderer
//
//  Renderer interstitial factory implementation
//

#import "CLXRendererInterstitialFactory.h"
#import "CLXRendererInterstitial.h"
#import <CloudXCore/CLXLogger.h>

@implementation CLXRendererInterstitialFactory

+ (instancetype)createInstance {
    return [[self alloc] init];
}

- (nullable id<CLXAdapterInterstitial>)createWithAdId:(NSString *)adId
                                                   bidId:(NSString *)bidId
                                                     adm:(NSString *)adm
                                                   extras:(NSDictionary<NSString *, NSString *> *)extras
                                              adUnitName:(nullable NSString *)adUnitName
                                                 delegate:(id<CLXAdapterInterstitialDelegate>)delegate {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CLXRendererInterstitialFactory"];
    [logger debug:[NSString stringWithFormat:@"Creating interstitial - Ad Unit: %@ (%@), BidID: %@, Markup: %lu chars",
                  adUnitName ?: @"(unknown)", adId, bidId, (unsigned long)(adm ? adm.length : 0)]];
    
    return [[CLXRendererInterstitial alloc] initWithAdm:adm
                                                  bidID:bidId
                                                delegate:delegate];
}

@end 