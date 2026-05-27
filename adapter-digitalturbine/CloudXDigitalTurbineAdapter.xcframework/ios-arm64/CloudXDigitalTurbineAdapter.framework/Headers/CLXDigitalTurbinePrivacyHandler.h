//
//  CLXDigitalTurbinePrivacyHandler.h
//  CloudXDigitalTurbineAdapter
//

#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 * @class CLXDigitalTurbinePrivacyHandler
 * @brief Forwards CloudX-resolved privacy state (GDPR, CCPA, IAB TC string)
 *        to the Digital Turbine SDK.
 *
 * Discovered by `CLXAdapterPrivacyForwarder` via classname convention
 * (`CLX<Network>PrivacyHandler`) and invoked whenever IAB privacy keys in
 * NSUserDefaults change or the publisher calls `CloudXCoreAPI`'s manual
 * privacy setters.
 *
 * The partner SDK auto-reads IAB TCF v2 and GPP from `NSUserDefaults`,
 * but does NOT auto-read the legacy `IABUSPrivacy_String`. CCPA must
 * therefore always be pushed explicitly. GDPR is also always-pushed
 * (set on non-nil, clear on nil) to prevent stale in-memory state from
 * surviving CMP changes within a session.
 */
@interface CLXDigitalTurbinePrivacyHandler : CLXAdapterPrivacyHandler
@end

NS_ASSUME_NONNULL_END
