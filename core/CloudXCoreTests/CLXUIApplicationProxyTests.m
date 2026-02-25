/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXUIApplicationProxyTests.m
 * @brief Tests for CLXUIApplicationProxy view controller traversal logic.
 *
 * Verifies that clx_topViewControllerFrom: correctly walks standard UIKit VC
 * hierarchies: UINavigationController, UITabBarController, presentedViewController,
 * and combinations thereof. This is the same traversal pattern used by AppLovin
 * MAX's ALUtils.topViewControllerFromKeyWindow.
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CLXUIApplicationProxy.h>

@interface CLXUIApplicationProxy (Testing)
+ (UIViewController *)clx_topViewControllerFrom:(UIViewController *)vc;
@end

@interface CLXMockPresentingVC : UIViewController
@property (nonatomic, strong) UIViewController *mockPresentedVC;
@end

@implementation CLXMockPresentingVC
- (UIViewController *)presentedViewController {
    return self.mockPresentedVC;
}
@end

@interface CLXMockPresentingTabBarVC : UITabBarController
@property (nonatomic, strong) UIViewController *mockPresentedVC;
@end

@implementation CLXMockPresentingTabBarVC
- (UIViewController *)presentedViewController {
    return self.mockPresentedVC;
}
@end

@interface CLXUIApplicationProxyTests : XCTestCase
@end

@implementation CLXUIApplicationProxyTests

#pragma mark - Nil / Base Cases

- (void)testNilViewController_ReturnsNil {
    UIViewController *result = [CLXUIApplicationProxy clx_topViewControllerFrom:nil];
    XCTAssertNil(result);
}

- (void)testPlainViewController_ReturnsSelf {
    UIViewController *vc = [[UIViewController alloc] init];
    UIViewController *result = [CLXUIApplicationProxy clx_topViewControllerFrom:vc];
    XCTAssertEqual(result, vc);
}

#pragma mark - UINavigationController

