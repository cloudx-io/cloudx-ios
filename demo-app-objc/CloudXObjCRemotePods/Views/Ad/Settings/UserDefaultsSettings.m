//
//  UserDefaultsSettings.m
//  CloudXObjCRemotePods
//
//  Created by Xenoss on 23.07.2025.
//

#import "UserDefaultsSettings.h"

@implementation UserDefaultsSettings

+ (instancetype)sharedSettings {
    static UserDefaultsSettings *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[UserDefaultsSettings alloc] init];
    });
    return sharedInstance;
}

@end

