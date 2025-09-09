//
//  CloudXAdNetworkInitializer.h
//  CloudXCore
//
//  Created by CloudX Team.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXBidderConfig;

/// Protocol for initializing ad network SDKs.
@protocol CLXAdNetworkInitializer <NSObject>

/// Flag to indicate if the ad network SDK is initialized.
+ (BOOL)isInitialized;

/// Creates an instance of the initializer.
+ (instancetype)createInstance;

/// CloudX SDK call this method to initialize the ad network SDK.
/// - Parameter config: configuration for the ad network SDK such as app id, ad unit id
/// - Returns: true if the initialization was successful, false otherwise
- (void)initializeWithConfig:(nullable CLXBidderConfig *)config 
                  completion:(void (^)(BOOL success, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END 