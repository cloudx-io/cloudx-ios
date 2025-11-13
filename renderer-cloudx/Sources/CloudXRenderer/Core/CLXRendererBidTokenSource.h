//
//  CLXRendererBidTokenSource.h
//  CloudXRenderer
//
//  CloudX renderer bid token source implementation
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXBidTokenSource.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXRendererBidTokenSource : NSObject <CLXBidTokenSource>

+ (instancetype)createInstance;

@end

NS_ASSUME_NONNULL_END 