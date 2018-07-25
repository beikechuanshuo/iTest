//
//  HRecordProgressView.m
//  reliao
//
//  Created by liyanjun on 16/9/26.
//
//

#import "HRecordProgressView.h"

@interface HRecordProgressView ()

@property (nonatomic, strong) CALayer *progressLayer;
@property (nonatomic, strong) CALayer *markLayer;

@end

@implementation HRecordProgressView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.progressLayer = [CALayer layer];
        [self.layer addSublayer:self.progressLayer];
        
        self.markLayer = [CALayer layer];
        self.markLayer.frame = CGRectMake(frame.size.width/10, 0, 5, frame.size.height);
        self.markLayer.backgroundColor = [UIColor redColor].CGColor;
        [self.layer addSublayer:self.markLayer];
    }
    return self;
}

- (void)setProgress:(CGFloat)progress
{
    _progress = progress;
    
    if (progress >= 1.0)
    {
        //大于1.0时，则清理掉原来的进度条
        self.progressLayer.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame),  CGRectGetHeight(self.frame));
    }
    else if (progress == 0.0)
    {
        self.progressLayer.frame = CGRectMake(0, 0, 0,  CGRectGetHeight(self.frame));
    }
    else
    {
        self.progressLayer.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame)*progress,  CGRectGetHeight(self.frame));
    }
}

- (void)setProgressBgColor:(UIColor *)progressBgColor
{
    _progressBgColor = progressBgColor;
    
    self.backgroundColor = progressBgColor;
}


- (void)setProgressColor:(UIColor *)progressColor
{
    _progressColor = progressColor;
    
    self.progressLayer.backgroundColor = progressColor.CGColor;
}

@end
