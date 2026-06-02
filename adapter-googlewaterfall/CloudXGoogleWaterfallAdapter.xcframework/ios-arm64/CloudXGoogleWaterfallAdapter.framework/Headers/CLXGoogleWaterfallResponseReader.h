#import <Foundation/Foundation.h>

@class GADResponseInfo;

NS_ASSUME_NONNULL_BEGIN

@interface CLXGoogleWaterfallExtractedFill : NSObject
@property (nonatomic, copy, readonly) NSArray<NSString *> *probesTriggered;
@property (nonatomic, copy, readonly, nullable) NSString *winnerSourceName;
@property (nonatomic, copy, readonly, nullable) NSString *winnerInstanceName;
@property (nonatomic, copy, readonly, nullable) NSString *mediationGroupName;

- (instancetype)initWithProbesTriggered:(NSArray<NSString *> *)probesTriggered
                       winnerSourceName:(nullable NSString *)winnerSourceName
                     winnerInstanceName:(nullable NSString *)winnerInstanceName
                     mediationGroupName:(nullable NSString *)mediationGroupName NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

@interface CLXGoogleWaterfallResponseReader : NSObject

+ (CLXGoogleWaterfallExtractedFill *)extractFromResponseInfo:(nullable GADResponseInfo *)info;

+ (CLXGoogleWaterfallExtractedFill *)extractFromInstanceNames:(nullable NSArray<NSString *> *)instanceNames
                                            winnerSourceName:(nullable NSString *)winnerSourceName
                                          winnerInstanceName:(nullable NSString *)winnerInstanceName
                                          mediationGroupName:(nullable NSString *)mediationGroupName;

@end

NS_ASSUME_NONNULL_END
