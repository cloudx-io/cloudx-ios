//
//  CLXPrebidRewardedFactory.h
//  CloudXPrebidAdapter
//
//  Prebid 3.0 rewarded factory implementation
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXPrebidRewardedFactory : NSObject <CLXAdapterRewardedFactory>

+ (instancetype)createInstance;

@end

NS_ASSUME_NONNULL_END 