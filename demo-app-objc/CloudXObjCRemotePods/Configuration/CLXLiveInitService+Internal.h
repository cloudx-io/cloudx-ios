#import <Foundation/Foundation.h>
#import <CloudXCore/CLXLiveInitService.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief Internal methods for CLXLiveInitService to support custom initialization URLs
 * @discussion This category exposes internal functionality for demo purposes only.
 * Production apps should use the standard initialization methods.
 */
@interface CLXLiveInitService (Internal)

/**
 * @brief Initializes the SDK with a custom initialization URL
 * @param appKey The application key for SDK initialization
 * @param customInitURL Custom URL for SDK initialization endpoint
 * @param completion Completion handler called with the SDK configuration or error
 * @discussion This method allows overriding the default initialization URL for testing different environments
 */
- (void)initSDKWithAppKey:(NSString *)appKey 
            customInitURL:(NSString *)customInitURL 
               completion:(void (^)(CLXSDKConfigResponse * _Nullable config, NSError * _Nullable error))completion;

/**
 * @brief Initialize SDK with custom URL and hashed user ID
 * @param appKey The application key for SDK initialization
 * @param customInitURL Custom URL for SDK initialization endpoint
 * @param hashedUserId The hashed user ID for SDK initialization
 * @param completion Completion handler called with success status and error
 * @discussion This method combines custom URL initialization with standard SDK initialization flow
 */
- (void)initSDKWithAppKey:(NSString *)appKey 
            customInitURL:(NSString *)customInitURL 
             hashedUserId:(NSString *)hashedUserId
               completion:(void (^)(BOOL success, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
