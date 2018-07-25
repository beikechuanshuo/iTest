//
//  HNewRecordingViewController.m
//  reliao
//
//  Created by liyanjun on 2017/6/7.
//  Copyright © 2017年 liyanjun. All rights reserved.
//

#import "HNewRecordingViewController.h"
#import "HRecordingCircleButton.h"
#import "HRecordVideoManager.h"
#import "HRecordVideoEncoder.h"
#import "NSFileManager+Extension.h"
#import "AVSEExportCommand.h"
#import "AVSERotateCommand.h"
#import "AVSECommand.h"
#import "UIColor+Extension.h"
#import "UIImage+Extension.h"
#import <Photos/Photos.h>
#import "HHUDViewController.h"

#define RecordingBtn_Radius 60
#define RecordingSpace_Bottom 56
#define ChangeCaptureBtnWidth_Height 58
#define BackBtnWidth_Height 58

#define PinchMaxScale 4.0
#define PinchMinScale 1.0

#define RecordMaxDuration 10.0

@interface HNewRecordingViewController ()<HRecordVideoManagerDelegate,HRecordingCircleButtonDeletage>

@property (nonatomic, strong) HRecordingCircleButton *recordingBtn;
@property (nonatomic, strong) UIButton *changeCapture;
@property (nonatomic, strong) UIButton *backCapture;
@property (nonatomic, strong) HRecordVideoManager *recordManager;
@property (nonatomic, strong) HRecordVideoEncoder *recordEncoder;
@property (nonatomic, assign) BOOL isFrontCapture;
@property (nonatomic, assign) BOOL recording; //是否正在录制
@property (nonatomic, strong) UIView *recoderPreview;

@property (nonatomic, copy) NSString *saveFilePath;
@property (nonatomic, copy) NSString *videoName;
@property (nonatomic, copy) NSString *uploadURL;

@property (nonatomic, assign) CGFloat totalPinchScale;

//回放的view
@property (nonatomic, strong) UIView *replayView;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;

//旋转等编辑
@property (nonatomic, strong) AVMutableComposition *composition;
@property (nonatomic, strong) AVMutableVideoComposition *videoComposition;
@property (nonatomic, strong) AVMutableAudioMix *audioMix;
@property (nonatomic, strong) AVAsset *inputAsset;
@property (nonatomic, strong) AVSEExportCommand *exportCommand;
@property (nonatomic, strong) UIView *blurBackgroundView; //返回录音的背景高斯模糊view
@property (nonatomic, strong) UIView *sendBackgroundView;
@property (nonatomic, strong) UIButton *backToRecordBtn;
@property (nonatomic, strong) UIButton *sendBtn;

@property (nonatomic, strong) AVAudioSession *audioSession;

@property (nonatomic, strong) UIImage *coverImage;

@property (nonatomic, strong) UIView *focusView;
@property (nonatomic, strong) CAShapeLayer *focusLayer;

@property (nonatomic, assign) UIInterfaceOrientation currectOrientation;

@end

