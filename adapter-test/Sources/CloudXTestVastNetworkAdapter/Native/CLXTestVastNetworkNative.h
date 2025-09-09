//
//  CloudXTestVastNetworkNative.h
//  CloudXTestVastNetworkAdapter
//
//  Created by bkorda on 06.03.2024.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXTestVastNetworkNative : NSObject <CLXAdapterNative>

@property (nonatomic, weak) id<CLXAdapterNativeDelegate> delegate;

- (instancetype)initWithAdm:(NSString *)adm
                                               type:(CLXNativeTemplate)type
              viewController:(UIViewController *)viewController
                                       delegate:(nullable id<CLXAdapterNativeDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END 