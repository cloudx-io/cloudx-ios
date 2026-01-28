/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import "CLXPayloadBuilder+Testing.h"
#import <objc/runtime.h>

@implementation CLXPayloadBuilder (Testing)

+ (instancetype)testBuilderWithAccountId:(NSString *)accountId
                             basePayload:(NSString *)basePayload {
    // Allocate the object and call the private initPrivate method via runtime
    CLXPayloadBuilder *builder = [CLXPayloadBuilder alloc];
    
    // Call initPrivate using performSelector
    SEL initPrivateSel = NSSelectorFromString(@"initPrivate");
    if ([builder respondsToSelector:initPrivateSel]) {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        builder = [builder performSelector:initPrivateSel];
        #pragma clang diagnostic pop
    } else {
        // Fallback: just init if initPrivate not available
        builder = [[CLXPayloadBuilder alloc] init];
    }
    
    // Set the properties using KVC (Key-Value Coding)
    [builder setValue:accountId forKey:@"accountId"];
    [builder setValue:basePayload forKey:@"basePayload"];
    
    return builder;
}

@end
