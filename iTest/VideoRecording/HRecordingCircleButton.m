//
//  HRecordingCircleButton.m
//  reliao
//
//  Created by liyanjun on 2017/6/7.
//  Copyright © 2017年 liyanjun. All rights reserved.
//

#import "HRecordingCircleButton.h"
#import "HCircleView.h"
#import "UIColor+Extension.h"
#import "HHUDViewController.h"

#define kBackgroundCircleOrgScale 0.6
#define kBackgroundCircleEndScale 1.0
#define kTopCircleOrgScale 0.47
#define kTopCircleEndScale 0.33

#define AnimationDuration 0.2

#define kProgressWidth 6

static BOOL working = NO;

@interface HRecordingCircleButton ()

@property (nonatomic, strong) UIView *backgroundCircleView; //高斯模糊的圆

@property (nonatomic, strong) HCircleView *topCircleView; //顶部白色的圆

@property (nonatomic, assign) CGFloat radius;

@property (nonatomic, strong) CAShapeLayer *progressLayer;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, assign) CGFloat progress;

@property (nonatomic, assign) CGPoint startPoint;

@property (nonatomic, strong) CADisplayLink *link;

@property (nonatomic, assign) BOOL animationLarge; //是否是变大动画

@property (nonatomic, assign) CGPoint currectPoint; //当前移动点

@property (nonatomic, assign) CGPoint endPoint; //结束时的点

@property (nonatomic, assign) BOOL isOutofView;

@end


@implementation HRecordingCircleButton

- (instancetype)initWithCircleRadius:(CGFloat)radius center:(CGPoint)center;
{
    self = [super initWithFrame:CGRectZero];
    if (self)
    {
        CGRect frame = CGRectMake(center.x-radius, center.y-radius, radius*2, radius*2);
        self.backgroundColor = [UIColor clearColor];
        self.frame = frame;
        self.layer.cornerRadius = radius;
        self.layer.masksToBounds = YES;
        
        self.radius = radius;
        CGFloat width = radius*2;
        
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
        {
            UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
            self.backgroundCircleView = [[HBlurCircleView alloc] initWithEffect:blur];
            self.backgroundCircleView.frame = CGRectMake((1-kBackgroundCircleOrgScale)*width/2, (1-kBackgroundCircleOrgScale)*width/2, width*kBackgroundCircleOrgScale, width*kBackgroundCircleOrgScale);
            self.backgroundCircleView.layer.cornerRadius = width*kBackgroundCircleOrgScale/2;
            self.backgroundCircleView.layer.masksToBounds = YES;
            ((HBlurCircleView *)self.backgroundCircleView).radius = self.radius*kBackgroundCircleOrgScale;
        }
        else
        {
            self.backgroundCircleView = [[HCircleView alloc] initWithFrame:CGRectMake((1-kBackgroundCircleOrgScale)*width/2, (1-kBackgroundCircleOrgScale)*width/2, width*kBackgroundCircleOrgScale, width*kBackgroundCircleOrgScale)];
            self.backgroundCircleView.backgroundColor = [[UIColor colorWithHex:0xF3F3F3] colorWithAlphaComponent:0.96];
            self.backgroundCircleView.layer.cornerRadius = width*kBackgroundCircleOrgScale/2;
            self.backgroundCircleView.layer.masksToBounds = YES;
            ((HCircleView *)self.backgroundCircleView).radius = self.radius*kBackgroundCircleOrgScale;
        }
        
        [self addSubview:self.backgroundCircleView];
       
        
        self.topCircleView = [[HCircleView alloc] initWithFrame:CGRectMake((1-kTopCircleOrgScale)*width/2, (1-kTopCircleOrgScale)*width/2, width*kTopCircleOrgScale, width*kTopCircleOrgScale)];
        self.topCircleView.backgroundColor = [UIColor whiteColor];
        self.topCircleView.layer.cornerRadius = width*kTopCircleOrgScale/2;
        self.topCircleView.layer.masksToBounds = YES;
        self.topCircleView.radius = self.radius*kTopCircleOrgScale;
        [self addSubview:self.topCircleView];
        
    
        //获取环形路径（画一个圆形，填充色透明，设置线框宽度为10，这样就获得了一个环形）
        self.progressLayer = [CAShapeLayer layer];//创建一个track shape layer
        self.progressLayer.frame = self.bounds;
        self.progressLayer.fillColor = [[UIColor clearColor] CGColor];  //填充色为无色
        self.progressLayer.strokeColor = [[UIColor colorWithHex:0x0bbe06] CGColor]; //指定path的渲染颜色,这里可以设置任意不透明颜色
        self.progressLayer.opacity = 1; //背景颜色的透明度
        [self.layer addSublayer:self.progressLayer];
        
        self.progress = 0.0;
    }
    return self;
}

