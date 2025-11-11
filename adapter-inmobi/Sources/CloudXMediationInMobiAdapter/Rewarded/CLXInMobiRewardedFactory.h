//
//  CLXInMobiRewardedFactory.h
//  CloudXMediationInMobiAdapter
//
//  Created by CloudX Team.
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CloudXCore.h>

@class CLXLogger;

NS_ASSUME_NONNULL_BEGIN

@interface CLXInMobiRewardedFactory : NSObject <CLXAdapterRewardedFactory>

+ (instancetype)createInstance;

@end

NS_ASSUME_NONNULL_END