@implementation HNewRecordingViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.audioSession = [AVAudioSession sharedInstance];
    
    [self initUI];
    [self initRecordManager];
    
    self.totalPinchScale = 1.0;
    
    [self.recordManager previewLayer].frame = CGRectMake(0, 0, CGRectGetWidth(self.view.frame),  SCREEN_HEIGHT);
    [self.recoderPreview.layer insertSublayer:[self.recordManager previewLayer] atIndex:0];
    [self.recordManager startUp];
    
    //自动连续对焦
    WS
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        SS
        [self.recordManager focusContinuousAutoFocusAndContinuousAutoExposure];
        [self addFocusViewWithPoint:self.view.center];
    });
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanAction:)];
    [self.recoderPreview addGestureRecognizer:pan];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapAction:)];
    tap.numberOfTapsRequired = 1;
    [self.recoderPreview addGestureRecognizer:tap];
    
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchAction:)];
    [self.recoderPreview addGestureRecognizer:pinch];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(editCommandCompletionNotificationReceiver:)
                                                 name:AVSEEditCommandCompletionNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(exportCommandCompletionNotificationReceiver:)
                                                 name:AVSEExportCommandCompletionNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(exportCommandCompletionNotificationReceiver:)
                                                 name:AVSEExportCommandFailNotification
                                               object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)initUI
{
    self.recoderPreview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame))];
    self.recoderPreview.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.recoderPreview];
    
    CGPoint point = CGPointMake([UIScreen mainScreen].bounds.size.width/2, [UIScreen mainScreen].bounds.size.height-36-RecordingSpace_Bottom);
    self.recordingBtn = [[HRecordingCircleButton alloc] initWithCircleRadius:RecordingBtn_Radius center:point];
    self.recordingBtn.delegate = self;
    self.recordingBtn.recordMaxTime = RecordMaxDuration;
    [self.view addSubview:self.recordingBtn];
    
    self.changeCapture = [UIButton buttonWithType:UIButtonTypeCustom];
    self.changeCapture.backgroundColor = [UIColor clearColor];
    [self.changeCapture setImage:[UIImage imageNamed:@"cameraswitch"] forState:UIControlStateNormal];
    [self.changeCapture setImage:[UIImage imageNamed:@"cameraswitchHL"] forState:UIControlStateHighlighted];
    [self.changeCapture addTarget:self action:@selector(changeCapture:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.changeCapture];
    self.changeCapture.frame = CGRectMake([UIScreen mainScreen].bounds.size.width-ChangeCaptureBtnWidth_Height-10, point.y-ChangeCaptureBtnWidth_Height/2, ChangeCaptureBtnWidth_Height, ChangeCaptureBtnWidth_Height);
    self.changeCapture.imageView.contentMode = UIViewContentModeScaleToFill;
    self.changeCapture.imageEdgeInsets = UIEdgeInsetsMake(15, 10, 15, 20);
    
    self.backCapture = [UIButton buttonWithType:UIButtonTypeCustom];
    self.backCapture.backgroundColor = [UIColor clearColor];
    [self.backCapture setImage:[UIImage imageNamed:@"recordvideo_close"] forState:UIControlStateNormal];
    [self.backCapture setImage:[UIImage imageNamed:@"recordvideo_close"] forState:UIControlStateHighlighted];
    [self.backCapture addTarget:self action:@selector(cancelAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.backCapture];
    self.backCapture.frame = CGRectMake(10,point.y-BackBtnWidth_Height/2,BackBtnWidth_Height,BackBtnWidth_Height);
    self.backCapture.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.backCapture.imageEdgeInsets = UIEdgeInsetsMake(15, 20, 15, 10);
    
    self.replayView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame))];
    self.replayView.hidden = YES;
    self.replayView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.replayView];
    
    self.player = [AVPlayer playerWithPlayerItem:nil];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.playerLayer.frame = self.replayView.bounds;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] > 10.0)
    {
        self.player.automaticallyWaitsToMinimizeStalling = NO;
    }
    
    [self.replayView.layer addSublayer:self.playerLayer];
    
    self.backToRecordBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.backToRecordBtn.frame = CGRectMake(16, 16, 40 , 40);
    self.backToRecordBtn.backgroundColor = [UIColor clearColor];
    [self.backToRecordBtn setImage:[UIImage imageNamed:@"videorecordcancel"] forState:UIControlStateNormal];
    [self.backToRecordBtn setImage:[UIImage imageNamed:@"videorecordcancelHL"] forState:UIControlStateHighlighted];
    [self.backToRecordBtn addTarget:self action:@selector(backToRecordAction:) forControlEvents:UIControlEventTouchUpInside];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
    {
        UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
        self.blurBackgroundView = [[UIVisualEffectView alloc] initWithEffect:blur];
        self.blurBackgroundView.frame = CGRectMake(40, CGRectGetHeight(self.view.frame)-56-72, 72, 72);
        self.blurBackgroundView.layer.cornerRadius = 36;
        self.blurBackgroundView.layer.masksToBounds = YES;
        [((UIVisualEffectView *)self.blurBackgroundView).contentView addSubview:self.backToRecordBtn];
        [self.replayView addSubview:self.blurBackgroundView];
    }
    else
    {
        self.blurBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(40, CGRectGetHeight(self.view.frame)-56-72, 72, 72)];
        self.blurBackgroundView.backgroundColor = [[UIColor colorWithHex:0xF3F3F3] colorWithAlphaComponent:0.96];
        self.blurBackgroundView.layer.cornerRadius = 36;
        self.blurBackgroundView.layer.masksToBounds = YES;
        [self.blurBackgroundView addSubview:self.backToRecordBtn];
        [self.replayView addSubview:self.blurBackgroundView];
    }
    
    self.sendBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.view.frame)-40-72, CGRectGetHeight(self.view.frame)-56-72, 72, 72)];
    self.sendBackgroundView.backgroundColor = [UIColor whiteColor];
    self.sendBackgroundView.layer.cornerRadius = 36;
    self.sendBackgroundView.layer.masksToBounds = YES;
    [self.replayView addSubview:self.sendBackgroundView];
    
    self.blurBackgroundView.frame = CGRectMake((CGRectGetWidth(self.view.frame)-72)/2, CGRectGetHeight(self.view.frame)-56-72, 72, 72);
    self.sendBackgroundView.frame = CGRectMake((CGRectGetWidth(self.view.frame)-72)/2, CGRectGetHeight(self.view.frame)-56-72, 72, 72);
    
    self.sendBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.sendBtn.backgroundColor = [UIColor clearColor];
    self.sendBtn.frame = CGRectMake(16, 16, 40 , 40);
    [self.sendBtn setImage:[UIImage imageNamed:@"videorecordsend"] forState:UIControlStateNormal];
    [self.sendBtn setImage:[UIImage imageNamed:@"videorecordsendHL"] forState:UIControlStateHighlighted];
    [self.sendBtn addTarget:self action:@selector(sendAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.sendBackgroundView addSubview:self.sendBtn];
    
    //点击自动对焦的框
    self.focusView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    self.focusView.backgroundColor = [UIColor clearColor];
    self.focusView.hidden = YES;
    [self.recoderPreview addSubview:self.focusView];
    
    self.focusLayer = [[CAShapeLayer alloc] init];
    self.focusLayer.lineWidth = 2;
    self.focusLayer.strokeColor = [UIColor colorWithHex:0x0bbe06].CGColor;
    self.focusLayer.fillColor = [UIColor clearColor].CGColor;
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, 100, 100)];
    
    [path moveToPoint:CGPointMake(50 , 0)];
    [path addLineToPoint:CGPointMake(50, 10)];
    
    [path moveToPoint:CGPointMake(0, 50)];
    [path addLineToPoint:CGPointMake(10, 50)];
    
    [path moveToPoint:CGPointMake(100, 50)];
    [path addLineToPoint:CGPointMake(90, 50)];
    
    [path moveToPoint:CGPointMake(50 , 100)];
    [path addLineToPoint:CGPointMake(50, 90)];
    
    [path closePath];
    self.focusLayer.path = path.CGPath;
    [self.focusView.layer addSublayer:self.focusLayer];
    self.focusLayer.hidden = NO;
}

