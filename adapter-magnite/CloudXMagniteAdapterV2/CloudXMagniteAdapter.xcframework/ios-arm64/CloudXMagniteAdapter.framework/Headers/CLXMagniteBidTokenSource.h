//
//  CLXMagniteBidTokenSource.h
//  CloudXMagniteAdapter
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXBidTokenSource.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @class CLXMagniteBidTokenSource
 * @brief Provides Magnite bidding tokens for server-side bid requests
 */
@interface CLXMagniteBidTokenSource : CLXBidTokenSource

+ (instancetype)sharedInstance;
@end

NS_ASSUME_NONNULL_END
