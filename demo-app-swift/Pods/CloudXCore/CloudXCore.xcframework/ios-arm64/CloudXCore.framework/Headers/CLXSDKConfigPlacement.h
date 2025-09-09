//
// SDKConfigPlacement.h
// CloudXCore
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXNativeTemplate.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, SDKConfigAdType) {
    SDKConfigAdTypeBanner = 0,
    SDKConfigAdTypeMrec,
    SDKConfigAdTypeInterstitial,
    SDKConfigAdTypeRewarded,
    SDKConfigAdTypeUnknown
};

@interface CLXSDKConfigPlacement : NSObject

@property (nonatomic, copy) NSString *id;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) int64_t bidResponseTimeoutMs;
@property (nonatomic, assign) int64_t adLoadTimeoutMs;
@property (nonatomic, assign) int64_t bannerRefreshRateMs;
@property (nonatomic, assign) SDKConfigAdType type;
@property (nonatomic, assign) BOOL hasCloseButton;
@property (nonatomic, copy, nullable) NSString *firstImpressionPlacementSuffix;
@property (nonatomic, assign) NSInteger firstImpressionLoopIndexStart;
@property (nonatomic, assign) NSInteger firstImpressionLoopIndexEnd;
@property (nonatomic, assign) CLXNativeTemplate nativeTemplate;
@property (nonatomic, copy, nullable) NSString *dealId;
@property (nonatomic, copy, nullable) NSArray<id> *line_items;

- (instancetype)init;
- (NSString *)ilrdDescription;

@end

NS_ASSUME_NONNULL_END 