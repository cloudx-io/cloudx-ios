//
//  CLXMolocoNativeFactory.h
//  CloudXMolocoAdapter
//
//  Created by CloudX on 2024.
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdapterNativeFactory.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXMolocoNativeFactory : NSObject <CLXAdapterNativeFactory>

+ (instancetype)createInstance;

@end

NS_ASSUME_NONNULL_END

