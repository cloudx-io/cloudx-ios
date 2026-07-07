#import <CloudXCore/CLXAdapterRewarded.h>
#import <CloudXCore/CLXAdapterRewardedFactory.h>
#import <CloudXCore/CLXAdapterRewardedParams.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXGoogleWaterfallRewardedFactory : CLXAdapterRewardedFactory

- (nullable CLXAdapterRewarded *)createWithParams:(CLXAdapterRewardedParams *)params;

@end

NS_ASSUME_NONNULL_END
