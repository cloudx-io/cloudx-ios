//
//  CLXInMobiInterstitialFactory.h
//  CloudXInMobiAdapter
//
//  Created by CloudX Team.
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXInMobiInterstitialFactory : NSObject <CLXAdapterInterstitialFactory>

+ (instancetype)createInstance;

@end

NS_ASSUME_NONNULL_END

