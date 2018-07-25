//
//  HRecordVideoManager.m
//  reliao
//
//  Created by liyanjun on 16/9/26.
//
//

#import "HRecordVideoManager.h"
#import "HRecordVideoEncoder.h"
#import <AVFoundation/AVFoundation.h>
#import "HAuthorizationCenter.h"
#import "UIImage+Extension.h"
#import <CoreMotion/CoreMotion.h>

@interface HRecordVideoManager ()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate,CAAnimationDelegate>
{
    CMTime _timeOffset;//录制的偏移CMTime
    CMTime _lastVideo;//记录上一次视频数据文件的CMTime
    CMTime _lastAudio;//记录上一次音频数据文件的CMTime
    
    NSInteger _cx;//视频分辨的宽
    NSInteger _cy;//视频分辨的高
    int _channels;//音频通道
    Float64 _samplerate;//音频采样率
}

@property (strong, nonatomic) HRecordVideoEncoder     *recordEncoder;//录制编码
@property (strong, nonatomic) AVCaptureSession           *recordSession;//捕获视频的会话
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;//捕获到的视频呈现的layer
@property (strong, nonatomic) AVCaptureDeviceInput       *backCameraInput;//后置摄像头输入
@property (strong, nonatomic) AVCaptureDeviceInput       *frontCameraInput;//前置摄像头输入
@property (strong, nonatomic) AVCaptureDeviceInput       *audioMicInput;//麦克风输入
@property (copy  , nonatomic) dispatch_queue_t           captureQueue;//录制的队列
@property (strong, nonatomic) AVCaptureConnection        *audioConnection;//音频录制连接
@property (strong, nonatomic) AVCaptureConnection        *videoConnection;//视频录制连接
@property (strong, nonatomic) AVCaptureVideoDataOutput   *videoOutput;//视频输出
@property (strong, nonatomic) AVCaptureAudioDataOutput   *audioOutput;//音频输出
@property (strong, nonatomic) AVCaptureStillImageOutput  *imageOutput; //图片输出
@property (strong, nonatomic) AVCaptureDevice *currectCaptureDevice; //当前的摄像头
@property (atomic, assign) BOOL isCapturing;//正在录制
@property (atomic, assign) BOOL isPaused;//是否暂停
@property (atomic, assign) BOOL discont;//是否中断
@property (atomic, assign) CMTime startTime;//开始录制的时间
@property (atomic, assign) CGFloat currentRecordTime;//当前录制时间
@property (nonatomic, assign) BOOL microphoneEnable; //是否有麦克风权限

@property (nonatomic, strong) CMMotionManager *motionManager; //重力感应来判断方向
@property (nonatomic, assign) UIInterfaceOrientation deviceOrientation; //设备方向

@end

@implementation HRecordVideoManager


- (void)dealloc
{
    [self.recordSession stopRunning];
    self.captureQueue     = nil;
    self.recordSession    = nil;
    self.previewLayer     = nil;
    self.backCameraInput  = nil;
    self.frontCameraInput = nil;
    self.audioOutput      = nil;
    self.videoOutput      = nil;
    self.audioConnection  = nil;
    self.videoConnection  = nil;
    self.recordEncoder    = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.maxRecordTime = 10.0f;
        self.isFrontCapture = NO;
        
        if (self.motionManager.deviceMotionAvailable)
        {
            WS
            [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMDeviceMotion * _Nullable motion, NSError * _Nullable error) {
                SS
                [self performSelectorOnMainThread:@selector(handleDeviceMotion:) withObject:motion waitUntilDone:YES];
            }];
        }
    }
    
    return self;
}

#pragma mark - 公开的方法
//启动录制功能
- (void)startUp
{
    //    NSLog(@"启动录制功能");
    self.startTime = CMTimeMake(0, 0);
    self.isCapturing = NO;
    self.isPaused = NO;
    self.discont = NO;
    [self.recordSession startRunning];
}
//关闭录制功能
- (void)shutdown
{
    self.startTime = CMTimeMake(0, 0);
    if (self.recordSession)
    {
        [self.recordSession stopRunning];
    }
    
    [self.recordEncoder finishWithCompletionHandler:^{
       
    }];
}