- (void)initRecordManager
{
    self.recordManager = [[HRecordVideoManager alloc] init];
    [self.recordManager setVedioWidth:540 height:960];
    self.recordManager.maxRecordTime = RecordMaxDuration;
    self.recordManager.delegate = self;
    self.isFrontCapture = YES;
}

#pragma mark - 调整小视频的方向，并显示
- (void)editRotateVideo
{
    NSError *error = nil;
    [self.audioSession setActive:YES error:&error];
    [self.audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    if ([self.recordManager.videoPath rangeOfString:@"_Tem"].location != NSNotFound)
    {
        
    }
    
    NSString *filePath = self.recordManager.videoPath;
    BOOL flag = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
    
    if (flag == NO)
    {
        return;
    }
    
    NSURL *videoURL = [NSURL fileURLWithPath:filePath];
    AVURLAsset *asset = [AVURLAsset assetWithURL:videoURL];
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
    
    [self.player replaceCurrentItemWithPlayerItem:playerItem];
    [self.player seekToTime:CMTimeMake(0, 1)];

    if (self.recordManager.startRecordingOrientation == UIInterfaceOrientationPortrait ||self.recordManager.startRecordingOrientation == UIInterfaceOrientationUnknown)
    {
        self.playerLayer.frame = self.view.bounds;
        [self.player play];
        
        return;
    }
    
    self.composition = nil;
    self.videoComposition = nil;
    self.audioMix = nil;
    
    AVSECommand *editCommand = [[AVSERotateCommand alloc] initWithComposition:self.composition videoComposition:self.videoComposition audioMix:self.audioMix];
    
    if (self.recordManager.startRecordingOrientation == UIInterfaceOrientationLandscapeLeft)
    {

        editCommand.rotationDegree = 270;
        
        CGFloat height = CGRectGetWidth(self.view.frame)*RecordingSize_S/RecordingSize_L;
        self.playerLayer.frame = CGRectMake(0, (CGRectGetHeight(self.view.frame)-height)/2, CGRectGetWidth(self.view.frame), height);
    }
    else if (self.recordManager.startRecordingOrientation == UIInterfaceOrientationLandscapeRight)
    {
        editCommand.rotationDegree = 90;
        
        CGFloat height = CGRectGetWidth(self.view.frame)*RecordingSize_S/RecordingSize_L;
        self.playerLayer.frame = CGRectMake(0, (CGRectGetHeight(self.view.frame)-height)/2, CGRectGetWidth(self.view.frame), height);
    }
    else
    {
        editCommand.rotationDegree = 180;
        self.playerLayer.frame = self.view.bounds;
    }
    
    self.inputAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:filePath] options:nil];
    [editCommand performWithAsset:self.inputAsset];
}

