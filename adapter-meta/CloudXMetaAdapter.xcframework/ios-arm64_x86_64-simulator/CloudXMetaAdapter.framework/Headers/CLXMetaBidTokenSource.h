//
//  CLXMetaBidTokenSource.h
//  CloudXMetaAdapter
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXBidTokenSource.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Provides Meta's bid token for OpenRTB auction requests.
 * The token enables privacy compliance (GDPR/CCPA) and bid request validation.
 */
@interface CLXMetaBidTokenSource : NSObject <CLXBidTokenSource>

+ (instancetype)sharedInstance;
+ (instancetype)createInstance;

@end

NS_ASSUME_NONNULL_END
