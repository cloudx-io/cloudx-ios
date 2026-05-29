#import <Foundation/Foundation.h>

@class CLXSDKBlock;
@class CLXPrivacyBlock;
@class CLXAdapterMetadata;

NS_ASSUME_NONNULL_BEGIN

/**
 * v2 SDK init request body. Wire shape `{id, sdk, privacy, adapters}` — block field
 * names match server's pkg/bidrequest/v2.SDKBlock and pkg/configpayload/v2.PrivacyBlock
 * verbatim. Adapters[] stays at root — init-only, no analog on bid/telemetry surfaces.
 *
 * Test mode is fully SSP-controlled: the server resolves `deviceConfig.test` from the
 * dashboard's per-device IFA whitelist plus a distribution-based rule keyed off
 * `sdk.appDistribution` (simulator builds get test mode automatically). There is no
 * client-side knob to force test mode from a host app — by design.
 */
@interface CLXSDKConfigRequest : NSObject

@property (nonatomic, copy) NSString *sessionId;
@property (nonatomic, strong) CLXSDKBlock *sdk;
@property (nonatomic, strong) CLXPrivacyBlock *privacy;
@property (nonatomic, strong) NSArray<CLXAdapterMetadata *> *adapters;

- (NSDictionary *)json;

@end

NS_ASSUME_NONNULL_END