- (void)setProgress:(CGFloat)progress
{
    _progress = progress;
    
    CGPoint center = CGPointMake(self.radius, self.radius);
    CGFloat progressRadius = (self.radius-kProgressWidth/2);
    CGFloat startA = - M_PI_2;  //设置进度条起点位置
    CGFloat endA = -M_PI_2 + M_PI * 2 * _progress;  //设置进度条终点位置
    
    self.progressLayer.lineCap = kCALineCapSquare;//指定线的边缘是圆的
    self.progressLayer.lineWidth = kProgressWidth;//线的宽度
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center radius:progressRadius startAngle:startA endAngle:endA clockwise:YES];//上面说明过了用来构建圆形
    self.progressLayer.path = [path CGPath]; //把path传递給layer，然后layer会处理相应的渲染，整个逻辑和CoreGraph是一致的。
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(recordingCircleButton:updateProgress:)])
    {
        [self.delegate recordingCircleButton:self updateProgress:progress];
    }
}

- (void)updateProgress:(id)sender
{
    if (self.progress >= 1.0)
    {
        return;
    }
    
    self.progress += (1.0/self.recordMaxTime)/20.0;
}

- (NSTimer *)timer
{
    if (_timer == nil)
    {
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(updateProgress:) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSDefaultRunLoopMode];
    }
    
    return _timer;
}

- (CADisplayLink*)link
{
    if (!_link)
    {
        _link = [CADisplayLink displayLinkWithTarget:self selector:@selector(linkHandler)];
        _link.frameInterval = 1;
    }
    return _link;
}

-(void)linkHandler
{
    if (self.animationLarge == YES)
    {
        CGFloat width = self.radius*2;
        CGFloat temWidth = CGRectGetWidth(self.backgroundCircleView.frame);
        if (temWidth >=kBackgroundCircleEndScale*width)
        {
            [self.link invalidate];
            self.link = nil;
            return;
        }
        
        CGFloat backViewRadius =  ((HBlurCircleView *)self.backgroundCircleView).radius+(kBackgroundCircleEndScale-kBackgroundCircleOrgScale)*self.radius/(AnimationDuration*60.0);
        CGFloat topViewRadius = self.topCircleView.radius - (kTopCircleOrgScale-kTopCircleEndScale)*self.radius/(AnimationDuration*60.0);
        
        if ([self.backgroundCircleView isKindOfClass:[HBlurCircleView class]])
        {
            self.backgroundCircleView.frame = CGRectMake((width/2-backViewRadius),(width/2-backViewRadius),backViewRadius*2,backViewRadius*2);
            ((HBlurCircleView *)self.backgroundCircleView).radius = backViewRadius;
            
        }
        else if([self.backgroundCircleView isKindOfClass:[HCircleView class]])
        {
            self.backgroundCircleView.frame = CGRectMake((width/2-backViewRadius),(width/2-backViewRadius),backViewRadius*2,backViewRadius*2);
            ((HCircleView *)self.backgroundCircleView).radius = backViewRadius;
        }
        
        self.topCircleView.frame = CGRectMake((width/2-topViewRadius),(width/2-topViewRadius),topViewRadius*2,topViewRadius*2);
        self.topCircleView.radius = topViewRadius;
        
        self.backgroundCircleView.layer.masksToBounds = YES;
        self.backgroundCircleView.layer.cornerRadius = backViewRadius;
        
        self.topCircleView.layer.masksToBounds = YES;
        self.topCircleView.layer.cornerRadius = topViewRadius;
    }
    else
    {
        CGFloat width = self.radius*2;
        CGFloat temWidth = CGRectGetWidth(self.backgroundCircleView.frame);
        if (temWidth <=kBackgroundCircleOrgScale*width)
        {
            [self.link invalidate];
            self.link = nil;
            return;
        }
        
        CGFloat backViewRadius =  ((HBlurCircleView *)self.backgroundCircleView).radius-(kBackgroundCircleEndScale-kBackgroundCircleOrgScale)*self.radius/(AnimationDuration*60.0);
        CGFloat topViewRadius = self.topCircleView.radius + (kTopCircleOrgScale-kTopCircleEndScale)*self.radius/(AnimationDuration*60.0);
        

        
        if ([self.backgroundCircleView isKindOfClass:[HBlurCircleView class]])
        {
            self.backgroundCircleView.frame = CGRectMake((width/2-backViewRadius),(width/2-backViewRadius),backViewRadius*2,backViewRadius*2);
            ((HBlurCircleView *)self.backgroundCircleView).radius = backViewRadius;
        }
        else
        {
            self.backgroundCircleView.frame = CGRectMake((width/2-backViewRadius),(width/2-backViewRadius),backViewRadius*2,backViewRadius*2);
            ((HCircleView *)self.backgroundCircleView).radius = backViewRadius;
        }
        
        self.topCircleView.frame = CGRectMake((width/2-topViewRadius),(width/2-topViewRadius),topViewRadius*2,topViewRadius*2);
        self.topCircleView.radius = topViewRadius;
        
        self.backgroundCircleView.layer.masksToBounds = YES;
        self.backgroundCircleView.layer.cornerRadius = backViewRadius;
        
        self.topCircleView.layer.masksToBounds = YES;
        self.topCircleView.layer.cornerRadius = topViewRadius;
    }
}


