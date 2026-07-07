//
//  CLXMagniteAdViewFactory.h
//  CloudXMagniteAdapter
//

#import <Foundation/Foundation.h>

#import <CloudXCore/CLXAdapterAdViewFactory.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Factory for creating Magnite banner adapters.
 * Implements the CloudX adapter factory protocol for banner/MREC ads.
 */
@interface CLXMagniteAdViewFactory : CLXAdapterAdViewFactory

/**
 * Factory method to create a new factory instance
 * @return New factory instance
 */
@end

NS_ASSUME_NONNULL_END
