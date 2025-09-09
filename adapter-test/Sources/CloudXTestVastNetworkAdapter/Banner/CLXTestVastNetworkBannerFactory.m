//
//  CloudXTestVastNetworkBannerFactory.m
//  CloudXTestVastNetworkAdapter
//
//  Created by bkorda on 06.03.2024.
//

#import "CLXTestVastNetworkBannerFactory.h"
#import "CLXTestVastNetworkBanner.h"
#import <CloudXCore/CLXLogger.h>

@implementation CLXTestVastNetworkBannerFactory

+ (instancetype)createInstance {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"TestVastNetworkBannerFactory"];
    [logger debug:@"🔧 [TestVastNetworkBannerFactory] createInstance called"];
    CLXTestVastNetworkBannerFactory *instance = [[CLXTestVastNetworkBannerFactory alloc] init];
    [logger info:[NSString stringWithFormat:@"✅ [TestVastNetworkBannerFactory] Instance created: %@", instance]];
    return instance;
}

- (nullable id<CLXAdapterBanner>)createWithViewController:(UIViewController *)viewController
                                                      type:(CLXBannerType)type
                                                      adId:(NSString *)adId
                                                     bidId:(NSString *)bidId
                                                       adm:(NSString *)adm
                                              hasClosedButton:(BOOL)hasClosedButton
                                                     extras:(NSDictionary<NSString *, NSString *> *)extras
                                                   delegate:(id<CLXAdapterBannerDelegate>)delegate {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"TestVastNetworkBannerFactory"];
    [logger debug:@"🔧 [TestVastNetworkBannerFactory] createWithViewController called"];
    [logger debug:[NSString stringWithFormat:@"📊 [TestVastNetworkBannerFactory] ViewController: %@", viewController]];
    [logger debug:[NSString stringWithFormat:@"📊 [TestVastNetworkBannerFactory] Type: %ld", (long)type]];
    [logger debug:[NSString stringWithFormat:@"📊 [TestVastNetworkBannerFactory] AdId: %@", adId]];
    [logger debug:[NSString stringWithFormat:@"📊 [TestVastNetworkBannerFactory] BidId: %@", bidId]];
    [logger debug:[NSString stringWithFormat:@"📊 [TestVastNetworkBannerFactory] Adm: %@", adm]];
    [logger debug:[NSString stringWithFormat:@"📊 [TestVastNetworkBannerFactory] HasClosedButton: %d", hasClosedButton]];
    [logger debug:[NSString stringWithFormat:@"📊 [TestVastNetworkBannerFactory] Extras: %@", extras]];
    [logger debug:[NSString stringWithFormat:@"📊 [TestVastNetworkBannerFactory] Delegate: %@", delegate]];
    
    [logger debug:@"🔧 [TestVastNetworkBannerFactory] Creating CLXTestVastNetworkBanner..."];
    
    CLXTestVastNetworkBanner *banner = [[CLXTestVastNetworkBanner alloc] initWithAdm:adm
                                                                        hasClosedButton:hasClosedButton
                                                                                   type:type
                                                                          viewController:viewController
                                                                               delegate:delegate];
    
    if (banner) {
        [logger info:[NSString stringWithFormat:@"✅ [TestVastNetworkBannerFactory] CLXTestVastNetworkBanner created successfully: %@", banner]];
        [logger debug:[NSString stringWithFormat:@"📊 [TestVastNetworkBannerFactory] Banner class: %@", NSStringFromClass([banner class])]];
        [logger debug:[NSString stringWithFormat:@"📊 [TestVastNetworkBannerFactory] Banner conforms to CLXAdapterBanner: %d", [banner conformsToProtocol:@protocol(CLXAdapterBanner)]]];
        return banner;
    } else {
        [logger error:@"❌ [TestVastNetworkBannerFactory] Failed to create CLXTestVastNetworkBanner"];
        return nil;
    }
}

@end 