//开始录制
- (void) startCapture
{
    @synchronized(self)
    {
        if (!self.isCapturing)
        {
            if (self.videoPath == nil || self.videoPath.length == 0)
            {
                NSString *videoName = [self getUploadFile_type:@"video" fileType:@"mp4"];
                self.videoPath = [[self getVideoCachePath] stringByAppendingPathComponent:videoName];
            }
            
            //因为其他方向录制的小视频会掉整方向，因此存储的地址+_Tem
            if (self.deviceOrientation != UIInterfaceOrientationPortrait)
            {
                self.startRecordingOrientation = self.deviceOrientation;
                
                NSRange rang =  [self.videoPath rangeOfString:@".mp4"];
                
                if (rang.location != NSNotFound)
                {
                    NSMutableString *temString = [NSMutableString stringWithFormat:@"%@_Tem.mp4",[self.videoPath substringToIndex:rang.location]];
                    self.videoPath = temString;
                }
            }
            else
            {
                self.startRecordingOrientation = UIInterfaceOrientationPortrait;
            }
            
            _cx = RecordingSize_S;
            _cy = RecordingSize_L;
            
            __block BOOL bCanRecord = YES;
            AVAudioSession *session = [AVAudioSession sharedInstance];
            if ([session respondsToSelector:@selector(requestRecordPermission:)])
            {
                [session performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted) {
                    if (granted)
                    {
                        bCanRecord = YES;
                    }
                    else
                    {
                        bCanRecord = NO;
                    }
                }];
            }
            
            self.microphoneEnable = bCanRecord;
            
            self.recordEncoder = nil;
            self.isPaused = NO;
            self.discont = NO;
            self.currentRecordTime = 0.0;
            _timeOffset = CMTimeMake(0, 0);
            self.isCapturing = YES;
            
            if (self.microphoneEnable == NO)
            {
                self.recordEncoder = [HRecordVideoEncoder encoderForPath:self.videoPath Height:_cy width:_cx channels:_channels samples:0.0];
            }
            else
            {
                self.recordEncoder = [HRecordVideoEncoder encoderForPath:self.videoPath Height:_cy width:_cx channels:1 samples:44100.0];
            }
        }
    }
}
//暂停录制
- (void) pauseCapture
{
    @synchronized(self)
    {
        if (self.isCapturing)
        {
            self.isPaused = YES;
            self.discont = YES;
        }
    }
}
//继续录制
- (void)resumeCapture
{
    @synchronized(self)
    {
        if (self.isPaused)
        {
            self.isPaused = NO;
        }
    }
}
//停止录制
- (void)stopCaptureHandler:(void (^)(void))handler
{
    @synchronized(self)
    {
        if (self.isCapturing)
        {
            self.isCapturing = NO;
            WS
            dispatch_async(self.captureQueue, ^{
                SS
                [self.recordEncoder finishWithCompletionHandler:^{
                    SS
                    self.isCapturing = NO;
                    self.startTime = CMTimeMake(0, 0);
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (handler)
                        {
                            handler();
                        }
                    });
                }];
            });
        }
    }
}

//取消录制
- (void)cancelCapture
{
     @synchronized(self)
    {
         if (self.isCapturing)
         {
             self.isCapturing = NO;
         }
        
         self.startTime = CMTimeMake(0, 0);
         self.currentRecordTime = 0;
         
         [[NSFileManager defaultManager] removeItemAtPath:self.videoPath error:nil];
     }
}

//获取视频第一帧的图片
- (void)movieToImageHandler:(void (^)(UIImage *movieImage))handler
{
    NSURL *url = [NSURL fileURLWithPath:self.videoPath];
    NSDictionary *opts = @{AVURLAssetPreferPreciseDurationAndTimingKey:@(NO)};
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:opts];
    AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    // 应用方向
    gen.appliesPreferredTrackTransform = YES;
    CMTime time = CMTimeMakeWithSeconds(0.0, 30);
    NSError *error = nil;
    CMTime actualTime;
    CGImageRef image = [gen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    if(error && image == NULL)
    {
        handler(nil);
        return;
    }
    
    UIImage *thumbImg = [[UIImage alloc] initWithCGImage:image];
    CGImageRelease(image);    
    dispatch_async(dispatch_get_main_queue(), ^{
        handler(thumbImg);
    });
}