- (void)testNavigationController_ReturnsVisibleViewController {
    UIViewController *root = [[UIViewController alloc] init];
    UIViewController *pushed = [[UIViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:root];
    [nav pushViewController:pushed animated:NO];

    UIViewController *result = [CLXUIApplicationProxy clx_topViewControllerFrom:nav];
    XCTAssertEqual(result, pushed);
}

- (void)testEmptyNavigationController_ReturnsSelf {
    UINavigationController *nav = [[UINavigationController alloc] init];
    UIViewController *result = [CLXUIApplicationProxy clx_topViewControllerFrom:nav];
    XCTAssertEqual(result, nav, @"Empty nav controller should return itself as a usable presenting VC");
}

- (void)testNavigationControllerWithSingleVC_ReturnsRoot {
    UIViewController *root = [[UIViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:root];

    UIViewController *result = [CLXUIApplicationProxy clx_topViewControllerFrom:nav];
    XCTAssertEqual(result, root);
}

#pragma mark - UITabBarController

- (void)testTabBarController_ReturnsSelectedTab {
    UIViewController *tab0 = [[UIViewController alloc] init];
    UIViewController *tab1 = [[UIViewController alloc] init];
    UITabBarController *tabs = [[UITabBarController alloc] init];
    tabs.viewControllers = @[tab0, tab1];
    tabs.selectedIndex = 1;

    UIViewController *result = [CLXUIApplicationProxy clx_topViewControllerFrom:tabs];
    XCTAssertEqual(result, tab1);
}

- (void)testTabBarWithNavController_ReturnsDeepestVC {
    UIViewController *detail = [[UIViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:[[UIViewController alloc] init]];
    [nav pushViewController:detail animated:NO];

    UITabBarController *tabs = [[UITabBarController alloc] init];
    tabs.viewControllers = @[nav];
    tabs.selectedIndex = 0;

    UIViewController *result = [CLXUIApplicationProxy clx_topViewControllerFrom:tabs];
    XCTAssertEqual(result, detail);
}

#pragma mark - Presented View Controllers (using mocks)

- (void)testPresentedViewController_ReturnsPresentedVC {
    UIViewController *modal = [[UIViewController alloc] init];
    CLXMockPresentingVC *root = [[CLXMockPresentingVC alloc] init];
    root.mockPresentedVC = modal;

    UIViewController *result = [CLXUIApplicationProxy clx_topViewControllerFrom:root];
    XCTAssertEqual(result, modal);
}

- (void)testDoublePresentedViewController_ReturnsDeepest {
    UIViewController *modal2 = [[UIViewController alloc] init];
    CLXMockPresentingVC *modal1 = [[CLXMockPresentingVC alloc] init];
    modal1.mockPresentedVC = modal2;
    CLXMockPresentingVC *root = [[CLXMockPresentingVC alloc] init];
    root.mockPresentedVC = modal1;

    UIViewController *result = [CLXUIApplicationProxy clx_topViewControllerFrom:root];
    XCTAssertEqual(result, modal2);
}

- (void)testNavControllerWithPresentedModal_ReturnsModal {
    UIViewController *modal = [[UIViewController alloc] init];
    CLXMockPresentingVC *pushed = [[CLXMockPresentingVC alloc] init];
    pushed.mockPresentedVC = modal;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:[[UIViewController alloc] init]];
    [nav pushViewController:pushed animated:NO];

    UIViewController *result = [CLXUIApplicationProxy clx_topViewControllerFrom:nav];
    XCTAssertEqual(result, modal);
}

#pragma mark - Combined Hierarchies

- (void)testNavInsideTabWithPresented_ReturnsDeepest {
    UIViewController *modal = [[UIViewController alloc] init];
    CLXMockPresentingVC *detail = [[CLXMockPresentingVC alloc] init];
    detail.mockPresentedVC = modal;

    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:[[UIViewController alloc] init]];
    [nav pushViewController:detail animated:NO];

    UITabBarController *tabs = [[UITabBarController alloc] init];
    tabs.viewControllers = @[nav];

    UIViewController *result = [CLXUIApplicationProxy clx_topViewControllerFrom:tabs];
    XCTAssertEqual(result, modal,
                   @"Should traverse tab -> nav -> pushed -> presented to find deepest VC");
}

- (void)testTabBarWithPresentedModal_ReturnsModal {
    UIViewController *tab0 = [[UIViewController alloc] init];
    UIViewController *modal = [[UIViewController alloc] init];
    CLXMockPresentingTabBarVC *tabs = [[CLXMockPresentingTabBarVC alloc] init];
    tabs.viewControllers = @[tab0];
    tabs.selectedIndex = 0;
    tabs.mockPresentedVC = modal;

    UIViewController *result = [CLXUIApplicationProxy clx_topViewControllerFrom:tabs];
    XCTAssertEqual(result, modal,
                   @"Modal presented on tab bar controller should take priority over selected tab");
}

- (void)testTabBarWithMultipleTabs_ReturnsCorrectSelectedTabChild {
    UIViewController *tab0Detail = [[UIViewController alloc] init];
    UINavigationController *nav0 = [[UINavigationController alloc] initWithRootViewController:[[UIViewController alloc] init]];
    [nav0 pushViewController:tab0Detail animated:NO];

    UIViewController *tab1Root = [[UIViewController alloc] init];

    UITabBarController *tabs = [[UITabBarController alloc] init];
    tabs.viewControllers = @[nav0, tab1Root];
    tabs.selectedIndex = 0;

    UIViewController *result = [CLXUIApplicationProxy clx_topViewControllerFrom:tabs];
    XCTAssertEqual(result, tab0Detail, @"Should return child of selected tab, not other tabs");

    tabs.selectedIndex = 1;
    result = [CLXUIApplicationProxy clx_topViewControllerFrom:tabs];
    XCTAssertEqual(result, tab1Root, @"Should follow selected tab index change");
}

@end