#pragma mark -
- (void)editCommandCompletionNotificationReceiver:(NSNotification*) notification
{
    if ([[notification name] isEqualToString:AVSEEditCommandCompletionNotification])
    {
        self.composition = [[notification object] mutableComposition];
        self.videoComposition = [[notification object] mutableVideoComposition];
        self.audioMix = [[notification object] mutableAudioMix];
        
        self.videoComposition.animationTool = NULL;
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:self.composition];
        playerItem.videoComposition = self.videoComposition;
        playerItem.audioMix = self.audioMix;
        [[self player] replaceCurrentItemWithPlayerItem:playerItem];
        [self.player play];
    }
}

- (void)exportCommandCompletionNotificationReceiver:(NSNotification *)notification
{
    if ([[notification name] isEqualToString:AVSEExportCommandCompletionNotification])
    {
        NSMutableString *imageLocalPath;
        if(self.saveFilePath && [self.saveFilePath hasSuffix:@".mp4"])
        {
            NSString *string = [self.saveFilePath substringToIndex:self.saveFilePath.length-4];
            imageLocalPath = [NSMutableString stringWithFormat:@"%@.jpg",string];
        }
        
        UIImage *coverImage = [HRecordVideoManager thumbnailImageForVideo:[NSURL fileURLWithPath:self.saveFilePath] atTime:0.0];
    
        NSString *size = nil;
        if (coverImage && coverImage.size.width > coverImage.size.height)
        {
            self.coverImage = [coverImage normalizedImageWithSize:CGSizeMake(140, 140*540/960)];
            size = [NSString stringWithFormat:@"960_540"];
        }
        else if(coverImage && coverImage.size.width <= coverImage.size.height)
        {
            self.coverImage = [coverImage normalizedImageWithSize:CGSizeMake(140*540/960,140)];
            size = [NSString stringWithFormat:@"540_960"];
        }
        else
        {
            self.coverImage = nil;
            size = @"";
        }
        
        coverImage = nil;
        BOOL writeFlag = NO;
        if (self.coverImage)
        {
            NSData *imageData = UIImageJPEGRepresentation(self.coverImage, 1.0);
            if (imageData)
            {
                writeFlag = [imageData writeToFile:imageLocalPath atomically:YES];
                if (writeFlag == NO)
                {
                    [[NSFileManager defaultManager] removeItemAtPath:imageLocalPath error:nil];
                    writeFlag = [imageData writeToFile:imageLocalPath atomically:YES];
                }
            }
        }
        
        NSMutableDictionary *sightVideoInfoDic = [[NSMutableDictionary alloc] init];
        
        [sightVideoInfoDic setValue:self.videoName forKey:kSightVideoNameKey];
        [sightVideoInfoDic setValue:@[] forKey:kSightVideoThumbnailArrayKey];
        [sightVideoInfoDic setValue:self.saveFilePath forKey:kSightVideoPathKey];
        [sightVideoInfoDic setValue:@(self.recordManager.currentRecordTime) forKey:kSightVideoThumbnailCapturedDurationKey];
        [sightVideoInfoDic setValue:writeFlag ? imageLocalPath : @"" forKey:kSightVideoThumbnailKey];
        [sightVideoInfoDic setValue:self.uploadURL forKey:kSightVideoServerPathKey];
        [sightVideoInfoDic setValue:size forKey:kSightVideoSizeKey];
        
        if ([self.recordDelegate respondsToSelector:@selector(recordingViewDidEndRecordWithInfo:)])
        {
            [self.recordDelegate recordingViewDidEndRecordWithInfo:sightVideoInfoDic];
        }

        
        WS
        dispatch_async(dispatch_get_main_queue(), ^{
            SS
            [[HHUDViewController sharedInstance] dismiss];
            
            [self.player pause];
            [self.player replaceCurrentItemWithPlayerItem:nil];
            self.player = nil;
            
            [self dismissViewControllerAnimated:YES completion:^{
                //小视频保存到系统相册
                [self saveVideoToSystemAlbumWithFilePath:self.saveFilePath];
            }];
        });
    }
    else
    {
        WS
        dispatch_async(dispatch_get_main_queue(), ^{
            SS
            [[HHUDViewController sharedInstance] showErrorDelay1sWithString:@"视频发送失败"];
            
            [self.player pause];
            [self.player replaceCurrentItemWithPlayerItem:nil];
            self.player = nil;
            
            [self dismissViewControllerAnimated:YES completion:^{
                
            }];
        });
    }
}