// 焦距范围0.0-1.0
- (void)cameraBackgroundDidChangeFocus:(CGFloat)focus
{
    AVCaptureDevice *captureDevice = self.currectCaptureDevice;
    NSError *error;
    if ([captureDevice lockForConfiguration:&error])
    {
        if ([captureDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus])
        {
            [captureDevice setFocusModeLockedWithLensPosition:focus completionHandler:nil];
        }
    }
    else
    {
        
    }
}

// 数码变焦 1-4倍
- (void)setCaptureDeviceFocusDidChangeZoom:(CGFloat)zoom
{
    AVCaptureDevice *captureDevice = self.currectCaptureDevice;
    NSError *error;
    if ([captureDevice lockForConfiguration:&error])
    {
        [captureDevice rampToVideoZoomFactor:zoom withRate:50];
    }
    else
    {
        // Handle the error appropriately.
    }
    
   NSLog(@"videoMaxZoomFactor:%f", self.currectCaptureDevice.activeFormat.videoMaxZoomFactor);
}

#pragma mark - 点击屏幕对焦
- (void)setCaptureDeviceAutoFocusWithPoint:(CGPoint)point
{
    AVCaptureDevice *captureDevice = self.currectCaptureDevice;
    NSError *error;
    if ([captureDevice lockForConfiguration:&error])
    {
        CGPoint location = point;
        CGSize frameSize = self.previewLayer.frame.size;
        if ([captureDevice position] == AVCaptureDevicePositionFront)
        {
            location.x = frameSize.width - location.x;
        }
        
        CGPoint pointOfInerest = CGPointMake(location.y / frameSize.height, 1.f - (location.x / frameSize.width));
        [self focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposureMode:AVCaptureExposureModeContinuousAutoExposure atPoint:pointOfInerest];
    }
    else
    {
        // Handle the error appropriately.
    }
}

-(void)focusWithMode:(AVCaptureFocusMode)focusMode exposureMode:(AVCaptureExposureMode)exposureMode atPoint:(CGPoint)point
{
    AVCaptureDevice *captureDevice = self.currectCaptureDevice;
    NSError *error;
    if ([captureDevice lockForConfiguration:&error])
    {
        if ([captureDevice isFocusModeSupported:focusMode])
        {
            [captureDevice setFocusMode:focusMode];
        }
        
        if ([captureDevice isFocusPointOfInterestSupported])
        {
            [captureDevice setFocusPointOfInterest:point];
        }
        
        if ([captureDevice isExposureModeSupported:exposureMode])
        {
            [captureDevice setExposureMode:exposureMode];
        }
        
        if ([captureDevice isExposurePointOfInterestSupported])
        {
            [captureDevice setExposurePointOfInterest:point];
        }
    }
    else
    {
      
    }
}

