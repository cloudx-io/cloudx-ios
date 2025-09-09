//
//  CLXPrebidInitializer.h
//  CloudXPrebidAdapter
//
//  Prebid 3.0 adapter initializer
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXPrebidInitializer : NSObject <CLXAdNetworkInitializer>

+ (instancetype)createInstance;
- (void)initializeWithConfig:(nullable CLXBidderConfig *)config completion:(void (^)(BOOL success, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END 