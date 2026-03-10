//
//  CLXUnityBidTokenSource.h
//  CloudXUnityAdapter
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXBidTokenSource.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXUnityBidTokenSource : NSObject <CLXBidTokenSource>

+ (instancetype)sharedInstance;
+ (instancetype)createInstance;

@end

NS_ASSUME_NONNULL_END
