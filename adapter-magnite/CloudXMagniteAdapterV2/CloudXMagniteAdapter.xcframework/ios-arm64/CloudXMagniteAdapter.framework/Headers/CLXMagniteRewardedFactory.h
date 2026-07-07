//
//  CLXMagniteRewardedFactory.h
//  CloudXMagniteAdapter
//

#import <Foundation/Foundation.h>

#import <CloudXCore/CLXAdapterRewardedFactory.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Factory for creating Magnite rewarded adapters.
 * Implements the CloudX adapter factory protocol for rewarded ads.
 */
@interface CLXMagniteRewardedFactory : CLXAdapterRewardedFactory

/**
 * Factory method to create a new factory instance
 * @return New factory instance
 */
@end

NS_ASSUME_NONNULL_END