- (void)focusContinuousAutoFocusAndContinuousAutoExposure
{
    AVCaptureDevice *captureDevice = self.currectCaptureDevice;
    NSError *error;
    if ([captureDevice lockForConfiguration:&error])
    {
        if ([captureDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus])
        {
            [captureDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
        }
        
        if ([captureDevice isFocusPointOfInterestSupported])
        {
            [captureDevice setFocusPointOfInterest:CGPointMake(SCREEN_WIDTH/2, SCREEN_HEIGHT/2)];
        }
        
        if ([captureDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure])
        {
            [captureDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
        }
        
        if ([captureDevice isExposurePointOfInterestSupported])
        {
            [captureDevice setExposurePointOfInterest:CGPointMake(SCREEN_WIDTH/2, SCREEN_HEIGHT/2)];
        }
    }
    else
    {
        
    }
}

- (CGFloat)getVideoMaxScaleAndCropFactor
{
    return self.videoConnection.videoMaxScaleAndCropFactor;
}

#pragma mark - set、get方法
//捕获视频的会话
- (AVCaptureSession *)recordSession
{
    if (_recordSession == nil)
    {
        _recordSession = [[AVCaptureSession alloc] init];
        if ([_recordSession canSetSessionPreset:AVCaptureSessionPresetiFrame960x540])
        {
            [_recordSession setSessionPreset:AVCaptureSessionPresetiFrame960x540];
        }
        else
        {
            [_recordSession setSessionPreset:AVCaptureSessionPresetHigh];
        }
        
        //添加后置摄像头的输出
        if ([_recordSession canAddInput:self.backCameraInput])
        {
            [_recordSession addInput:self.backCameraInput];
        }
        //添加后置麦克风的输出
        if ([_recordSession canAddInput:self.audioMicInput])
        {
            [_recordSession addInput:self.audioMicInput];
        }
        //添加视频输出
        if ([_recordSession canAddOutput:self.videoOutput])
        {
            [_recordSession addOutput:self.videoOutput];
        }
        //添加音频输出
        if ([_recordSession canAddOutput:self.audioOutput])
        {
            [_recordSession addOutput:self.audioOutput];
        }
        
        //添加图片输出
        if ([_recordSession canAddOutput:self.imageOutput])
        {
            [_recordSession addOutput:self.imageOutput];
        }
        
        self.videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
        
        self.currectCaptureDevice = [self backCamera];
        
        if ([self.currectCaptureDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus] && [self.currectCaptureDevice lockForConfiguration:nil])
        {
            [self.currectCaptureDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
            [self.currectCaptureDevice unlockForConfiguration];
        }
        
    }
    return _recordSession;
}

//后置摄像头输入
- (AVCaptureDeviceInput *)backCameraInput
{
    if (_backCameraInput == nil)
    {
        NSError *error;
        _backCameraInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self backCamera] error:&error];
        if (error)
        {
            NSLog(@"获取后置摄像头失败~");
        }
    }
    return _backCameraInput;
}

//前置摄像头输入
- (AVCaptureDeviceInput *)frontCameraInput
{
    if (_frontCameraInput == nil)
    {
        NSError *error;
        _frontCameraInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self frontCamera] error:&error];
        if (error)
        {
            NSLog(@"获取前置摄像头失败~");
        }
    }
    return _frontCameraInput;
}

//麦克风输入
- (AVCaptureDeviceInput *)audioMicInput
{
    if (_audioMicInput == nil)
    {
        AVCaptureDevice *mic = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        NSError *error;
        _audioMicInput = [AVCaptureDeviceInput deviceInputWithDevice:mic error:&error];
        if (error)
        {
            NSLog(@"获取麦克风失败~");
        }
    }
    return _audioMicInput;
}

//视频输出
- (AVCaptureVideoDataOutput *)videoOutput
{
    if (_videoOutput == nil)
    {
        _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
        _videoOutput.alwaysDiscardsLateVideoFrames = YES;
        [_videoOutput setSampleBufferDelegate:self queue:self.captureQueue];
        NSDictionary* setcapSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange], kCVPixelBufferPixelFormatTypeKey,
                                        nil];
        _videoOutput.videoSettings = setcapSettings;
    }
    return _videoOutput;
}

- (AVCaptureStillImageOutput *)imageOutput
{
    if (_imageOutput == nil)
    {
        _imageOutput = [AVCaptureStillImageOutput new];
    }
    
    return _imageOutput;
}


//音频输出
- (AVCaptureAudioDataOutput *)audioOutput
{
    if (_audioOutput == nil)
    {
        _audioOutput = [[AVCaptureAudioDataOutput alloc] init];
        [_audioOutput setSampleBufferDelegate:self queue:self.captureQueue];
        
    }
    
    return _audioOutput;
}

//视频连接
- (AVCaptureConnection *)videoConnection
{
    _videoConnection = [self.videoOutput connectionWithMediaType:AVMediaTypeVideo];
    
    if ([_videoConnection isVideoStabilizationSupported])
    {
        [_videoConnection setPreferredVideoStabilizationMode:AVCaptureVideoStabilizationModeAuto];
    }
    
    return _videoConnection;
}

//音频连接
- (AVCaptureConnection *)audioConnection
{
    if (_audioConnection == nil)
    {
        _audioConnection = [self.audioOutput connectionWithMediaType:AVMediaTypeAudio];
    }
    return _audioConnection;
}

