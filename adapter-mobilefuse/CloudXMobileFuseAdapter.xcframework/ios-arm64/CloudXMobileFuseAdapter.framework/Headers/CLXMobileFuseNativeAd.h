//
//  CLXMobileFuseNativeAd.h
//  CloudXMobileFuseAdapter
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXNativeAd.h>
#import <CloudXCore/CLXAdapterLogger.h>

@class MFNativeAd;
@protocol CLXAdapterNativeDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface CLXMobileFuseNativeAd : CLXNativeAd

@property (nonatomic, strong, nullable) MFNativeAd *mobileFuseNativeAd;
@property (nonatomic, weak, nullable) id<CLXAdapterNativeDelegate> adapterDelegate;

- (instancetype)initWithMobileFuseNativeAd:(MFNativeAd *)mobileFuseNativeAd
                      localExtraParameters:(nullable NSDictionary<NSString *, id> *)localExtraParameters
                            logger:(id<CLXAdapterLogger>)logger;

@end

NS_ASSUME_NONNULL_END
