#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXRillImpressionDefaultModel : NSObject

@property (nonatomic, copy) NSString *bidder;
@property (nonatomic) NSInteger width;
@property (nonatomic) NSInteger height;
@property (nonatomic, copy, nullable) NSString *dealId;
@property (nonatomic, copy) NSString *creativeId;
@property (nonatomic, strong, nullable) NSNumber *cpmMicros;
@property (nonatomic, strong, nullable) NSNumber *responseTimeMillis;
@property (nonatomic, copy) NSString *releaseVersion;
@property (nonatomic, copy, nullable) NSString *auctionId;
@property (nonatomic, copy) NSString *accountId;
@property (nonatomic, copy) NSString *organizationId;
@property (nonatomic, copy) NSString *applicationId;
@property (nonatomic, copy) NSString *placementId;
@property (nonatomic, copy) NSString *deviceName;
@property (nonatomic, copy) NSString *deviceType;
@property (nonatomic, copy) NSString *osName;
@property (nonatomic, copy) NSString *osVersion;
@property (nonatomic, copy) NSString *sessionId;
@property (nonatomic, copy) NSString *ifa;
@property (nonatomic) NSInteger loopIndex;
@property (nonatomic, copy) NSString *testGroupName;

- (NSString *)createParamString;

@end

NS_ASSUME_NONNULL_END 