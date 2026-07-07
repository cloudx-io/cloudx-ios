//
//  CLXMetaBidderSignalsProvider.h
//  CloudXMetaAdapter
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdapterBidderSignalsProvider.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Provides Meta's bid token for OpenRTB auction requests.
 * The token enables privacy compliance (GDPR/CCPA) and bid request validation.
 */
@interface CLXMetaBidderSignalsProvider : CLXAdapterBidderSignalsProvider

+ (instancetype)sharedInstance;
@end

NS_ASSUME_NONNULL_END
