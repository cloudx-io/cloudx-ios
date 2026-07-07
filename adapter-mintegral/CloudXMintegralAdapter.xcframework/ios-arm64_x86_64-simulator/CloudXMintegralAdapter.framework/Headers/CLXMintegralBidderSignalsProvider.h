#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdapterBidderSignalsProvider.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXMintegralBidderSignalsProvider : CLXAdapterBidderSignalsProvider

+ (instancetype)sharedInstance;
@end

NS_ASSUME_NONNULL_END