//捕获到的视频呈现的layer
- (AVCaptureVideoPreviewLayer *)previewLayer
{
    if (_previewLayer == nil)
    {
        //通过AVCaptureSession初始化
        AVCaptureVideoPreviewLayer *preview = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.recordSession];
        //设置比例为铺满全屏
        
        preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
        _previewLayer = preview;
    }
    return _previewLayer;
}

//录制的队列
- (dispatch_queue_t)captureQueue
{
    if (_captureQueue == nil)
    {
        _captureQueue = dispatch_queue_create("recordvedio", DISPATCH_QUEUE_SERIAL);
    }
    return _captureQueue;
}

- (CMMotionManager *)motionManager
{
    if (_motionManager == nil)
    {
        _motionManager = [[CMMotionManager alloc] init];
        _motionManager.deviceMotionUpdateInterval = 1/15.0;
        
    }
    return _motionManager;
}

#pragma mark -处理重力感应方向
- (void)handleDeviceMotion:(CMDeviceMotion *)deviceMotion
{
    double x = deviceMotion.gravity.x;
    double y = deviceMotion.gravity.y;
    
    if (fabs(y) >= fabs(x))
    {
        if (y >= 0)
        {
            _deviceOrientation = UIInterfaceOrientationPortraitUpsideDown;
        }
        else
        {
            _deviceOrientation = UIInterfaceOrientationPortrait;
        }
    }
    else
    {
        if (x >= 0)
        {
            _deviceOrientation = UIInterfaceOrientationLandscapeRight;    // Home键左侧水平拍摄
        }
        else
        {
            _deviceOrientation = UIInterfaceOrientationLandscapeLeft;     // Home键右侧水平拍摄
        }
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(recordVideoDeviceOrientationChanged:)])
    {
        [self.delegate recordVideoDeviceOrientationChanged:_deviceOrientation];
    }
}

#pragma mark - 切换动画
- (void)changeCameraAnimation
{
    CATransition *changeAnimation = [CATransition animation];
    [changeAnimation setDelegate:self];
    changeAnimation.duration = 0.45;
    changeAnimation.type = @"oglFlip";
    changeAnimation.subtype = kCATransitionFromRight;
    changeAnimation.timingFunction = UIViewAnimationCurveEaseInOut;
    [self.previewLayer addAnimation:changeAnimation forKey:@"changeAnimation"];
}

- (void)animationDidStart:(CAAnimation *)anim
{
    [self.recordSession startRunning];
}

#pragma -mark 将mov文件转为MP4文件
- (void)changeMovToMp4:(NSURL *)mediaURL dataBlock:(void (^)(UIImage *movieImage))handler
{
    AVAsset *video = [AVAsset assetWithURL:mediaURL];
    AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:video presetName:AVAssetExportPreset960x540];
    exportSession.shouldOptimizeForNetworkUse = YES;
    exportSession.outputFileType = AVFileTypeMPEG4;
    NSString * basePath=[self getVideoCachePath];
    if (self.videoPath == nil)
    {
        self.videoPath = [basePath stringByAppendingPathComponent:[self getUploadFile_type:@"video" fileType:@"mp4"]];
    }
    exportSession.outputURL = [NSURL fileURLWithPath:self.videoPath];
    WS
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        SS
        [self movieToImageHandler:handler];
    }];
}

- (void)setVedioWidth:(NSInteger)width height:(NSInteger)height
{
    _cx = width;
    _cy = height;
}

#pragma mark - 视频相关
//返回前置摄像头
- (AVCaptureDevice *)frontCamera
{
    return [self cameraWithPosition:AVCaptureDevicePositionFront];
}

//返回后置摄像头
- (AVCaptureDevice *)backCamera
{
    return [self cameraWithPosition:AVCaptureDevicePositionBack];
}

- (AVCaptureDevice *)currectCaptureDevice
{
    if (self.isFrontCapture)
    {
        _currectCaptureDevice = [self.frontCameraInput device];
        
    }
    else
    {
        _currectCaptureDevice = [self.backCameraInput device];
    }
    
    return _currectCaptureDevice;
}

