//
//  CLXRendererRewardedFactory.h
//  CloudXRenderer
//
//  CloudX rewarded factory implementation
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXRendererRewardedFactory : NSObject <CLXAdapterRewardedFactory>

+ (instancetype)createInstance;

@end

NS_ASSUME_NONNULL_END 