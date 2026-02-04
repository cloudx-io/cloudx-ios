//
//  CLXRendererNativeFactory.m
//  CloudXRenderer
//
//  Renderer native factory implementation
//

#import "CLXRendererNativeFactory.h"
#import "CLXRendererNative.h"
#import <CloudXCore/CLXLogger.h>

@implementation CLXRendererNativeFactory

+ (instancetype)createInstance {
    return [[self alloc] init];
}

- (nullable id<CLXAdapterNative>)createWithViewController:(UIViewController *)viewController
                                                                                                               type:(CLXNativeTemplate)type
                                                       adId:(NSString *)adId
                                                      bidId:(NSString *)bidId
                                                        adm:(NSString *)adm
                                                     extras:(NSDictionary<NSString *, NSString *> *)extras
                                                adUnitName:(nullable NSString *)adUnitName
                                                                                                       delegate:(id<CLXAdapterNativeDelegate>)delegate {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CLXRendererNativeFactory"];
    [logger debug:[NSString stringWithFormat:@"Creating native - Ad Unit: %@ (%@), BidID: %@, Type: %ld, Markup: %lu chars",
                  adUnitName ?: @"(unknown)", adId, bidId, (long)type, (unsigned long)(adm ? adm.length : 0)]];
        return [[CLXRendererNative alloc] initWithAdm:adm
                                           type:type
                              viewController:viewController
                                   delegate:delegate];
}

@end 