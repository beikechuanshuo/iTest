//
//  HCircleView.m
//  Test
//
//  Created by liyanjun on 2017/6/8.
//  Copyright © 2017年 liyanjun. All rights reserved.
//

#import "HCircleView.h"

@implementation HCircleView

- (void)setRadius:(CGFloat)radius
{
    _radius = radius;
    //通知自定义的view重新绘制图形
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    //1.获取图形上下文
    CGContextRef ctx=UIGraphicsGetCurrentContext();
    //2.绘图
    //在自定义的view中画一个圆
    CGContextAddArc(ctx, 0, 0, self.radius, 0, 2*M_PI, 0);
    //设置圆的填充颜色
    [self.backgroundColor set];
    
    //3.渲染
    CGContextFillPath(ctx);
}

@end


@implementation HBlurCircleView

- (void)setRadius:(CGFloat)radius
{
    _radius = radius;
    //通知自定义的view重新绘制图形
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    //1.获取图形上下文
    CGContextRef ctx=UIGraphicsGetCurrentContext();
    //2.绘图
    //在自定义的view中画一个圆
    CGContextAddArc(ctx, 100, 100, self.radius, 0, 2*M_PI, 0);
    //设置圆的填充颜色
    [self.backgroundColor set];
    
    //3.渲染
    CGContextFillPath(ctx);

}

@end
