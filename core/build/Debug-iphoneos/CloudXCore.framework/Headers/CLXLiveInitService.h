/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file LiveInitService.h
 * @brief Live implementation of the SDK initialization service
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXSDKConfig.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXInitService.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @class LiveInitService
 * @brief Concrete implementation of InitService for live environment
 * @discussion This service handles the actual initialization of the SDK in a live environment,
 * coordinating with the network service to perform the initialization.
 */
@interface CLXLiveInitService : NSObject <CLXInitService>

/** Logger instance for tracking initialization process */
@property (nonatomic, strong) CLXLogger *logger;

/**
 * @brief Initializes the SDK with the provided app key
 * @param appKey The application key for SDK initialization
 * @param completion Completion handler called with the SDK configuration or error
 */
- (void)initSDKWithAppKey:(NSString *)appKey completion:(void (^)(CLXSDKConfigResponse * _Nullable config, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END 