#pragma mark - 播放结束回调
- (void)playerItemDidReachEnd:(NSNotification *)notification
{
    [self.player seekToTime:CMTimeMake(0, 1)];
    [self.player play];
}

#pragma mark - action 
- (void)changeCapture:(id)sender
{
    self.changeCapture.selected = !self.changeCapture.selected;
    if (self.changeCapture.selected == YES)
    {
        [self.recordManager changeCameraInputDeviceisFront:YES];
    }
    else
    {
        [self.recordManager changeCameraInputDeviceisFront:NO];
    }
    
    WS
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        SS
        [self.recordManager setCaptureDeviceAutoFocusWithPoint:self.view.center];
        [self addFocusViewWithPoint:self.view.center];
    });
}

- (void)cancelAction:(id)sender
{
    [self.player pause];
    [self.player replaceCurrentItemWithPlayerItem:nil];
    self.player = nil;
    
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}


- (void)startRecording:(id)sender
{
    if (self.recording)
    {
        return;
    }
    
    NSString *guid = [[NSUUID new] UUIDString];
    NSString *outputFile = [NSString stringWithFormat:@"video_%@.mp4", guid];
    self.videoName = outputFile;
    
    NSString *outputDirectory = NSTemporaryDirectory();
    NSString *outputPath = [outputDirectory stringByAppendingPathComponent:outputFile];
    
    self.saveFilePath = outputPath;
    self.recordManager.videoPath = outputPath;
    [self.recordManager startCapture];
    
    self.recording = YES;
}

- (void)backToRecordAction:(id)sender
{
    [self.recordManager startUp];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.recordManager setCaptureDeviceAutoFocusWithPoint:CGPointMake(SCREEN_WIDTH/2, SCREEN_HEIGHT/2)];
        [self.recordManager setCaptureDeviceFocusDidChangeZoom:1.0];
    });
    
    self.replayView.hidden = YES;
    self.blurBackgroundView.frame = CGRectMake((CGRectGetWidth(self.view.frame)-72)/2, CGRectGetHeight(self.view.frame)-56-72, 72, 72);
    self.sendBackgroundView.frame = CGRectMake((CGRectGetWidth(self.view.frame)-72)/2, CGRectGetHeight(self.view.frame)-56-72, 72, 72);
    [self.player pause];
    [self.player replaceCurrentItemWithPlayerItem:nil];
    [[NSFileManager defaultManager] removeItemAtPath:self.saveFilePath error:nil];
}

