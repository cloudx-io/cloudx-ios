//
//  CLXRendererNative.h
//  CloudXRenderer
//
//  CloudX native ad renderer implementation
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXRendererNative : NSObject <CLXAdapterNative>

@property (nonatomic, weak) id<CLXAdapterNativeDelegate> delegate;

- (instancetype)initWithAdm:(NSString *)adm
                                               type:(CLXNativeTemplate)type
              viewController:(UIViewController *)viewController
                                       delegate:(nullable id<CLXAdapterNativeDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END 