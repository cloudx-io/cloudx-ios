#import <Foundation/Foundation.h>
#import <CloudXCore/CLXExport.h>

NS_ASSUME_NONNULL_BEGIN

CLX_PUBLIC
@interface CLXSettings : NSObject

+ (instancetype)sharedInstance;

// MARK: - Location Controls

/// @deprecated No-op. Server-controlled.
@property (nonatomic, assign) BOOL locationSharingEnabled
    __attribute__((deprecated("Server-controlled; this property is a no-op.")));

@end

NS_ASSUME_NONNULL_END
