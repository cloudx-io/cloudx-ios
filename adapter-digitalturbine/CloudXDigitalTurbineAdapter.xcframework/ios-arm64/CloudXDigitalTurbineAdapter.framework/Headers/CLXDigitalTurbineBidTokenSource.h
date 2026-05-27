//
//  CLXDigitalTurbineBidTokenSource.h
//  CloudXDigitalTurbineAdapter
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXBidTokenSource.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Supplies the Digital Turbine bidding token for OpenRTB auction requests.
 * Token acquisition runs on a background queue to avoid blocking the main
 * thread if the third-party SDK serializes the call internally.
 */
@interface CLXDigitalTurbineBidTokenSource : CLXBidTokenSource

+ (instancetype)sharedInstance;

/**
 * Wire-contract key under which the bidding token is emitted in the token
 * dictionary returned to the CloudX core. The upstream SSP adapter expects
 * this exact key to unmarshal the token from
 * `ext.cloudx.adapter_extras.<network>`; a rename would produce a
 * `BadInputError` at the SSP boundary. Exposed for test-time contract pinning;
 * callers should not depend on it at runtime.
 */
+ (NSString *)tokenDictionaryKey;

@end

NS_ASSUME_NONNULL_END
