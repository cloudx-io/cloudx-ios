/*
 * Copyright (c) 2025 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXIlrdProvider.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * ILRD provider for AL MAX SDK.
 * Subscribes to revenue events topic via ALCCommunicator
 * and converts revenue messages into ILRD event dictionaries.
 */
@interface CLXAlIlrd : NSObject <CLXIlrdProvider>

/**
 * Initialize with the account name used as the communicator identifier.
 * The account name is converted to snake_case for the ALCCommunicator subscription.
 */
- (instancetype)initWithAccountName:(NSString *)accountName;

/**
 * Converts account name to snake_case for use as communicator identifier.
 * Splits on camelCase boundaries and spaces, joins with underscores, lowercases.
 * Exposed for testing.
 */
- (NSString *)accountNameAsSnakeCase;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
