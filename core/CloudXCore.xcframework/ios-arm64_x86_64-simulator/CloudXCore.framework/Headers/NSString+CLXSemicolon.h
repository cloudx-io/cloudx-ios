#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (Semicolon)

- (NSString *)semicolon;
- (NSString *)base64Encoded;

@end

@interface NSString (URLEncoding)

- (NSString *)urlQueryEncodedString;

@end

NS_ASSUME_NONNULL_END 
