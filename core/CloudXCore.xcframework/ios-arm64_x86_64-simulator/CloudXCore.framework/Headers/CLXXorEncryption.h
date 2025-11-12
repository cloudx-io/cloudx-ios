//
//  XorEncryption.h
//  Pods
//
//  Created by Xenoss on 03.07.2025.
//


#import <Foundation/Foundation.h>

@interface CLXXorEncryption : NSObject

+ (NSData *)generateXorSecret:(NSString *)accountId;
+ (NSString *)encrypt:(NSString *)impression secret:(NSData *)secret;
+ (NSString *)decrypt:(NSString *)encryptedBase64 secret:(NSData *)secret;
+ (NSString *)generateCampaignIdBase64:(NSString *)accountId;

@end
