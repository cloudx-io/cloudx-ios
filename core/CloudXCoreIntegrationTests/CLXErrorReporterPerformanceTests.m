/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXErrorReporterPerformanceTests.m
 * @brief Performance/stress tests for CLXErrorReporter
 *
 * These tests use measureBlock and exercise the full reporting pipeline
 * (including singleton access and logger I/O), making them unsuitable
 * for the parallel-safe unit test target.
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CLXErrorReporter.h>

@interface CLXErrorReporterPerformanceTests : XCTestCase
@property (nonatomic, strong) CLXErrorReporter *errorReporter;
@end

@implementation CLXErrorReporterPerformanceTests

- (void)setUp {
    [super setUp];
    self.errorReporter = [[CLXErrorReporter alloc] init];
}

- (void)tearDown {
    self.errorReporter = nil;
    [super tearDown];
}

- (void)testErrorReporting_PerformanceUnderLoad {
    NSInteger reportCount = 1000;

    [self measureBlock:^{
        for (NSInteger i = 0; i < reportCount; i++) {
            NSException *exception = [NSException exceptionWithName:@"PerformanceTestException"
                                                            reason:[NSString stringWithFormat:@"Performance test exception %ld", (long)i]
                                                          userInfo:@{@"iteration": @(i)}];
            [self.errorReporter reportException:exception context:@{@"test": @"performance"}];
        }
    }];
}

@end
