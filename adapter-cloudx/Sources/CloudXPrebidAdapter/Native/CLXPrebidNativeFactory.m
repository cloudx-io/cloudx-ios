//
//  CLXPrebidNativeFactory.m
//  CloudXPrebidAdapter
//
//  Prebid 3.0 native factory implementation
//

#import "CLXPrebidNativeFactory.h"
#import "CLXPrebidNative.h"
#import <CloudXCore/CLXLogger.h>

@implementation CLXPrebidNativeFactory

+ (instancetype)createInstance {
    return [[self alloc] init];
}

- (nullable id<CLXAdapterNative>)createWithViewController:(UIViewController *)viewController
                                                                                                               type:(CLXNativeTemplate)type
                                                       adId:(NSString *)adId
                                                      bidId:(NSString *)bidId
                                                        adm:(NSString *)adm
                                                     extras:(NSDictionary<NSString *, NSString *> *)extras
                                                                                                       delegate:(id<CLXAdapterNativeDelegate>)delegate {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CLXPrebidNativeFactory"];
    [logger debug:[NSString stringWithFormat:@"[CLXPrebidNativeFactory] createWithViewController called with adm: %@", adm]];
        return [[CLXPrebidNative alloc] initWithAdm:adm
                                           type:type
                              viewController:viewController
                                   delegate:delegate];
}

@end 