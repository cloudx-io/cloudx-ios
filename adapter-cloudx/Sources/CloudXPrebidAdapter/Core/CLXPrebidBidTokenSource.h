//
//  CLXPrebidBidTokenSource.h
//  CloudXPrebidAdapter
//
//  Prebid 3.0 bid token source implementation
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXBidTokenSource.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXPrebidBidTokenSource : NSObject <CLXBidTokenSource>

+ (instancetype)createInstance;

@end

NS_ASSUME_NONNULL_END 