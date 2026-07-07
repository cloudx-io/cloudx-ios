#import <Foundation/Foundation.h>
#import "CLXGoogleWaterfallAdLoader.h"

NS_ASSUME_NONNULL_BEGIN

@interface CLXGoogleWaterfallNativeLoader : NSObject <CLXGoogleWaterfallAdLoader>
- (instancetype)initWithAdUnitId:(NSString *)adUnitId NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
