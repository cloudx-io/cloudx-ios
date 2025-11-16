//
//  CLXMolocoBidTokenSource.h
//  CloudXMolocoAdapter
//
//  Created by CloudX on 2024.
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXBidTokenSource.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXMolocoBidTokenSource : NSObject <CLXBidTokenSource>

@property (nonatomic, strong, readonly) NSString *network;

+ (instancetype)sharedInstance;
+ (instancetype)createInstance;

@end

NS_ASSUME_NONNULL_END

