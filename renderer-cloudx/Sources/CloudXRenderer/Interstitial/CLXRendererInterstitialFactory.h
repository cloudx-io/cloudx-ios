//
//  CLXRendererInterstitialFactory.h
//  CloudXRenderer
//
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXRendererInterstitialFactory : NSObject <CLXAdapterInterstitialFactory>

+ (instancetype)createInstance;

@end

NS_ASSUME_NONNULL_END 