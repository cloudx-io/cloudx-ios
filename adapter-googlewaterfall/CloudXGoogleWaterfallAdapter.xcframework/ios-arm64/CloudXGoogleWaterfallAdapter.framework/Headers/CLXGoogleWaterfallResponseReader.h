#import <Foundation/Foundation.h>

@class GADResponseInfo;

NS_ASSUME_NONNULL_BEGIN

@interface CLXGoogleWaterfallExtractedFill : NSObject
@property (nonatomic, copy, readonly, nullable) NSString *winnerSourceName;
@property (nonatomic, copy, readonly, nullable) NSString *winnerInstanceName;
@property (nonatomic, copy, readonly, nullable) NSString *mediationGroupName;
@property (nonatomic, copy, readonly, nullable) NSString *creativeId;
@property (nonatomic, copy, readonly, nullable) NSString *responseId;

- (instancetype)initWithWinnerSourceName:(nullable NSString *)winnerSourceName
                      winnerInstanceName:(nullable NSString *)winnerInstanceName
                      mediationGroupName:(nullable NSString *)mediationGroupName
                              creativeId:(nullable NSString *)creativeId
                              responseId:(nullable NSString *)responseId NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

@interface CLXGoogleWaterfallResponseReader : NSObject

+ (CLXGoogleWaterfallExtractedFill *)extractFromResponseInfo:(nullable GADResponseInfo *)info;

+ (CLXGoogleWaterfallExtractedFill *)extractFromWinnerSourceName:(nullable NSString *)winnerSourceName
                                              winnerInstanceName:(nullable NSString *)winnerInstanceName
                                              mediationGroupName:(nullable NSString *)mediationGroupName
                                                      creativeId:(nullable NSString *)creativeId
                                                      responseId:(nullable NSString *)responseId;

@end

NS_ASSUME_NONNULL_END
