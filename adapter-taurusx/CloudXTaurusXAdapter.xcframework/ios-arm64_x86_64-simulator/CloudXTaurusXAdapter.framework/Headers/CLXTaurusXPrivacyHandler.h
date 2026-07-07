//
//  CLXTaurusXPrivacyHandler.h
//  CloudXTaurusXAdapter
//

#import <CloudXCore/CLXAdapterPrivacyHandler.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @class CLXTaurusXPrivacyHandler
 * @brief Forwards CloudX-resolved privacy state (GDPR, CCPA) to the TaurusX SDK.
 *
 * Discovered by `CLXAdapterPrivacyForwarder` via the classname convention
 * (`CLX<Network>PrivacyHandler`) and `isSubclassOfClass:` — so it MUST subclass
 * `CLXAdapterPrivacyHandler`. Invoked whenever IAB privacy keys in NSUserDefaults
 * change or the publisher calls a manual privacy setter.
 *
 * TaurusX exposes binary integer privacy levels, so the handler maps CloudX's
 * resolved nullable consent values to the SDK values when privacy changes.
 */
@interface CLXTaurusXPrivacyHandler : CLXAdapterPrivacyHandler
@end

NS_ASSUME_NONNULL_END
