#import <CloudXCore/NSString+CLXSemicolon.h>

@implementation NSString (CLXURLEncoding)

- (NSString *)clx_urlQueryEncodedString {
    NSMutableCharacterSet *allowed = [NSMutableCharacterSet alphanumericCharacterSet];
    [allowed addCharactersInString:@"-._~"];
    return [self stringByAddingPercentEncodingWithAllowedCharacters:allowed];
}

@end
