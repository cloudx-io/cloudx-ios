#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (CLXSemicolon)

- (NSString *)clx_semicolon;
- (NSString *)clx_base64Encoded;

@end

@interface NSString (CLXURLEncoding)

- (NSString *)clx_urlQueryEncodedString;

@end

NS_ASSUME_NONNULL_END 

