#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdapterInterstitialFactory.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXMintegralInterstitialFactory : NSObject <CLXAdapterInterstitialFactory>

+ (instancetype)createInstance;

@end

NS_ASSUME_NONNULL_END

