#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURLSession (CloudX)

+ (NSURLSession *)cloudxSessionWithIdentifier:(NSString *)identifier;

@end

NS_ASSUME_NONNULL_END 