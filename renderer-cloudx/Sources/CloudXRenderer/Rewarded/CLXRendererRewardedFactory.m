//
//  CLXRendererRewardedFactory.m
//  CloudXRenderer
//
//  Renderer rewarded factory implementation
//

#import "CLXRendererRewardedFactory.h"
#import "CLXRendererRewarded.h"
#import <CloudXCore/CLXLogger.h>

@implementation CLXRendererRewardedFactory

+ (instancetype)createInstance {
    return [[self alloc] init];
}

- (nullable id<CLXAdapterRewarded>)createWithAdId:(NSString *)adId
                                               bidId:(NSString *)bidId
                                                 adm:(NSString *)adm
                                              extras:(NSDictionary<NSString *, NSString *> *)extras
                                          adUnitName:(nullable NSString *)adUnitName
                                            delegate:(id<CLXAdapterRewardedDelegate>)delegate {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CLXRendererRewardedFactory"];
    [logger debug:[NSString stringWithFormat:@"Creating rewarded - Ad Unit: %@ (%@), BidID: %@, Markup: %lu chars",
                  adUnitName ?: @"(unknown)", adId, bidId, (unsigned long)(adm ? adm.length : 0)]];
    
    return [[CLXRendererRewarded alloc] initWithAdm:adm
                                             bidID:bidId
                                           delegate:delegate];
}

@end 