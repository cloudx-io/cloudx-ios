//
//  CLXPangleBidderSignalsProvider.h
//  CloudXPangleAdapter
//

#import <Foundation/Foundation.h>

#import <CloudXCore/CLXAdapterBidderSignalsProvider.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXPangleBidderSignalsProvider : CLXAdapterBidderSignalsProvider

+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END
