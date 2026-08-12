//
//  CLXUnityAdsBidderSignalsProvider.h
//  CloudXUnityAdsAdapter
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdapterBidderSignalsProvider.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXUnityAdsBidderSignalsProvider : CLXAdapterBidderSignalsProvider

+ (instancetype)sharedInstance;
@end

NS_ASSUME_NONNULL_END
