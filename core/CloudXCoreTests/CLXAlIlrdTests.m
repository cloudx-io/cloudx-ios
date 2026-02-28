/*
 * Copyright (c) 2025 CloudX. All rights reserved.
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CLXAlIlrd.h>

@interface CLXAlIlrdTests : XCTestCase
@end

@implementation CLXAlIlrdTests

#pragma mark - Snake Case Conversion

- (void)testSnakeCaseFromCamelCase {
    // Arrange
    CLXAlIlrd *subject = [[CLXAlIlrd alloc] initWithAccountName:@"myAccountName"];

    // Act
    NSString *result = [subject accountNameAsSnakeCase];

    // Assert
    XCTAssertEqualObjects(result, @"my_account_name");
}

- (void)testSnakeCaseFromSpaces {
    // Arrange
    CLXAlIlrd *subject = [[CLXAlIlrd alloc] initWithAccountName:@"My Account Name"];

    // Act
    NSString *result = [subject accountNameAsSnakeCase];

    // Assert
    XCTAssertEqualObjects(result, @"my_account_name");
}

- (void)testSnakeCaseFromLowercase {
    // Arrange
    CLXAlIlrd *subject = [[CLXAlIlrd alloc] initWithAccountName:@"simple"];

    // Act
    NSString *result = [subject accountNameAsSnakeCase];

    // Assert
    XCTAssertEqualObjects(result, @"simple");
}

- (void)testSnakeCaseFromEmpty {
    // Arrange
    CLXAlIlrd *subject = [[CLXAlIlrd alloc] initWithAccountName:@""];

    // Act
    NSString *result = [subject accountNameAsSnakeCase];

    // Assert
    XCTAssertEqualObjects(result, @"");
}

- (void)testSnakeCaseFromSingleUppercase {
    // Arrange
    CLXAlIlrd *subject = [[CLXAlIlrd alloc] initWithAccountName:@"ABC"];

    // Act
    NSString *result = [subject accountNameAsSnakeCase];

    // Assert
    XCTAssertEqualObjects(result, @"a_b_c");
}

#pragma mark - Subscribe Without AL SDK

- (void)testSubscribeFailsWhenAlSdkNotAvailable {
    // Arrange
    CLXAlIlrd *subject = [[CLXAlIlrd alloc] initWithAccountName:@"test"];

    // Act
    NSError *error = nil;
    BOOL result = [subject subscribeWithError:&error];

    // Assert
    XCTAssertFalse(result);
    XCTAssertNotNil(error);
}

#pragma mark - Event Callback

- (void)testEventCallbackCanBeSetAndCleared {
    // Arrange
    CLXAlIlrd *subject = [[CLXAlIlrd alloc] initWithAccountName:@"test"];

    // Act & Assert - should not crash
    [subject setEventCallback:^(NSDictionary<NSString *, id> *event) {}];
    [subject setEventCallback:nil];
}

#pragma mark - Platform Property

- (void)testPlatformIsAl {
    // Arrange
    CLXAlIlrd *subject = [[CLXAlIlrd alloc] initWithAccountName:@"test"];

    // Assert
    XCTAssertEqual(subject.platform, CLXIlrdPlatformAl);
}

@end
