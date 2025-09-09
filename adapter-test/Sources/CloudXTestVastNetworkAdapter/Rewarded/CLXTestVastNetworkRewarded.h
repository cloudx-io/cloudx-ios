//
//  CloudXTestVastNetworkRewarded.h
//  CloudXTestVastNetworkAdapter
//
//  Created by bkorda on 06.03.2024.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXTestVastNetworkRewarded : NSObject <CLXAdapterRewarded>

@property (nonatomic, assign, readonly) BOOL isReady;

- (instancetype)initWithAdm:(NSString *)adm
                      bidID:(NSString *)bidID
                   delegate:(nullable id<CLXAdapterRewardedDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END 