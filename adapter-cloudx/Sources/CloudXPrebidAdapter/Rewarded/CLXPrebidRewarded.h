//
//  CLXPrebidRewarded.h
//  CloudXPrebidAdapter
//
//  Prebid 3.0 rewarded ad implementation
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXPrebidRewarded : NSObject <CLXAdapterRewarded>

@property (nonatomic, assign, readonly) BOOL isReady;

- (instancetype)initWithAdm:(NSString *)adm
                      bidID:(NSString *)bidID
                   delegate:(nullable id<CLXAdapterRewardedDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END 