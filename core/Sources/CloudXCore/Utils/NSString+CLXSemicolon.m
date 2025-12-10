#import <CloudXCore/NSString+CLXSemicolon.h>

@implementation NSString (CLXSemicolon)

- (NSString *)clx_semicolon {
    return [self stringByAppendingString:@";"];
}

- (NSString *)clx_base64Encoded {
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    return [data base64EncodedStringWithOptions:0];
}

@end


@implementation NSString (CLXURLEncoding)

- (NSString *)clx_urlQueryEncodedString {
    NSMutableCharacterSet *allowed = [NSMutableCharacterSet alphanumericCharacterSet];
    [allowed addCharactersInString:@"-._~"];
    return [self stringByAddingPercentEncodingWithAllowedCharacters:allowed];
}

@end
