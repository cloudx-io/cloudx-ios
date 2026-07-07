//
//  CLXVungleBidderSignalsProvider.h
//  CloudXVungleAdapter
//

#import <Foundation/Foundation.h>

#import <CloudXCore/CLXAdapterBidderSignalsProvider.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXVungleBidderSignalsProvider : CLXAdapterBidderSignalsProvider

+ (instancetype)sharedInstance;
@end

NS_ASSUME_NONNULL_END
