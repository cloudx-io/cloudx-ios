//
//  CLXMolocoRewardedFactory.h
//  CloudXMolocoAdapter
//
//  Created by CloudX on 2024.
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdapterRewardedFactory.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXMolocoRewardedFactory : NSObject <CLXAdapterRewardedFactory>

+ (instancetype)createInstance;

@end

NS_ASSUME_NONNULL_END

