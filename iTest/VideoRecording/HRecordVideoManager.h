//
//  HRecordVideoManager.h
//  reliao
//
//  Created by liyanjun on 16/9/26.
//
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "AVSERotateCommand.h"

#define RecordingSize_L 960 //长边
#define RecordingSize_S 540 //短边

@protocol HRecordVideoManagerDelegate <NSObject>

- (void)recordProgress:(CGFloat)progress;

- (void)recordVideoDeviceOrientationChanged:(UIInterfaceOrientation)orientation;

@end

@interface HRecordVideoManager : NSObject

@property (atomic, assign, readonly) BOOL isCapturing;//正在录制
@property (atomic, assign, readonly) BOOL isPaused;//是否暂停
@property (atomic, assign, readonly) CGFloat currentRecordTime;//当前录制时间
@property (atomic, assign) CGFloat maxRecordTime;//录制最长时间
@property (atomic, strong) NSString *videoPath;//视频路径
@property (nonatomic, assign) BOOL isFrontCapture; //是否时前置摄像头

@property (nonatomic, weak) id<HRecordVideoManagerDelegate> delegate;

@property (nonatomic, assign) UIInterfaceOrientation startRecordingOrientation; //开始录制时的方向

//捕获到的视频呈现的layer
- (AVCaptureVideoPreviewLayer *)previewLayer;
//启动录制功能
- (void)startUp;
//关闭录制功能
- (void)shutdown;
//开始录制
- (void)startCapture;
//暂停录制
- (void)pauseCapture;
//停止录制
- (void)stopCaptureHandler:(void (^)(void))handler;
//继续录制
- (void)resumeCapture;
//取消录制
- (void)cancelCapture;
//开启闪光灯
- (void)openFlashLight;
//关闭闪光灯
- (void)closeFlashLight;
//切换前后置摄像头
- (void)changeCameraInputDeviceisFront:(BOOL)isFront;
//将mov的视频转成mp4
- (void)changeMovToMp4:(NSURL *)mediaURL dataBlock:(void (^)(UIImage *movieImage))handler;
//设置录像的尺寸
- (void)setVedioWidth:(NSInteger)width height:(NSInteger)height;

// 数码变焦 1-3倍
- (void)setCaptureDeviceFocusDidChangeZoom:(CGFloat)zoom;

// 焦距范围0.0-1.0
- (void)cameraBackgroundDidChangeFocus:(CGFloat)focus;

//自动对焦
- (void)setCaptureDeviceAutoFocusWithPoint:(CGPoint)point;

//获取最大焦距
- (CGFloat)getVideoMaxScaleAndCropFactor;

//
-(void)focusContinuousAutoFocusAndContinuousAutoExposure;

+ (UIImage*)thumbnailImageForVideo:(NSURL *)videoURL atTime:(NSTimeInterval)time;

@end
