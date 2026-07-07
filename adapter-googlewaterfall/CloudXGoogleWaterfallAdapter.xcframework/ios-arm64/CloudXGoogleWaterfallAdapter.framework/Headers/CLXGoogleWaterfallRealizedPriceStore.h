#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXGoogleWaterfallRealizedPriceStore : NSObject

+ (instancetype)sharedInstance;

- (instancetype)initWithUserDefaults:(NSUserDefaults *)defaults NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (void)storeRealizedEcpm:(double)cpm forAdUnitID:(NSString *)adUnitID;

- (double)realizedEcpmForAdUnitID:(NSString *)adUnitID;

@end

NS_ASSUME_NONNULL_END
