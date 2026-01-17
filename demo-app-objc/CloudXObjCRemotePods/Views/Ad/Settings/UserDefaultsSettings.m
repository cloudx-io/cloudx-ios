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

#pragma mark - Hashed User ID

- (NSString *)hashedUserId {
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"DemoApp.HashedUserId"];
}

- (void)setHashedUserId:(NSString *)hashedUserId {
    [[NSUserDefaults standardUserDefaults] setObject:hashedUserId forKey:@"DemoApp.HashedUserId"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Print Bid Response (QA)

- (BOOL)printBidResponse {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"DemoApp.PrintBidResponse"];
}

- (void)setPrintBidResponse:(BOOL)printBidResponse {
    [[NSUserDefaults standardUserDefaults] setBool:printBidResponse forKey:@"DemoApp.PrintBidResponse"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end

