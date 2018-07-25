//
//  CALayer+Extension.m
//  Animation
//
//  Created by liyanjun on 2018/3/16.
//  Copyright © 2018年 liyanjun. All rights reserved.
//

#import "CALayer+Extension.h"
#import <UIKit/UIKit.h>

#define RATIO ([UIScreen mainScreen].bounds.size.width / 375.0)
#define Ration(num) (num * RATIO)

@implementation CALayer (Extension)

/** 根据图片的内容创建对应的Layer对象 */
+ (CALayer *)layerWithImageName:(NSString *)imageName
{
    if (imageName.length == 0) return nil;
    UIImage *image = [UIImage imageNamed:imageName];
    CALayer *layer = [CALayer layer];
    [layer setContents:(id)image.CGImage];
    layer.bounds = CGRectMake(0, 0, Ration(image.size.width), Ration(image.size.height));
    layer.anchorPoint = CGPointMake(0.5, 1);
    
    return layer;
}

@end
