//
//  CloudXTestVastNetworkRewardedFactory.h
//  CloudXTestVastNetworkAdapter
//
//  Created by bkorda on 07.03.2024.
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXTestVastNetworkRewardedFactory : NSObject <CLXAdapterRewardedFactory>

+ (instancetype)createInstance;

@end

NS_ASSUME_NONNULL_END 