//切换前后置摄像头
- (void)changeCameraInputDeviceisFront:(BOOL)isFront
{
    if (isFront)
    {
        self.isFrontCapture = YES;
        [self.recordSession stopRunning];
        [self.recordSession removeInput:self.backCameraInput];
        if ([self.recordSession canAddInput:self.frontCameraInput])
        {
            [self changeCameraAnimation];
            [self.recordSession addInput:self.frontCameraInput];
        }
        
        self.currectCaptureDevice = [self frontCamera];
        
        self.videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
        
        if (self.videoConnection.supportsVideoMirroring)
        {
            self.videoConnection.videoMirrored = YES;
        }
    }
    else
    {
        self.isFrontCapture = NO;
        [self.recordSession stopRunning];
        [self.recordSession removeInput:self.frontCameraInput];
        if ([self.recordSession canAddInput:self.backCameraInput])
        {
            [self changeCameraAnimation];
            [self.recordSession addInput:self.backCameraInput];
        }
        
        self.currectCaptureDevice = [self backCamera];
        
        self.videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
        if (self.videoConnection.supportsVideoMirroring)
        {
            self.videoConnection.videoMirrored = NO;
        }
    }
}

//用来返回是前置摄像头还是后置摄像头
- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition) position
{
    //返回和视频录制相关的所有默认设备
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    //遍历这些设备返回跟position相关的设备
    for (AVCaptureDevice *device in devices)
    {
        if ([device position] == position)
        {
            return device;
        }
    }
    return nil;
}

//开启闪光灯
- (void)openFlashLight
{
    AVCaptureDevice *backCamera = [self backCamera];
    if (backCamera.torchMode == AVCaptureTorchModeOff)
    {
        [backCamera lockForConfiguration:nil];
        backCamera.torchMode = AVCaptureTorchModeOn;
        backCamera.flashMode = AVCaptureFlashModeOn;
        [backCamera unlockForConfiguration];
    }
}
//关闭闪光灯
- (void)closeFlashLight
{
    AVCaptureDevice *backCamera = [self backCamera];
    if (backCamera.torchMode == AVCaptureTorchModeOn)
    {
        [backCamera lockForConfiguration:nil];
        backCamera.torchMode = AVCaptureTorchModeOff;
        backCamera.flashMode = AVCaptureTorchModeOff;
        [backCamera unlockForConfiguration];
    }
}

//获得视频存放地址
- (NSString *)getVideoCachePath
{
    NSString *videoCache = [NSTemporaryDirectory() stringByAppendingPathComponent:@"videos"] ;
    BOOL isDir = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL existed = [fileManager fileExistsAtPath:videoCache isDirectory:&isDir];
    if ( !(isDir == YES && existed == YES) )
    {
        [fileManager createDirectoryAtPath:videoCache withIntermediateDirectories:YES attributes:nil error:nil];
    };
    return videoCache;
}

- (NSString *)getUploadFile_type:(NSString *)type fileType:(NSString *)fileType
{
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HHmmss"];
    NSDate * NowDate = [NSDate dateWithTimeIntervalSince1970:now];
    ;
    NSString * timeStr = [formatter stringFromDate:NowDate];
    NSString *fileName = [NSString stringWithFormat:@"%@_%@.%@",type,timeStr,fileType];
    return fileName;
}

