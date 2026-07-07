//
//  CLXMetaInitializer.h
//  CloudXMetaAdapter
//

#import <CloudXCore/CLXAdapterInitializer.h>

@interface CLXMetaInitializer : CLXAdapterInitializer

@property (nonatomic, copy, readonly) NSString *sdkVersion;
@property (nonatomic, copy, readonly) NSString *network;

+ (NSString *)sdkVersion;

@end 
