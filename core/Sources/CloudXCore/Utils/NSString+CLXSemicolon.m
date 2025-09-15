#import <CloudXCore/NSString+CLXSemicolon.h>

@implementation NSString (Semicolon)

- (NSString *)semicolon {
    return [self stringByAppendingString:@";"];
}

- (NSString *)base64Encoded {
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    return [data base64EncodedStringWithOptions:0];
}

@end


@implementation NSString (URLEncoding)

- (NSString *)urlQueryEncodedString {
    NSMutableCharacterSet *allowed = [NSMutableCharacterSet alphanumericCharacterSet];
    [allowed addCharactersInString:@"-._~"];
    return [self stringByAddingPercentEncodingWithAllowedCharacters:allowed];
}

@end
