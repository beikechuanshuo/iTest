//
//  UIColor+Extension.h
//  HExtension
//
//  Created by liyanjun on 16/3/15.
//  Copyright © 2016年 liyanjun. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (Extension)

+ (UIColor *)colorWithHex:(NSInteger)hex alpha:(CGFloat)alpha;

+ (UIColor *)colorWithHex:(NSInteger)hex;

+ (UIColor *)colorWithHexString:(NSString *)hexString;

@end
