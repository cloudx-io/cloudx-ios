//
//  CLXVungleAdViewFactory.h
//  CloudXVungleAdapter
//

#import <Foundation/Foundation.h>

#import <CloudXCore/CLXAdapterAdViewFactory.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Factory for creating Vungle banner adapters.
 * Implements the CloudX adapter factory protocol for banner/MREC ads.
 */
@interface CLXVungleAdViewFactory : CLXAdapterAdViewFactory

/**
 * Factory method to create a new factory instance
 * @return New factory instance
 */
@end

NS_ASSUME_NONNULL_END
