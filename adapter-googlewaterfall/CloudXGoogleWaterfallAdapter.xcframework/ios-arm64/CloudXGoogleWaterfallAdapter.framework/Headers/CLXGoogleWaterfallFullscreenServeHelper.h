#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CloudXCore/CLXAdapterLoadParams.h>
#import <CloudXCore/CLXAdapterShowParams.h>
#import <CloudXCore/CLXAdapterLogger.h>

@class CLXError;

NS_ASSUME_NONNULL_BEGIN

@protocol CLXGoogleWaterfallFullscreenServeEmitter <NSObject>
- (BOOL)acquiredAdIsValid:(id)ad;
- (void)presentAd:(id)ad fromViewController:(nullable UIViewController *)vc;
- (NSString *)notReadyMessage;
- (void)emitDidLoad;
- (void)emitDidFailToLoad:(CLXError *)error;
- (void)emitDidDisplay;
- (void)emitDidClick;
- (void)emitDidHide;
- (void)emitDidFailToDisplay:(CLXError *)error;
- (void)emitImpression:(nullable NSDictionary *)extraInfo;
@end

@interface CLXGoogleWaterfallFullscreenServeHelper : NSObject

- (instancetype)initWithAdm:(NSString *)adm
                     extras:(nullable NSDictionary<NSString *, NSString *> *)extras
           fallbackGraceSec:(NSTimeInterval)fallbackGraceSec
                     logger:(id<CLXAdapterLogger>)logger
                    emitter:(id<CLXGoogleWaterfallFullscreenServeEmitter>)emitter NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (void)loadWithParams:(CLXAdapterLoadParams *)loadParams;
- (void)showWithParams:(CLXAdapterShowParams *)showParams;
- (BOOL)isReady;
- (void)destroy;

@property (nonatomic, strong, readonly, nullable) id servingAd;
@property (nonatomic, copy, readonly) NSString *adm;

@end

NS_ASSUME_NONNULL_END
