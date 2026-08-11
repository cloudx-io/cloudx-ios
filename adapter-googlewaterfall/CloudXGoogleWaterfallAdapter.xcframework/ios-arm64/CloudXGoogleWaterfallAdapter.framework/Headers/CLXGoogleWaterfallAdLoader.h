#import <Foundation/Foundation.h>
#import "CLXGoogleWaterfallGamSupport.h"

@class GADResponseInfo;
@class GADRequest;
@protocol CLXGoogleWaterfallAdLoader;

NS_ASSUME_NONNULL_BEGIN

@protocol CLXGoogleWaterfallAdLoadCallbacks <NSObject>
- (void)adLoader:(id<CLXGoogleWaterfallAdLoader>)loader
       didLoadAd:(id)ad
    responseInfo:(nullable GADResponseInfo *)responseInfo;
- (void)adLoader:(id<CLXGoogleWaterfallAdLoader>)loader
    didFailWithErrorCode:(NSInteger)code
             errorDomain:(nullable NSString *)domain
            responseInfo:(nullable GADResponseInfo *)responseInfo;
@end

@protocol CLXGoogleWaterfallAdLoader <NSObject>
- (void)loadWithCallbacks:(id<CLXGoogleWaterfallAdLoadCallbacks>)callbacks;
- (void)detachForServe;
- (void)destroy;
@end

NS_ASSUME_NONNULL_END
