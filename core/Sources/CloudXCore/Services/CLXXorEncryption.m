//
//  XorEncryption.m
//  Pods
//
//  Created by Xenoss on 03.07.2025.
//


#import <CloudXCore/CLXXorEncryption.h>

@implementation CLXXorEncryption

static NSString * const STATIC_SECRET = @"cloudx";

// Utility: Reverse string
+ (NSString *)reverseString:(NSString *)str {
    NSUInteger len = [str length];
    NSMutableString *reversed = [NSMutableString stringWithCapacity:len];
    while (len > 0) {
        len--;
        unichar c = [str characterAtIndex:len];
        [reversed appendFormat:@"%C", c];
    }
    return reversed;
}

// Utility: Convert 4 bytes (big endian) to int
+ (int)intFromBigEndianBytes:(const uint8_t *)bytes {
    return (int)((bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | (bytes[3]));
}

// Utility: Convert int to 4 bytes (big endian)
+ (void)bigEndianBytesFromInt:(int)value intoBuffer:(uint8_t *)buffer {
    buffer[0] = (value >> 24) & 0xFF;
    buffer[1] = (value >> 16) & 0xFF;
    buffer[2] = (value >> 8) & 0xFF;
    buffer[3] = value & 0xFF;
}

// Convert int to NSData (4 bytes big endian)
+ (NSData *)intToData:(int)value {
    uint8_t buffer[4];
    [self bigEndianBytesFromInt:value intoBuffer:buffer];
    return [NSData dataWithBytes:buffer length:4];
}

+ (NSData *)generateXorSecret:(NSString *)accountId {
    NSString *reversed = [self reverseString:accountId];
    int reversedHash = [self xorHashCode:reversed];
    return [self intToData:reversedHash];
}

+ (NSString *)encrypt:(NSString *)impression secret:(NSData *)secret {
    NSData *inputData = [impression dataUsingEncoding:NSUTF8StringEncoding];
    NSData *encryptedData = [self xorWithSecretIntChunks:inputData secret:secret];
    return [encryptedData base64EncodedStringWithOptions:0];
}

+ (NSString *)decrypt:(NSString *)encryptedBase64 secret:(NSData *)secret {
    NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:encryptedBase64 options:0];
    NSData *decryptedData = [self xorWithSecretIntChunks:decodedData secret:secret];
    return [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
}

// XOR payload in 4-byte (int) chunks with secret int. Pad last chunk with zeros if needed.
+ (NSData *)xorWithSecretIntChunks:(NSData *)input secret:(NSData *)secret {
    if ([secret length] != 4) {
        @throw [NSException exceptionWithName:@"IllegalArgumentException"
                                       reason:@"Secret must be 4 bytes!"
                                     userInfo:nil];
    }
    const uint8_t *secretBytes = (const uint8_t *)secret.bytes;
    int secretInt = [self intFromBigEndianBytes:secretBytes];

    NSUInteger paddedLen = ((input.length + 3) / 4) * 4;
    NSMutableData *paddedInput = [NSMutableData dataWithLength:paddedLen];
    [paddedInput replaceBytesInRange:NSMakeRange(0, input.length) withBytes:input.bytes];
    NSMutableData *out = [NSMutableData dataWithLength:paddedLen];

    for (NSUInteger i = 0; i < paddedLen; i += 4) {
        const uint8_t *chunkBytes = ((const uint8_t *)paddedInput.bytes) + i;
        int chunkInt = [self intFromBigEndianBytes:chunkBytes];
        int xored = chunkInt ^ secretInt;
        uint8_t xoredBytes[4];
        [self bigEndianBytesFromInt:xored intoBuffer:xoredBytes];
        [out replaceBytesInRange:NSMakeRange(i, 4) withBytes:xoredBytes];
    }
    // Only return the original input length
    return [out subdataWithRange:NSMakeRange(0, input.length)];
}

// Hash using XOR of 4-byte int chunks, big-endian, padded with zeros
+ (int)xorHashCode:(NSString *)str {
    NSData *input = [str dataUsingEncoding:NSUTF8StringEncoding];
    NSUInteger paddedLen = ((input.length + 3) / 4) * 4;
    NSMutableData *padded = [NSMutableData dataWithLength:paddedLen];
    [padded replaceBytesInRange:NSMakeRange(0, input.length) withBytes:input.bytes];

    int out = [self intFromBigEndianBytes:(const uint8_t *)padded.bytes];
    for (NSUInteger i = 4; i < paddedLen; i += 4) {
        int chunk = [self intFromBigEndianBytes:((const uint8_t *)padded.bytes) + i];
        out = out ^ chunk;
    }
    return out;
}

+ (NSString *)generateCampaignIdBase64:(NSString *)accountId {
    int hashA = [self xorHashCode:STATIC_SECRET];
    NSString *reversed = [self reverseString:accountId];
    int hashB = [self xorHashCode:reversed];
    int xor = hashA ^ hashB;
    NSData *data = [self intToData:xor];
    return [data base64EncodedStringWithOptions:0];
}

@end
