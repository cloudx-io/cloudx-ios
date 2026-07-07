#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdapterInitializer.h>

NS_ASSUME_NONNULL_BEGIN

/// Returns YES once the Mintegral SDK has been initialized via
/// `-initializeWithParams:`. Adapters can gate their load path on this so a
/// load issued before init fails fast with a clear error instead of being
/// silently dropped by the partner SDK.
BOOL CLXMintegralInitializerIsInitialized(void);

@interface CLXMintegralInitializer : CLXAdapterInitializer

@property (nonatomic, copy, readonly) NSString *sdkVersion;
@property (nonatomic, copy, readonly) NSString *network;

+ (NSString *)sdkVersion;

@end

NS_ASSUME_NONNULL_END
