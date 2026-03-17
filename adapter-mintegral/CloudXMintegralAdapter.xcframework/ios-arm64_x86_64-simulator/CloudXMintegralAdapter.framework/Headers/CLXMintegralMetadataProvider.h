#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdapterMetadataProvider.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXMintegralMetadataProvider : NSObject <CLXAdapterMetadataProvider>
+ (instancetype)createInstance;
@end

NS_ASSUME_NONNULL_END
