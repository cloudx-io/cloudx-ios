#import <Foundation/Foundation.h>
#import "CLXGoogleWaterfallAdLoader.h"

@class GADRequest;

NS_ASSUME_NONNULL_BEGIN

@interface CLXGoogleWaterfallFullscreenLoader : NSObject <CLXGoogleWaterfallAdLoader>
- (instancetype)initWithAdUnitId:(NSString *)adUnitId
                       loadBlock:(void (^)(NSString *adUnitId, GADRequest *request,
                                           void (^completion)(id _Nullable ad, NSError *_Nullable error)))loadBlock
    NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
