//
// CLXSdkConfiguration.h
// CloudXCore
//
// Configuration data returned after successful SDK initialization.
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXExport.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Configuration data returned after successful SDK initialization.
 *
 * This object is passed to the initialization completion handler upon success.
 * Currently empty, reserved for future use to provide SDK configuration details.
 */
CLX_PUBLIC
@interface CLXSdkConfiguration : NSObject

@end

NS_ASSUME_NONNULL_END