#pragma mark - 写入数据
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    @autoreleasepool
    {
        BOOL isVideo = YES;
        @synchronized(self)
        {
            if (!self.isCapturing  || self.isPaused)
            {
                return;
            }
            
            if (captureOutput != self.videoOutput)
            {
                isVideo = NO;
            }
            
            //判断是否中断录制过
            if (self.discont)
            {
                if (isVideo)
                {
                    return;
                }
                self.discont = NO;
                // 计算暂停的时间
                CMTime pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
                CMTime last = isVideo ? _lastVideo : _lastAudio;
                if (last.flags & kCMTimeFlags_Valid)
                {
                    if (_timeOffset.flags & kCMTimeFlags_Valid)
                    {
                        pts = CMTimeSubtract(pts, _timeOffset);
                    }
                    CMTime offset = CMTimeSubtract(pts, last);
                    if (_timeOffset.value == 0)
                    {
                        _timeOffset = offset;
                    }
                    else
                    {
                        _timeOffset = CMTimeAdd(_timeOffset, offset);
                    }
                }
                _lastVideo.flags = 0;
                _lastAudio.flags = 0;
            }
            // 增加sampleBuffer的引用计时,这样我们可以释放这个或修改这个数据，防止在修改时被释放
            CFRetain(sampleBuffer);
            if (_timeOffset.value > 0)
            {
                CFRelease(sampleBuffer);
                //根据得到的timeOffset调整
                sampleBuffer = [self adjustTime:sampleBuffer by:_timeOffset];
            }
            // 记录暂停上一次录制的时间
            CMTime pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
            CMTime dur = CMSampleBufferGetDuration(sampleBuffer);
            if (dur.value > 0)
            {
                pts = CMTimeAdd(pts, dur);
            }
            
            if (isVideo)
            {
                _lastVideo = pts;
            }
            else
            {
                _lastAudio = pts;
            }
        }
        CMTime dur = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        if (self.startTime.value == 0)
        {
            self.startTime = dur;
        }
        CMTime sub = CMTimeSubtract(dur, self.startTime);
        self.currentRecordTime = CMTimeGetSeconds(sub);
        if (self.currentRecordTime > self.maxRecordTime)
        {
            if (self.currentRecordTime - self.maxRecordTime < 0.1)
            {
                if ([self.delegate respondsToSelector:@selector(recordProgress:)])
                {
                    WS
                    dispatch_async(dispatch_get_main_queue(), ^{
                        SS
                        [self.delegate recordProgress:self.currentRecordTime/self.maxRecordTime];
                    });
                }
            }
            return;
        }
        
        if ([self.delegate respondsToSelector:@selector(recordProgress:)])
        {
            WS
            dispatch_async(dispatch_get_main_queue(), ^{
                SS
                [self.delegate recordProgress:self.currentRecordTime/self.maxRecordTime];
            });
        }
        // 进行数据编码
        [self.recordEncoder encodeFrame:sampleBuffer isVideo:isVideo];
        CFRelease(sampleBuffer);
        
    }
}

//调整媒体数据的时间
- (CMSampleBufferRef)adjustTime:(CMSampleBufferRef)sample by:(CMTime)offset
{
    CMItemCount count;
    CMSampleBufferGetSampleTimingInfoArray(sample, 0, nil, &count);
    CMSampleTimingInfo* pInfo = malloc(sizeof(CMSampleTimingInfo) * count);
    CMSampleBufferGetSampleTimingInfoArray(sample, count, pInfo, &count);
    for (CMItemCount i = 0; i < count; i++)
    {
        pInfo[i].decodeTimeStamp = CMTimeSubtract(pInfo[i].decodeTimeStamp, offset);
        pInfo[i].presentationTimeStamp = CMTimeSubtract(pInfo[i].presentationTimeStamp, offset);
    }
    CMSampleBufferRef sout;
    CMSampleBufferCreateCopyWithNewTiming(nil, sample, count, pInfo, &sout);
    free(pInfo);
    return sout;
}

+ (UIImage*)thumbnailImageForVideo:(NSURL *)videoURL atTime:(NSTimeInterval)time
{
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
    NSParameterAssert(asset);
    AVAssetImageGenerator *assetImageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    assetImageGenerator.appliesPreferredTrackTransform = YES;
    assetImageGenerator.apertureMode =AVAssetImageGeneratorApertureModeEncodedPixels;
    
    CGImageRef thumbnailImageRef = NULL;
    CFTimeInterval thumbnailImageTime = time;
    NSError *thumbnailImageGenerationError = nil;
    thumbnailImageRef = [assetImageGenerator copyCGImageAtTime:CMTimeMake(thumbnailImageTime, 60)actualTime:NULL error:&thumbnailImageGenerationError];
    
    if(!thumbnailImageRef)
        NSLog(@"thumbnailImageGenerationError %@",thumbnailImageGenerationError.domain);
    
    UIImage *thumbnailImage = thumbnailImageRef ? [[UIImage alloc]initWithCGImage:thumbnailImageRef] : nil;
    return thumbnailImage;
}


@end
