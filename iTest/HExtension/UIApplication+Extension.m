//
//  UIApplication+Extension.m
//  HExtension
//
//  Created by liyanjun on 16/3/15.
//  Copyright © 2016年 liyanjun. All rights reserved.
//

#import "UIApplication+Extension.h"

@implementation UIApplication (Extension)

- (UIWindow *)getKeyWindow
{
    return self.keyWindow;
}

- (UIViewController *)rootViewController
{
    return [self getKeyWindow].rootViewController;
}

+ (UIViewController *)getCurrentShowVC
{
    UIViewController *result = nil;
    
    UIWindow * window = [[UIApplication sharedApplication] keyWindow];
    if (window.windowLevel != UIWindowLevelNormal)
    {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(UIWindow * tmpWin in windows)
        {
            if (tmpWin.windowLevel == UIWindowLevelNormal)
            {
                window = tmpWin;
                break;
            }
        }
    }
    
    UIView *frontView = [[window subviews] objectAtIndex:0];
    id nextResponder = [frontView nextResponder];
    if ([nextResponder isKindOfClass:[UIViewController class]])
    {
        result = nextResponder;
    }
    else
    {
        result = window.rootViewController;
    }
    
    return result;
}

@end
