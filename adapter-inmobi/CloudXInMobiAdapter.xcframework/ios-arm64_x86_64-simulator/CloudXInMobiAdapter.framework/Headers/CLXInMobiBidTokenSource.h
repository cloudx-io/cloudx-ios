//
//  CLXInMobiBidTokenSource.h
//  CloudXInMobiAdapter
//
//  Created by CloudX Team.
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXBidTokenSource.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXInMobiBidTokenSource : NSObject <CLXBidTokenSource>

+ (instancetype)createInstance;

@end

NS_ASSUME_NONNULL_END

