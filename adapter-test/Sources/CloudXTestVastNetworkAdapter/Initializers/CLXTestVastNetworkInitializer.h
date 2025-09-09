//
//  CloudXTestVastNetworkInitializer.h
//  CloudXTestVastNetworkAdapter
//
//  Created by bkorda on 06.03.2024.
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXTestVastNetworkInitializer : NSObject <CLXAdNetworkInitializer>

+ (instancetype)createInstance;
- (void)initializeWithConfig:(nullable CLXBidderConfig *)config completion:(void (^)(BOOL success, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END 