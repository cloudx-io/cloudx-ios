#import <Foundation/Foundation.h>

@class CLXSDKBlock;
@class CLXPrivacyBlock;
@class CLXAdapterMetadata;

NS_ASSUME_NONNULL_BEGIN

/**
 * v2 SDK init request body. Wire shape `{id, sdk, privacy, forceTestMode?, adapters}` — block
 * field names match server's pkg/bidrequest/v2.SDKBlock and pkg/configpayload/v2.PrivacyBlock
 * verbatim. Adapters[] stays at root — init-only, no analog on bid/telemetry surfaces.
 *
 * Test mode is SSP-controlled: the server resolves `deviceConfig.test` from the dashboard's
 * per-device IFA whitelist, a distribution rule keyed off `sdk.appDistribution` (simulator builds
 * get test mode automatically) and the account setting. A host app has no knob for it.
 *
 * The one exception is `forceTestMode`, and only the Mediation Debugger sets it: someone tapped
 * `Test Mode Enabled` on this device, and the next initialization sends that request once and then
 * forgets it. The server ranks it below the simulator and public-demo rules and above the account
 * setting.
 *
 * History, so this is not removed a second time. Test mode was a public init parameter in
 * 5076048cc, then a sticky `CLXCore_forceTestModeBeforeInit` defaults key read on every launch, and
 * both were dropped in 73cd45a90 because only internal QA tooling used them. The debugger is that
 * tooling, and its request differs where it mattered: it is enable only, it lives in the SDK's own
 * defaults suite rather than the host's, only the SDK's own init service sends it, through an
 * internal method, and the one initialization it applies to consumes it (`CLXTestModeRequestStore`).
 */
@interface CLXSDKConfigRequest : NSObject

@property (nonatomic, copy) NSString *sessionId;
@property (nonatomic, strong) CLXSDKBlock *sdk;
@property (nonatomic, strong) CLXPrivacyBlock *privacy;
@property (nonatomic, strong) NSArray<CLXAdapterMetadata *> *adapters;

- (NSDictionary *)json;

@end

NS_ASSUME_NONNULL_END