- (void)sendAction:(id)sender
{
    if (self.recordManager.startRecordingOrientation == UIInterfaceOrientationPortrait ||self.recordManager.startRecordingOrientation == UIInterfaceOrientationUnknown)
    {
        [self.player pause];
        
        //如果拍摄时是正立拍摄，则不需要调整视频方向直接发送即可
        NSMutableString *imageLocalPath;
        if(self.saveFilePath && [self.saveFilePath hasSuffix:@".mp4"])
        {
            NSString *string = [self.saveFilePath substringToIndex:self.saveFilePath.length-4];
            imageLocalPath = [NSMutableString stringWithFormat:@"%@.jpg",string];
        }
        
        UIImage *coverImage = [HRecordVideoManager thumbnailImageForVideo:[NSURL fileURLWithPath:self.saveFilePath] atTime:0.0];
        
        NSString *size = nil;
        if (coverImage && coverImage.size.width > coverImage.size.height)
        {
            self.coverImage = [coverImage normalizedImageWithSize:CGSizeMake(140, 140*540/960)];
            size = [NSString stringWithFormat:@"960_540"];
        }
        else if(coverImage && coverImage.size.width <= coverImage.size.height)
        {
            self.coverImage = [coverImage normalizedImageWithSize:CGSizeMake(140*540/960,140)];
            size = [NSString stringWithFormat:@"540_960"];
        }
        else
        {
            self.coverImage = nil;
            size = @"";
        }
        
        coverImage = nil;
        BOOL writeFlag = NO;
        if (self.coverImage)
        {
            NSData *imageData = UIImageJPEGRepresentation(self.coverImage, 1.0);
            if (imageData)
            {
                writeFlag = [imageData writeToFile:imageLocalPath atomically:YES];
                if (writeFlag == NO)
                {
                    [[NSFileManager defaultManager] removeItemAtPath:imageLocalPath error:nil];
                    writeFlag = [imageData writeToFile:imageLocalPath atomically:YES];
                }
            }
        }
        
        NSMutableDictionary *sightVideoInfoDic = [[NSMutableDictionary alloc] init];
        [sightVideoInfoDic setValue:self.videoName forKey:kSightVideoNameKey];
        [sightVideoInfoDic setValue:@[] forKey:kSightVideoThumbnailArrayKey];
        [sightVideoInfoDic setValue:self.saveFilePath forKey:kSightVideoPathKey];
        [sightVideoInfoDic setValue:@(self.recordManager.currentRecordTime) forKey:kSightVideoThumbnailCapturedDurationKey];
        [sightVideoInfoDic setValue:writeFlag ? imageLocalPath : @"" forKey:kSightVideoThumbnailKey];
        [sightVideoInfoDic setValue:self.uploadURL forKey:kSightVideoServerPathKey];
        [sightVideoInfoDic setValue:size forKey:kSightVideoSizeKey];
        
        
        if ([self.recordDelegate respondsToSelector:@selector(recordingViewDidEndRecordWithInfo:)])
        {
            [self.recordDelegate recordingViewDidEndRecordWithInfo:sightVideoInfoDic];
        }
            
        [self.player replaceCurrentItemWithPlayerItem:nil];
        self.player = nil;
        
        [self dismissViewControllerAnimated:YES completion:^{
            
        }];
    }
    else
    {
        [self.player pause];
        
        [HHUDViewController sharedInstance].disabled = YES;
        [[HHUDViewController sharedInstance] showLoadingWithString:@"正在处理"];
        
        AVSECommand *exportCommand = [[AVSEExportCommand alloc] initWithComposition:self.composition videoComposition:self.videoComposition audioMix:self.audioMix];
        exportCommand.outputPath = self.saveFilePath;
        [exportCommand performWithAsset:nil];
    }
}

