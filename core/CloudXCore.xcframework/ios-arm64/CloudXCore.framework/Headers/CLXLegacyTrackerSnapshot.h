#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/** Per-auction carrier for legacy `;`-positional tracker payload resolution. */
@interface CLXLegacyTrackerSnapshot : NSObject

@property (nonatomic, copy, readonly) NSString *auctionId;     // → bidRequest.id
@property (nonatomic, copy, readonly) NSString *adUnitId;      // → bidRequest.imp.tagid
@property (nonatomic, copy, readonly) NSString *deviceModel;   // → bidRequest.device.model
@property (nonatomic, copy, readonly) NSString *deviceOS;      // → bidRequest.device.os
@property (nonatomic, copy, readonly) NSString *osVersion;     // → bidRequest.device.osv
@property (nonatomic, copy, readonly) NSString *country;       // → bidRequest.device.geo.country
@property (nonatomic, copy, readonly, nullable) NSString *deviceIFV; // → bidRequest.device.ext.ifv
@property (nonatomic, copy, readonly) NSString *deviceIFA;     // → sdk.ifa via handleIfaField

- (instancetype)initWithAuctionId:(NSString *)auctionId
                         adUnitId:(NSString *)adUnitId
                      deviceModel:(NSString *)deviceModel
                         deviceOS:(NSString *)deviceOS
                        osVersion:(NSString *)osVersion
                          country:(NSString *)country
                        deviceIFV:(nullable NSString *)deviceIFV
                        deviceIFA:(NSString *)deviceIFA;

@end

NS_ASSUME_NONNULL_END
