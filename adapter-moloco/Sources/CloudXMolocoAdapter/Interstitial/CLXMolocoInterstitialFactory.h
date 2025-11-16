//
//  CLXMolocoInterstitialFactory.h
//  CloudXMolocoAdapter
//
//  Created by CloudX on 2024.
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdapterInterstitialFactory.h>

#if __has_include(<CloudXMolocoAdapter/CLXMolocoBaseFactory.h>)
#import <CloudXMolocoAdapter/CLXMolocoBaseFactory.h>
#else
#import "../Base/CLXMolocoBaseFactory.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface CLXMolocoInterstitialFactory : NSObject <CLXAdapterInterstitialFactory>

+ (instancetype)createInstance;

@end

NS_ASSUME_NONNULL_END