- (void)stopRecord:(id)sender
{
    if (self.recording)
    {
        self.recording = NO;
        
        WS
        [self.recordManager stopCaptureHandler:^(void) {
            SS
            [self.recordManager shutdown];
            self.replayView.hidden = NO;
            
            [UIView animateWithDuration:0.25 animations:^{
                self.blurBackgroundView.frame = CGRectMake(40, CGRectGetHeight(self.view.frame)-56-72, 72, 72);
                self.sendBackgroundView.frame = CGRectMake(CGRectGetWidth(self.view.frame)-40-72, CGRectGetHeight(self.view.frame)-56-72, 72, 72);
            }];
            
            [self editRotateVideo];
            return ;
        }];
    }
}

#pragma mark -滑动手势
- (void)handlePanAction:(UIPanGestureRecognizer *)pan
{
    if (self.recordManager.isCapturing == NO)
    {
        return;
    }
    
    if (pan.state == UIGestureRecognizerStateChanged)
    {
        CGPoint speed = [pan velocityInView:self.view];
        
        NSLog(@"speed:%f",speed.y);
        
        //向上是负数，向下是正数，并且以-1500~0,0~1500为最大范围 1~1.2  1~0.8
        
        CGFloat y = speed.y;
        CGFloat scale = 1.0;
        if (y < 0)
        {
            //变大
            scale = (1+fabs(y)/10000.0);
            if(self.totalPinchScale*scale >= PinchMaxScale)
            {
                self.totalPinchScale = PinchMaxScale;
            }
            else
            {
                self.totalPinchScale *=scale;
            }
        }
        else
        {
            //缩小
            scale = (1-fabs(y)/10000.0);
            
            if (self.totalPinchScale*scale <= PinchMinScale)
            {
                self.totalPinchScale = PinchMinScale;
            }
            else
            {
                self.totalPinchScale *=scale;
            }
        }
        
        [self.recordManager setCaptureDeviceFocusDidChangeZoom:self.totalPinchScale];
    }
}

#pragma mark - 点击手势
- (void)handleTapAction:(UITapGestureRecognizer *)tap
{
    if (tap.state == UIGestureRecognizerStateRecognized)
    {
        CGPoint location = [tap locationInView:self.recoderPreview];
        [self.recordManager setCaptureDeviceAutoFocusWithPoint:location];
        [self addFocusViewWithPoint:location];
    }
}

- (void)addFocusViewWithPoint:(CGPoint)point
{
    self.focusView.center = point;
    self.focusView.layer.anchorPoint = CGPointMake(0.5, 0.5);
    self.focusView.hidden = NO;
    [self.focusView.layer removeAllAnimations];
    self.focusView.transform = CGAffineTransformMakeScale(1.5, 1.5);
    
    WS
    [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        SS
        self.focusView.transform = CGAffineTransformMakeScale(1.0, 1.0);
    } completion:^(BOOL finished) {
        
    }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        SS
        self.focusView.hidden = YES;
    });
}

#pragma mark  - 捏合手势
- (void)handlePinchAction:(UIPinchGestureRecognizer *)pinch
{
    if (pinch.state == UIGestureRecognizerStateChanged)
    {
        CGFloat scale = pinch.scale;
        //放大情况
        if(scale >= 1.0)
        {
            if(self.totalPinchScale*scale >= PinchMaxScale)
            {
                self.totalPinchScale = PinchMaxScale;
            }
            else
            {
                self.totalPinchScale *=scale;
            }
        }
        //缩小情况
        if (scale < 1.0)
        {
            if (self.totalPinchScale*scale <= PinchMinScale)
            {
                self.totalPinchScale = PinchMinScale;
            }
            else
            {
                self.totalPinchScale *=scale;
            }
        }
   
        pinch.scale = 1.0;
        
        [self.recordManager setCaptureDeviceFocusDidChangeZoom:self.totalPinchScale];
    }
}

#pragma mark - HRecordVideoManagerDelegate
- (void)recordProgress:(CGFloat)progress
{
    
}

