//
//  HDevice+Motion.m
//  HDevice
//
//  Created by liyanjun on 16/3/24.
//  Copyright © 2016年 liyanjun. All rights reserved.
//

#import "HDevice+Motion.h"
#import <objc/runtime.h>

@implementation HDevice (Motion)

static const void *temMotion = &temMotion;
static NSUInteger startTimes = 0;

@dynamic motion;

- (void)init_motion
{
    startTimes = 0;
    self.motion = [[CMMotionManager alloc] init];
    if (self.motion.accelerometerAvailable)
    {
        self.motion.accelerometerUpdateInterval = 1.0 / 100.0;
    }
}

- (void)dealloc_motion
{
    self.motion = nil;
}

- (void)setMotion:(CMMotionManager *)motion
{
    objc_setAssociatedObject(self, temMotion, motion, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CMMotionManager *)motion
{
    return objc_getAssociatedObject(self, temMotion);
}


/**
 *  开始加速器
 */
- (void)startAccelerometer
{
    if (self.motion)
    {
        //添加一个计数，防止出现开启和关闭不配对导致出现bug的情况
        @synchronized(self)
        {
            if (startTimes == 0)
            {
                [self.motion startAccelerometerUpdates];
            }

            startTimes += 1;
        }
    }
}

/**
 *  停止加速器
 */
- (void)stopAccelerometer
{
    if (self.motion)
    {
        @synchronized(self)
        {
            if (startTimes == 1)
            {
                [self.motion stopAccelerometerUpdates];
            }

            startTimes -= 1;
        }
    }
}


/**
 *  得到方向，重要，此方向会成为图片exif信息的来源。
 *
 *  @return 直接返回的为AVCaptureVideoOrientation，方便调用
 */
- (AVCaptureVideoOrientation)captureOrientation
{
    AVCaptureVideoOrientation captureVideoOrientation = AVCaptureVideoOrientationPortrait;
    CMAcceleration accleleration = self.motion.accelerometerData.acceleration;
    float x = accleleration.x;
    float y = accleleration.y;
    float angle = atan2(y, x);

    if (angle >= -2.25 && angle <= -0.25)
    {
        captureVideoOrientation = AVCaptureVideoOrientationPortrait;
    }
    else if (angle >= -1.75 && angle <= 0.75)
    {
        captureVideoOrientation = AVCaptureVideoOrientationLandscapeLeft;
    }
    else if (angle >= 0.75 && angle <= 2.25)
    {
        captureVideoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
    }
    else if (angle <= -2.25 || angle >= 2.25)
    {
        captureVideoOrientation = AVCaptureVideoOrientationLandscapeRight;
    }
    return captureVideoOrientation;
}

@end
