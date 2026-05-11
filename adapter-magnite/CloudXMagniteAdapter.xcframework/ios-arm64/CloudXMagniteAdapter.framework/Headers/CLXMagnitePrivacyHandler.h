//
//  CLXMagnitePrivacyHandler.h
//  CloudXMagniteAdapter
//

#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 * @class CLXMagnitePrivacyHandler
 * @brief Forwards publisher-set privacy settings to the Magnite SDK
 */
@interface CLXMagnitePrivacyHandler : CLXAdapterPrivacyHandler
@end

NS_ASSUME_NONNULL_END
