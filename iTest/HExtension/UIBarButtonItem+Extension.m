//
//  UIBarButtonItem+Extension.m
//  reliao
//
//  Created by liyanjun on 2017/3/17.
//
//

#import "UIBarButtonItem+Extension.h"

@implementation UIBarButtonItem (Extension)


+ (UIBarButtonItem *)barButtonItemTaget:(id)taget action:(SEL)action imageNormal:(NSString *)imageNormal imageHighlighted:(NSString *)imageHighlighted {
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [button setBackgroundImage:[UIImage imageNamed:imageNormal] forState:UIControlStateNormal];
    
    [button setBackgroundImage:[UIImage imageNamed:imageHighlighted] forState:UIControlStateHighlighted];
    
    [button addTarget:taget action:action forControlEvents:UIControlEventTouchUpInside];
    
    CGRect rect = button.frame;
    rect.size = button.currentBackgroundImage.size;
    button.frame = rect;
    return  [[UIBarButtonItem alloc] initWithCustomView:button];
}

@end
