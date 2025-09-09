//
//  CloudXTestVastNetworkNativeFactory.m
//  CloudXTestVastNetworkAdapter
//
//  Created by bkorda on 06.04.2024.
//

#import "CLXTestVastNetworkNativeFactory.h"
#import "CLXTestVastNetworkNative.h"
#import <CloudXCore/CLXLogger.h>

@implementation CLXTestVastNetworkNativeFactory

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
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CloudXTestVastNetworkNativeFactory"];
    [logger debug:[NSString stringWithFormat:@"[CloudXTestVastNetworkNativeFactory] createWithViewController called with adm: %@", adm]];
    return [[CLXTestVastNetworkNative alloc] initWithAdm:adm
                                                        type:type
                                               viewController:viewController
                                                    delegate:delegate];
}

@end 