- (void)recordVideoDeviceOrientationChanged:(UIInterfaceOrientation)orientation
{
    if (self.currectOrientation == orientation)
    {
        return;
    }
    
    CGFloat angle = 0;
    CGFloat fromAngle = 0;
    
    if (orientation == UIInterfaceOrientationLandscapeLeft)
    {
        angle = M_PI/2;
        
        if (self.currectOrientation == UIDeviceOrientationPortraitUpsideDown)
        {
            fromAngle = M_PI;
        }
        else if (self.currectOrientation == UIInterfaceOrientationLandscapeRight)
        {
            fromAngle = -M_PI/2;
        }
        else
        {
            fromAngle = 0;
        }
    }
    else if(orientation == UIDeviceOrientationPortraitUpsideDown)
    {
        if (self.currectOrientation == UIInterfaceOrientationLandscapeLeft)
        {
            fromAngle = M_PI/2;
        }
        else if (self.currectOrientation == UIInterfaceOrientationLandscapeRight)
        {
            fromAngle = 3*M_PI/2;
        }
        else
        {
            fromAngle = 0;
        }

        angle = M_PI;
        
    }
    else if (orientation == UIInterfaceOrientationLandscapeRight)
    {
        if (self.currectOrientation == UIInterfaceOrientationLandscapeLeft)
        {
            fromAngle = M_PI/2;
        }
        else if (self.currectOrientation == UIDeviceOrientationPortraitUpsideDown)
        {
            fromAngle = -M_PI;
        }
        else
        {
            fromAngle = 0;
        }
        
        angle = -M_PI/2;
    }
    else
    {
        if (self.currectOrientation == UIInterfaceOrientationLandscapeLeft)
        {
             fromAngle = M_PI/2;
        }
        else if (self.currectOrientation == UIDeviceOrientationPortraitUpsideDown)
        {
            fromAngle = M_PI;
        }
        else
        {
            fromAngle = -M_PI/2;
        }
        angle = 0;
    }
    
    self.currectOrientation = orientation;
    
    self.changeCapture.layer.anchorPoint = CGPointMake(0.5, 0.5);
    
    CABasicAnimation *rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.fromValue = [NSNumber numberWithFloat: fromAngle];
    rotationAnimation.toValue = [NSNumber numberWithFloat: angle];
    rotationAnimation.duration = 0.3;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = 1;
    //旋转后保持旋转后状态
    rotationAnimation.fillMode = kCAFillModeForwards;
    rotationAnimation.removedOnCompletion = NO;
    [self.changeCapture.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
}

#pragma mark - HRecordVideoManagerDelegate
- (void)eventDownButtonBeganTouchDown
{
    [self startRecording:nil];
}

- (void)eventDownButtonOutOfView
{

}

- (void)touchMove:(NSSet<UITouch *> *)touches
{

}

- (void)touchEndAction:(id)sender
{
    [self stopRecord:nil];
}

- (void)touchMoveSpeedY:(CGFloat)speedY
{
    if (self.recordManager.isCapturing == NO)
    {
        return;
    }
    
    CGFloat scale = 1.0;
    if (speedY < 0)
    {
        //变大
        scale = (1+fabs(speedY)/10000.0);
        if(self.totalPinchScale*scale >= PinchMaxScale)
        {
            self.totalPinchScale = PinchMaxScale;
        }
        else
        {
            self.totalPinchScale *=scale;
        }
    }
    else
    {
        //缩小
        scale = (1-fabs(speedY)/10000.0);
        
        if (self.totalPinchScale*scale <= PinchMinScale)
        {
            self.totalPinchScale = PinchMinScale;
        }
        else
        {
            self.totalPinchScale *=scale;
        }
    }
    
    [self.recordManager setCaptureDeviceFocusDidChangeZoom:self.totalPinchScale];
}

- (void)recordingCircleButton:(HRecordingCircleButton *)recordingBtn updateProgress:(CGFloat)progress
{
    if (progress >= 1.0)
    {
        [self stopRecord:nil];
    }
}

#pragma mark - 保存小视频到系统相册 -
- (void)saveVideoToSystemAlbumWithFilePath:(NSString *)filePath
{
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0)
    {
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            
            [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:[NSURL fileURLWithPath:filePath]];
            
        } completionHandler:^(BOOL success, NSError *error) {
            
        }];
    }
    else
    {
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        [library writeVideoAtPathToSavedPhotosAlbum:[NSURL fileURLWithPath:filePath] completionBlock:^(NSURL *assetURL, NSError *error) {
            if (error)
            {
                NSLog(@"Save video fail:%@",error);
            }
            else
            {
                NSLog(@"Save video succeed.");
            }
        }];
    }
}


@end
