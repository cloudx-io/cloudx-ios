#import <Foundation/Foundation.h>
#import <CloudXCore/CLXBidTokenSource.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXMintegralBidTokenSource : NSObject <CLXBidTokenSource>

@property (nonatomic, strong, readonly) NSString *network;

+ (instancetype)sharedInstance;
+ (instancetype)createInstance;

@end

NS_ASSUME_NONNULL_END

