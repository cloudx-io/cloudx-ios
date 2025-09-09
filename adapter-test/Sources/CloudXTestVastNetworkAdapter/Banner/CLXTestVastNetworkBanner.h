//
//  CloudXTestVastNetworkBanner.h
//  CloudXTestVastNetworkAdapter
//
//  Created by bkorda on 06.03.2024.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXTestVastNetworkBanner : NSObject <CLXAdapterBanner>

@property (nonatomic, weak) id<CLXAdapterBannerDelegate> delegate;

- (instancetype)initWithAdm:(NSString *)adm
             hasClosedButton:(BOOL)hasClosedButton
                        type:(CLXBannerType)type
               viewController:(UIViewController *)viewController
                     delegate:(nullable id<CLXAdapterBannerDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END 