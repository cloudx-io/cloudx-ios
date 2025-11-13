//
//  CLXRendererRewardedFactory.m
//  CloudXRenderer
//
//  Renderer rewarded factory implementation
//

#import "CLXRendererRewardedFactory.h"
#import "CLXRendererRewarded.h"

@implementation CLXRendererRewardedFactory

+ (instancetype)createInstance {
    return [[self alloc] init];
}

- (nullable id<CLXAdapterRewarded>)createWithAdId:(NSString *)adId
                                               bidId:(NSString *)bidId
                                                 adm:(NSString *)adm
                                              extras:(NSDictionary<NSString *, NSString *> *)extras
                                            delegate:(id<CLXAdapterRewardedDelegate>)delegate {
        return [[CLXRendererRewarded alloc] initWithAdm:adm
                                             bidID:bidId
                                           delegate:delegate];
}

@end 