//
//  CLXMolocoBannerFactory.h
//  CloudXMolocoAdapter
//
//  Created by CloudX on 2024.
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdapterBannerFactory.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXMolocoBannerFactory : NSObject <CLXAdapterBannerFactory>

+ (instancetype)createInstance;

@end

NS_ASSUME_NONNULL_END