#pragma mark - action -
- (void)touchDownAndDragOutAction:(id)sender
{
    [self.timer fire];
    self.animationLarge = YES;
    self.progress = 0.0;
    [self.link invalidate];
    self.link = nil;
    [self.link addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)touchEndAction:(id)sender
{
    [self.timer invalidate];
    self.timer = nil;
    self.animationLarge = NO;
    
    self.progress = 0.0;
    [self.link invalidate];
    self.link = nil;
    [self.link addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(touchEndAction:)])
    {
        [self.delegate touchEndAction:self];
    }
}

#pragma mark -
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSLog(@"TouchBeginTime：%@",[NSDate date]);
    [super touchesBegan:touches withEvent:event];
    UITouch *touch = [touches.allObjects objectAtIndex:0];
    self.startPoint = [touch locationInView:self];
    self.currectPoint = self.startPoint;
    self.endPoint = self.startPoint;
    
    [self touchDownAndDragOutAction:nil];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    working = NO;
    self.startPoint = CGPointZero;
    self.currectPoint = self.startPoint;
    self.endPoint = self.startPoint;
    [self touchEndAction:nil];
    [super touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    working = NO;
    self.startPoint = CGPointZero;
    self.currectPoint = self.startPoint;
    self.endPoint = self.startPoint;
    
    [self touchEndAction:nil];
    [super touchesCancelled:touches withEvent:event];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(touchMove:)])
    {
        [self.delegate touchMove:touches];
    }
    
    UITouch *touch = [touches.allObjects objectAtIndex:0];
    
    CGPoint point = [touch locationInView:self];
    
    BOOL ret = CGRectContainsPoint(self.bounds,point);
    if (ret == NO)
    {
        CGFloat speedY = (point.y-self.currectPoint.y)/0.02;
        
        self.currectPoint = point;
        self.endPoint = self.currectPoint;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(touchMoveSpeedY:)])
        {
            [self.delegate touchMoveSpeedY:speedY];
        }
    }
    
    [super touchesMoved:touches withEvent:event];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    BOOL ret = CGRectContainsPoint(self.bounds,point);
    
    if (working && ret)
    {
        return ret;
    }
    
    if (ret)
    {
        working = YES;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(eventDownButtonBeganTouchDown)])
        {
            [self.delegate eventDownButtonBeganTouchDown];
        }
    }
    else
    {
        if (self.delegate && [self.delegate respondsToSelector:@selector(eventDownButtonOutOfView)])
        {
            [self.delegate eventDownButtonOutOfView];
        }
    }
    return ret;
}


@end
