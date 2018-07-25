//
//  UIApplication+Extension.h
//  HExtension
//
//  Created by liyanjun on 16/3/15.
//  Copyright © 2016年 liyanjun. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIApplication (Extension)

- (UIWindow *)getKeyWindow;

- (UIViewController *)rootViewController;

//当前显示的VC
+ (UIViewController *)getCurrentShowVC;

@end
