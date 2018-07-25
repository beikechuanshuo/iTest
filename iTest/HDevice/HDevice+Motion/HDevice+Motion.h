//
//  HDevice+Motion.h
//  HDevice
//
//  Created by liyanjun on 16/3/24.
//  Copyright © 2016年 liyanjun. All rights reserved.
//

#import "HDevice.h"
#import <CoreMotion/CoreMotion.h>
#import <AVFoundation/AVCaptureSession.h>

@interface HDevice (Motion)

/**
 * 扩展私有属性，请不要对外使用
 */
@property (nonatomic) CMMotionManager *motion;

/**
 *  开始加速器
 */
- (void)startAccelerometer;

/**
 *  停止加速器
 */
- (void)stopAccelerometer;


/**
 *  得到方向，重要，此方向会成为图片exif信息的来源，不要轻易修改此函数。
 *
 *  @return 直接返回的为AVCaptureVideoOrientation，方便调用
 */
- (AVCaptureVideoOrientation)captureOrientation;

@end
