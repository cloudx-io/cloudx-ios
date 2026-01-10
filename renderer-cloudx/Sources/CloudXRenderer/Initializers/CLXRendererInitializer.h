//
//  CLXRendererInitializer.h
//  CloudXRenderer
//
//  CloudX renderer initializer
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXRendererInitializer : NSObject <CLXAdNetworkInitializer>

+ (instancetype)createInstance;
- (void)initializeWithConfig:(nullable CLXBidderConfig *)config testMode:(BOOL)testMode completion:(void (^)(BOOL success, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END 