//
//  CloudXFullscreenStaticContainerViewController.h
//  CloudXTestVastNetworkAdapter
//
//  Created by bkorda on 07.03.2024.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CLXFullscreenStaticContainerViewControllerDelegate <NSObject>

- (void)closeFullScreenAd;
- (void)didFailToShowWithError:(NSError *)error;
- (void)didClickFullAdd;
- (void)didLoad;
- (void)didShow;
- (void)impression;

@end

@interface CLXFullscreenStaticContainerViewController : UIViewController

- (instancetype)initWithDelegate:(id<CLXFullscreenStaticContainerViewControllerDelegate>)delegate
                            adm:(NSString *)adm;

- (void)destroy;
- (void)loadHTML;

@end

NS_ASSUME_NONNULL_END 