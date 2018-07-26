//
//  QIYIScanQRCodeViewController.m
//  reliao
//
//  Created by liyanjun on 16/8/26.
//
//

#import "QIYIScanQRCodeViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "UIColor+Extension.h"
#import "UIImage+Extension.h"
#import "QIYIActionSheetView.h"
#import "QIYIHUDViewController.h"
#import "QIYIScanResultViewController.h"
#import "NNLHashids.h"
#import "QIYIFriendInfoViewController.h"
#import "QIYIScanQRCodeManager.h"
#import "QIYIScanLoginViewController.h"
#import "QIYIChatRoomViewController.h"
#import "QIYIFalconViewController.h"
#import "QIYIMyCodeViewController.h"
#import "QIYIGroupQRCodeViewController.h"
#import "QIYIAuthorizationCenter.h"
#import "QIYIOfficialViewController.h"
#import "QIYIAllUserInfoManager.h"
#import "QIYITabItemBtn.h"
#import "iPhoneXMPPAppDelegate.h"
#import "NSFileManager+Extension.h"
#import "QIYIHeartView.h"
#import "QIYIShowARResultView.h"

static const char *kScanQRCodeQueueName = "ScanQRCodeQueue";

extern NSString *salt;

#define ScanViewWidth_Height SCREEN_WIDTH*0.66
#define ScanViewSpaceLeft_Right SCREEN_WIDTH*0.17
#define ScanViewLineWidth 20
#define ScanViewLineHeight 2

@interface QIYIScanQRCodeViewController ()<AVCaptureMetadataOutputObjectsDelegate,UINavigationControllerDelegate, UIImagePickerControllerDelegate,CAAnimationDelegate,AVCaptureVideoDataOutputSampleBufferDelegate,UIAlertViewDelegate>

@property (nonatomic, strong) QIYINavBarView *navBarView;
@property (nonatomic, strong) AVCaptureDevice *captureDevice;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (nonatomic, strong) UIImageView *lineImageView;
@property (nonatomic, strong) UILabel *tipsLabel;
@property (nonatomic, strong) UIButton *bottomBtn;

@property (nonatomic, assign) BOOL lightState;
@property (nonatomic, assign) BOOL hasScanResult;
@property (nonatomic, assign) BOOL isShowingMoreView;
@property (nonatomic, weak) UIImagePickerController *imagePickerController;

@property (nonatomic, strong) CALayer *normalMaskLayer;

@property (nonatomic, strong) CAShapeLayer *ARMaskLayer;

@property (nonatomic, strong) UILabel *loadWebTipsLabel; //登录网页版的提示信息

@property (nonatomic, strong) UIView *bottomView;

@property (nonatomic, strong) QIYITabItemBtn *scanItemBtn;

@property (nonatomic, strong) QIYITabItemBtn *scanARItemBtn;

@property (nonatomic, assign) BOOL isFrontCapture; //是否时前置摄像头

@property (nonatomic, strong)  AVCaptureMetadataOutput *captureMetadataOutput;

@property (nonatomic, strong) AVCaptureVideoDataOutput *captureOutput;

@property (nonatomic, assign) BOOL handlingImage; //是否正在处理图片

@property (nonatomic, assign) BOOL loadModelFinish;

@property (nonatomic, strong) UILabel *errorARScanLabel;

@property (nonatomic, strong) UILabel *ARScanTipLabel;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, assign) BOOL newworkStatus;

//统计成功和失败次数
@property (nonatomic, assign) NSInteger ARScanSucc;

@property (nonatomic, assign) NSInteger ARScanFail;

@property (nonatomic, strong) QIYIShowARResultView *ARScanResultView;

@property (nonatomic, assign) BOOL downloadingARModal;

@property (nonatomic, assign) BOOL viewDidAppear;

@end

@implementation QIYIScanQRCodeViewController

+ (instancetype)sharedScanQRCodeInstance
{
    static QIYIScanQRCodeViewController *VC = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        VC = [[QIYIScanQRCodeViewController alloc] initWithNibName:nil bundle:nil];
    });
    
    return VC;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.captureDevice removeObserver:self forKeyPath:@"adjustingFocus"];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        [self initUI];
        [self initOther];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //语音/视频聊天相关通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sacnQRCodeReceivedPresentVideoCallNotify) name:QYHydraWillPresentVideoCallNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkChanged:) name:kReachabilityChangedNotification object:nil];
    self.newworkStatus = YES;
    self.loadModelFinish = NO;
    self.viewDidAppear = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.navigationController)
    {
        self.navigationController.navigationBar.hidden = YES;
    }
    
    self.hasScanResult = NO;
    
    if (self.scanType == QIYIScanQRCodeType_Normal)
    {
        self.lineImageView.hidden = NO;
    }
    else
    {
        self.lineImageView.hidden = YES;
    }
  
    [self startReading];
    
    //自动对焦
    [self setCaptureDeviceAutoFocusWithPoint:CGPointMake(SCREEN_WIDTH/2, SCREEN_HEIGHT/2)];
    self.handlingImage = NO;
    
    iPhoneXMPPAppDelegate *delegate = (iPhoneXMPPAppDelegate *)[UIApplication sharedApplication].delegate;
    
    if(!([delegate.netStatus isEqualToString:@"1"] || [delegate.netStatus isEqualToString:@"14"]))
    {
        self.errorARScanLabel.text = @"无网络连接，请检测网络设置";
        if (self.scanType == QIYIScanQRCodeType_AR)
        {
            self.errorARScanLabel.hidden = NO;
        }
        else
        {
            self.errorARScanLabel.hidden = YES;
            [[QIYIHUDViewController sharedInstance] showErrorDelay1sWithString:@"当前网络不可用"];
        }
        
        self.newworkStatus = NO;
        [self stopAnimationTimer];
    }
    else
    {
        self.newworkStatus = YES;
    }
    
    NSString *ARKeyNew = [NSString stringWithFormat:@"%@_ARKey_New",[QIYIMyUserInfoManager sharedInstance].myUserName];
    NSString *ARNew = [[NSUserDefaults standardUserDefaults] objectForKey:ARKeyNew];
    if (ARNew == nil || ARNew.length == 0)
    {
        [[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:ARKeyNew];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.viewDidAppear = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.lineImageView.hidden = YES;
    [self stopAnimationTimer];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    self.hasScanResult = YES;
    self.ARScanResultView.frame = CGRectMake(0, SCREEN_HEIGHT, SCREEN_WIDTH, SCREEN_HEIGHT);
    self.viewDidAppear = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)initUI
{
    self.view.backgroundColor = TABLEVIEW_COLOR;
    
    self.navBarView = [[QIYINavBarView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), [HDevice shareInstance].navViewHeight)];
    self.navBarView.title = NSLocalizedString(@"二维码", nil);
    self.navBarView.leftBtnTitle = NSLocalizedString(@"消息",nil);
    self.navBarView.rightBtnTitle = @"";
    WS
    self.navBarView.backBlock = ^(void){
        SS
        if (self.navigationController == nil)
        {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        else
        {
            [self.navigationController popViewControllerAnimated:YES];
        }
        
        [self uploadPinBackForARWithData1:[NSString stringWithFormat:@"%ld",self.ARScanFail] andData2:[NSString stringWithFormat:@"%ld",self.ARScanSucc]];
        self.ARScanFail = 0;
        self.ARScanSucc = 0;
    };
    
    self.navBarView.rightTapBlock = ^(void){
        SS
        if (self.scanType == QIYIScanQRCodeType_Normal)
        {
            [self tapShowMoreQRCodeView:nil];
        }
        else
        {
            self.isFrontCapture = !self.isFrontCapture;
            [self changeCameraInputDeviceisFront:self.isFrontCapture];
        }
    };
    
    [self.view addSubview:self.navBarView];
    
    self.lineImageView = [[UIImageView alloc] initWithFrame:CGRectMake(ScanViewSpaceLeft_Right, CGRectGetMaxY(self.navBarView.frame)+(SCREEN_HEIGHT-64-ScanViewWidth_Height)*0.4, CGRectGetWidth(self.view.frame)-ScanViewSpaceLeft_Right*2, 3)];
    self.lineImageView.image = [UIImage imageNamed:@"scan_scaning"];
    self.lineImageView.backgroundColor = [UIColor clearColor];
    self.lineImageView.clipsToBounds = YES;
    self.lineImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:self.lineImageView];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    CGFloat bottomHeiht = 80;
    if([[HDevice shareInstance] localizedModel] == HDeviceLocalizedModel_iPhoneX)
    {
        bottomHeiht += 34;
    }
    
    self.normalMaskLayer = [CALayer layer];
    self.normalMaskLayer.backgroundColor = [UIColor clearColor].CGColor;
    self.normalMaskLayer.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    [self.view.layer addSublayer:self.normalMaskLayer];
    
    //普通扫一扫的UI显示
    for (NSInteger i = 0 ; i < 4; i++)
    {
        CALayer *leftLayer = [CALayer layer];
        CALayer *lineV = [CALayer layer];
        CALayer *lineH = [CALayer layer];
        if (i == 0)
        {
            //上
            leftLayer.frame = CGRectMake(0, CGRectGetMaxY(self.navBarView.frame), CGRectGetWidth(self.view.frame), (SCREEN_HEIGHT-64-ScanViewWidth_Height)*0.4);
            lineH.frame =CGRectMake(ScanViewSpaceLeft_Right,CGRectGetMaxY(self.navBarView.frame)+(SCREEN_HEIGHT-64-ScanViewWidth_Height)*0.4, ScanViewLineWidth, ScanViewLineHeight);
            lineV.frame = CGRectMake(ScanViewSpaceLeft_Right,CGRectGetMaxY(self.navBarView.frame)+(SCREEN_HEIGHT-64-ScanViewWidth_Height)*0.4,ScanViewLineHeight, ScanViewLineWidth);
        }
        else if (i == 1)
        {
            //左
            leftLayer.frame = CGRectMake(0, CGRectGetMaxY(self.navBarView.frame)+(SCREEN_HEIGHT-64-ScanViewWidth_Height)*0.4, ScanViewSpaceLeft_Right, ScanViewWidth_Height);
            
            lineH.frame =CGRectMake(ScanViewSpaceLeft_Right,CGRectGetMaxY(self.navBarView.frame)+(SCREEN_HEIGHT-64-ScanViewWidth_Height)*0.4+ScanViewWidth_Height-ScanViewLineHeight, ScanViewLineWidth, ScanViewLineHeight);
            lineV.frame = CGRectMake(ScanViewSpaceLeft_Right,CGRectGetMaxY(self.navBarView.frame)+(SCREEN_HEIGHT-64-ScanViewWidth_Height)*0.4+ScanViewWidth_Height-ScanViewLineWidth,ScanViewLineHeight, ScanViewLineWidth);
        }
        else if (i == 2)
        {
            //右
            leftLayer.frame = CGRectMake(SCREEN_WIDTH-ScanViewSpaceLeft_Right,CGRectGetMaxY(self.navBarView.frame)+(SCREEN_HEIGHT-64-ScanViewWidth_Height)*0.4, ScanViewSpaceLeft_Right, ScanViewWidth_Height);
            
            lineH.frame =CGRectMake(SCREEN_WIDTH-ScanViewSpaceLeft_Right-ScanViewLineWidth,CGRectGetMaxY(self.navBarView.frame)+(SCREEN_HEIGHT-64-ScanViewWidth_Height)*0.4, ScanViewLineWidth, ScanViewLineHeight);
            lineV.frame = CGRectMake(SCREEN_WIDTH-ScanViewSpaceLeft_Right-ScanViewLineHeight,CGRectGetMaxY(self.navBarView.frame)+(SCREEN_HEIGHT-64-ScanViewWidth_Height)*0.4,ScanViewLineHeight, ScanViewLineWidth);
        }
        else if (i == 3)
        {
            //下
            leftLayer.frame = CGRectMake(0,CGRectGetMaxY(self.navBarView.frame)+(SCREEN_HEIGHT-64-ScanViewWidth_Height)*0.4+ScanViewWidth_Height, CGRectGetWidth(self.view.frame), (SCREEN_HEIGHT-64-ScanViewWidth_Height)*0.6);
            
            lineH.frame =CGRectMake(SCREEN_WIDTH-ScanViewSpaceLeft_Right-ScanViewLineWidth,CGRectGetMaxY(self.navBarView.frame)+(SCREEN_HEIGHT-64-ScanViewWidth_Height)*0.4+ScanViewWidth_Height-ScanViewLineHeight, ScanViewLineWidth, ScanViewLineHeight);
            lineV.frame = CGRectMake(SCREEN_WIDTH-ScanViewSpaceLeft_Right-ScanViewLineHeight,CGRectGetMaxY(self.navBarView.frame)+(SCREEN_HEIGHT-64-ScanViewWidth_Height)*0.4+ScanViewWidth_Height-ScanViewLineWidth,ScanViewLineHeight, ScanViewLineWidth);
            
            self.tipsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMinY(leftLayer.frame)+10, CGRectGetWidth(self.view.frame), 15)];
            self.tipsLabel.backgroundColor = [UIColor clearColor];
            self.tipsLabel.textAlignment = NSTextAlignmentCenter;
            self.tipsLabel.textColor = [UIColor colorWithHex:0xDDDDDD];
            self.tipsLabel.text = NSLocalizedString(@"将二维码放入框内，即可自动扫描", nil);
            self.tipsLabel.font = [UIFont systemFontOfSize:12];
            [self.view addSubview:self.tipsLabel];
            
            self.bottomBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.tipsLabel.frame)+10, CGRectGetWidth(self.view.frame), 20)];
            self.bottomBtn.backgroundColor = [UIColor clearColor];
            self.bottomBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
            [self.bottomBtn setTitleColor:kThemeColor forState:UIControlStateNormal];
            [self.bottomBtn setTitle:NSLocalizedString(@"我的二维码", nil) forState:UIControlStateNormal] ;
            self.bottomBtn.titleLabel.font = [UIFont systemFontOfSize:15];
            [self.bottomBtn addTarget:self action:@selector(tapMyQRCodeAction:) forControlEvents:UIControlEventTouchUpInside];
            [self.view addSubview:self.bottomBtn];
            
            self.loadWebTipsLabel =  [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.tipsLabel.frame)+10, CGRectGetWidth(self.view.frame), 44)];
            self.loadWebTipsLabel.backgroundColor = [UIColor clearColor];
            self.loadWebTipsLabel.textAlignment = NSTextAlignmentCenter;
            self.loadWebTipsLabel.textColor = kThemeColor;
            self.loadWebTipsLabel.text = NSLocalizedString(@"电脑浏览器打开home.iqiyi.com\n扫描二维码登录网页版", nil);
            self.loadWebTipsLabel.font = [UIFont systemFontOfSize:15];
            self.loadWebTipsLabel.numberOfLines = 2;
            self.loadWebTipsLabel.hidden = YES;
            [self.view addSubview:self.loadWebTipsLabel];
        }
        
        leftLayer.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6].CGColor;
        lineH.backgroundColor = kThemeColor.CGColor;
        lineV.backgroundColor = kThemeColor.CGColor;
        
        [self.normalMaskLayer addSublayer:leftLayer];
        [self.normalMaskLayer addSublayer:lineH];
        [self.normalMaskLayer addSublayer:lineV];
        
        [self.view bringSubviewToFront:self.tipsLabel];
        [self.view bringSubviewToFront:self.bottomBtn];
        [self.view bringSubviewToFront:self.loadWebTipsLabel];
    }
    
    //AR扫一扫显示
    CGRect ARMaskLayerFrame = CGRectMake(0, CGRectGetMaxY(self.navBarView.frame), SCREEN_WIDTH, SCREEN_HEIGHT- CGRectGetMaxY(self.navBarView.frame) - bottomHeiht);
    
    UIBezierPath *bpath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(-2, -2, ARMaskLayerFrame.size.width+4, ARMaskLayerFrame.size.height+4) cornerRadius:0];
    UIBezierPath *aPath = [self drawHeartWithMinLength:CGRectGetWidth(self.view.frame) center:CGPointMake(ARMaskLayerFrame.size.width/2, ARMaskLayerFrame.size.height/2-40)];
    [bpath appendPath:[aPath bezierPathByReversingPath]];
    self.ARMaskLayer = [CAShapeLayer layer];
    self.ARMaskLayer.lineWidth = 2.0;
    self.ARMaskLayer.lineCap = kCALineJoinRound;  // 线条拐角
    self.ARMaskLayer.lineJoin = kCALineJoinRound;   //  终点处理
    self.ARMaskLayer.strokeColor = [UIColor colorWithHex:0XE4007D].CGColor;
    self.ARMaskLayer.path = bpath.CGPath;
    self.ARMaskLayer.fillColor = [[UIColor blackColor] colorWithAlphaComponent:0.6].CGColor;
    self.ARMaskLayer.frame = ARMaskLayerFrame;
    self.ARMaskLayer.masksToBounds = YES;
    [self.view.layer addSublayer:self.ARMaskLayer];

    self.errorARScanLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, CGRectGetMaxY(self.navBarView.frame)+(ARMaskLayerFrame.size.height/2-40), ARMaskLayerFrame.size.width-100, 20)];
    self.errorARScanLabel.backgroundColor = [UIColor clearColor];
    self.errorARScanLabel.textColor = [UIColor whiteColor];
    self.errorARScanLabel.font = [UIFont systemFontOfSize:16];
    self.errorARScanLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.errorARScanLabel];
    
    //爱心的半径
    CGFloat curveRadius = floor((CGRectGetWidth(self.view.frame) - 2*50)/(2+sqrt(2)));
    self.ARScanTipLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, CGRectGetMaxY(self.navBarView.frame)+(ARMaskLayerFrame.size.height/2-40)+2*curveRadius+20, ARMaskLayerFrame.size.width-100, 15)];
    self.ARScanTipLabel.backgroundColor = [UIColor clearColor];
    self.ARScanTipLabel.textColor = [UIColor colorWithHex:0xDDDDDD];
    self.ARScanTipLabel.font = [UIFont systemFontOfSize:12];
    self.ARScanTipLabel.text = @"对准目标，自动扫描";
    self.ARScanTipLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.ARScanTipLabel];
    
    [self.view bringSubviewToFront:self.navBarView];
    
    self.bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT-bottomHeiht, SCREEN_WIDTH, bottomHeiht)];
    self.bottomView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.9];
    [self.view addSubview:self.bottomView];
    
    self.scanItemBtn = [[QIYITabItemBtn alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH/2, 80)];
    [self.scanItemBtn setTitle:@"二维码" forState:UIControlStateNormal];
    [self.scanItemBtn setImage:[UIImage imageNamed:@"tab_qr"] forState:UIControlStateNormal];
    [self.scanItemBtn setImage:[UIImage imageNamed:@"tab_qr_active"] forState:UIControlStateHighlighted];
    [self.scanItemBtn setImage:[UIImage imageNamed:@"tab_qr_active"] forState:UIControlStateSelected];
    [self.scanItemBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.scanItemBtn setTitleColor:kThemeColor forState:UIControlStateHighlighted];
    [self.scanItemBtn setTitleColor:kThemeColor forState:UIControlStateSelected];
    [self.scanItemBtn addTarget:self action:@selector(scanItemBtnPressAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomView addSubview:self.scanItemBtn];
    self.scanARItemBtn.selected = NO;
    
    self.scanARItemBtn = [[QIYITabItemBtn alloc] initWithFrame:CGRectMake(SCREEN_WIDTH/2, 0, SCREEN_WIDTH/2, 80)];
    [self.scanARItemBtn setTitle:@"AR" forState:UIControlStateNormal];
    [self.scanARItemBtn setImage:[UIImage imageNamed:@"tab_ar"] forState:UIControlStateNormal];
    [self.scanARItemBtn setImage:[UIImage imageNamed:@"tab_ar_active"] forState:UIControlStateHighlighted];
    [self.scanARItemBtn setImage:[UIImage imageNamed:@"tab_ar_active"] forState:UIControlStateSelected];
    [self.scanARItemBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.scanARItemBtn setTitleColor:[UIColor colorWithHex:0XE4007D] forState:UIControlStateHighlighted];
    [self.scanARItemBtn setTitleColor:[UIColor colorWithHex:0XE4007D] forState:UIControlStateSelected];
    [self.scanARItemBtn addTarget:self action:@selector(scanARItemBtnPressAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomView addSubview:self.scanARItemBtn];
    self.scanARItemBtn.selected = NO;
    self.ARScanResultView = [[QIYIShowARResultView alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT, SCREEN_WIDTH, SCREEN_HEIGHT)];
    [self.view addSubview:self.ARScanResultView];
}


- (void)initOther
{
    // 获取 AVCaptureDevice 实例
    NSError * error;
    self.captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:self.captureDevice];
    
    [self.captureDevice addObserver:self forKeyPath:@"adjustingFocus" options:NSKeyValueObservingOptionNew context:nil];
    
    // 创建会话
    self.captureSession = [[AVCaptureSession alloc] init];
    
    if ([self.captureSession canSetSessionPreset:AVCaptureSessionPresetiFrame960x540])
    {
        [self.captureSession setSessionPreset:AVCaptureSessionPresetiFrame960x540];
    }
    else
    {
        [self.captureSession setSessionPreset:AVCaptureSessionPresetMedium];
    }
 
    // 初始化输入流
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:self.captureDevice error:&error];
    // 添加输入流
    if ([self.captureSession canAddInput:input])
    {
        [self.captureSession addInput:input];
    }
    
    self.captureOutput = [[AVCaptureVideoDataOutput alloc] init];
    self.captureOutput.alwaysDiscardsLateVideoFrames = YES;
    dispatch_queue_t queue = dispatch_queue_create("cameraQueue", NULL);
    [self.captureOutput setSampleBufferDelegate:self queue:queue];
    NSDictionary* setcapSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    [self.captureOutput setVideoSettings:setcapSettings];

    if ([self.captureSession canAddOutput:self.captureOutput])
    {
        [self.captureSession addOutput:self.captureOutput];
    }
    
    // 初始化输出流
    self.captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
    self.captureMetadataOutput.rectOfInterest = CGRectMake(0.2, 0.1, 0.6, 0.8);

    // 添加输出流
    if([self.captureSession canAddOutput:self.captureMetadataOutput])
    {
        [self.captureSession addOutput:self.captureMetadataOutput];
    }
    
    // 创建dispatch queue.
    dispatch_queue_t dispatchQueue;
    dispatchQueue = dispatch_queue_create(kScanQRCodeQueueName, NULL);
    [self.captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
    // 设置元数据类型 AVMetadataObjectTypeQRCode
    [self.captureMetadataOutput setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];
   
    // 创建输出对象
    self.videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
    [self.videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [self.videoPreviewLayer setFrame:CGRectMake(0, CGRectGetMaxY(self.navBarView.frame), CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame)-[HDevice shareInstance].navViewHeight)];
    self.videoPreviewLayer.backgroundColor = [UIColor blackColor].CGColor;
    [self.view.layer insertSublayer:self.videoPreviewLayer atIndex:0];
    
    [self getTorchStatus];
    self.hasScanResult = NO;
    self.isShowingMoreView = NO;
}

- (void)setScanType:(QIYIScanQRCodeType)scanType
{
    _scanType = scanType;
    if (scanType == QIYIScanQRCodeType_Normal)
    {
        self.normalMaskLayer.hidden = NO;
        self.lineImageView.hidden = NO;
        self.tipsLabel.hidden = NO;
        self.bottomBtn.hidden = NO;
        self.ARMaskLayer.hidden = YES;
        self.scanItemBtn.selected = YES;
        self.ARScanTipLabel.hidden = YES;
        self.errorARScanLabel.hidden = YES;
        self.scanARItemBtn.selected = NO;
        self.navBarView.title = NSLocalizedString(@"二维码", nil);
        [self.navBarView.rightBtn setImage:[UIImage imageNamed:@"web_more"] forState:UIControlStateNormal];
        
        [self stopAnimationTimer];
        for (UIView *view in self.view.subviews)
        {
            if ([view isKindOfClass:[QIYIHeartView class]])
            {
                view.hidden = YES;
            }
        }
        
        //如果是从网页版版进入，则
        if ([self.from isEqualToString:@"me_web"])
        {
            self.navBarView.title = NSLocalizedString(@"personal_detail_loadWebHotChat", nil);
            self.bottomBtn.hidden = YES;
            self.loadWebTipsLabel.hidden = NO;
        }
        else
        {
            self.navBarView.title = NSLocalizedString(@"扫描二维码", nil);
            self.bottomBtn.hidden = NO;
            self.loadWebTipsLabel.hidden = YES;
        }
        
        if (self.newworkStatus == NO)
        {
            [[QIYIHUDViewController sharedInstance] showErrorDelay1sWithString:@"当前网络不可用"];
        }
        
        [self uploadPinBackForARWithData1:[NSString stringWithFormat:@"%ld",self.ARScanFail] andData2:[NSString stringWithFormat:@"%ld",self.ARScanSucc]];
    }
    else
    {
        self.normalMaskLayer.hidden = YES;
        self.lineImageView.hidden = YES;
        self.tipsLabel.hidden = YES;
        self.bottomBtn.hidden = YES;
        self.ARMaskLayer.hidden = NO;
        [self.lineImageView.layer removeAllAnimations];
        self.scanItemBtn.selected = NO;
        self.scanARItemBtn.selected = YES;
        self.ARScanTipLabel.hidden = NO;
        self.errorARScanLabel.hidden = NO;
        self.loadWebTipsLabel.hidden = YES;
        self.navBarView.title = NSLocalizedString(@"AR", nil);
        [self.navBarView.rightBtn setImage:[UIImage imageNamed:@"nav_cameraswitch"] forState:UIControlStateNormal];
        
        [self startAnimatioTimer];
    }
    
    self.ARScanFail = 0;
    self.ARScanSucc = 0;
}

- (void)scanLineAnimation
{
    if (self.hasScanResult)
    {
        [self.lineImageView.layer removeAllAnimations];
        return;
    }
    
    CABasicAnimation *animation=[CABasicAnimation animationWithKeyPath:@"transform.translation.y"];
    
    animation.toValue = @(ScanViewWidth_Height-4);
    
    animation.duration = 2;
    
    animation.removedOnCompletion = NO;
    
    animation.repeatCount = CGFLOAT_MAX;
    
    [self.lineImageView.layer addAnimation:animation forKey:@"transform.translation.y"];
}


- (void)scanVoice
{
    NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"scan_result" ofType:@"wav"];
    NSURL *soundUrl = [NSURL fileURLWithPath:soundPath];
    SystemSoundID soundEffect;
    AudioServicesCreateSystemSoundID((__bridge CFURLRef) soundUrl, &soundEffect);
    AudioServicesPlaySystemSound(soundEffect);
}

- (void)setBackTitle:(NSString *)backTitle
{
    _backTitle = backTitle;
    if (backTitle)
    {
        self.navBarView.leftBtnTitle = backTitle;
    }
    else
    {
        self.navBarView.leftBtnTitle = @"";
    }
}

- (void)setFrom:(NSString *)from
{
    _from = from;
    
    if (self.scanType == QIYIScanQRCodeType_Normal)
    {
        if ([from isEqualToString:@"me_web"])
        {
            self.navBarView.title = NSLocalizedString(@"personal_detail_loadWebHotChat", nil);
            self.bottomBtn.hidden = YES;
            self.loadWebTipsLabel.hidden = NO;
        }
        else
        {
            self.navBarView.title = NSLocalizedString(@"扫描二维码", nil);
            self.bottomBtn.hidden = NO;
            self.loadWebTipsLabel.hidden = YES;
        }
    }
    else
    {
        
    }
}

- (void)startReading
{
    // 开始会话
    [self.captureSession startRunning];
    self.hasScanResult = NO;
    if (self.scanType == QIYIScanQRCodeType_Normal)
    {
        [self scanLineAnimation];
    }
    else
    {
        [self.lineImageView.layer removeAllAnimations];
    }
}

- (void)stopReading
{
    // 停止会话
    [self.captureSession stopRunning];
    self.hasScanResult = YES;
}

#pragma mark - 初始化下载点击按钮
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)
    {
        self.downloadingARModal = NO;
        self.loadModelFinish = NO;
        self.errorARScanLabel.hidden = NO;
        self.errorARScanLabel.text = @"初始化失败，请稍后重试";
    }
    else
    {
        self.errorARScanLabel.hidden = NO;
        self.errorARScanLabel.text = @"正在下载数据文件，请稍候";
        
        /*
        WS
        [[MDLHandposeManager shareInstance] initHandposeModelWithFinishBlock:^(BOOL flag) {
            if (flag)
            {
                SS
                self.loadModelFinish = [[MDLHandposeManager shareInstance] loadHandposeModel];
                if (self.loadModelFinish == NO)
                {
                    //重试一次
                    self.loadModelFinish = [[MDLHandposeManager shareInstance] loadHandposeModel];
                    //如果还失败，则提示加载模型失败吧;
                    if (self.loadModelFinish == NO)
                    {
                        self.errorARScanLabel.hidden = NO;
                        self.errorARScanLabel.text = @"初始化失败，请稍后再试";
                    }
                    else
                    {
                        self.errorARScanLabel.text = @"";
                        self.errorARScanLabel.hidden = YES;
                    }
                }
                else
                {
                    self.errorARScanLabel.text = @"";
                    self.errorARScanLabel.hidden = YES;
                }
                
                
            }
            else
            {
                self.downloadingARModal = NO;
                self.errorARScanLabel.hidden = NO;
                self.errorARScanLabel.text = @"初始化失败，请稍后再试";
            }
        }];*/
    }
}

#pragma mark - 网络状态改变通知
- (void)networkChanged:(NSNotification *)notification
{
    Reachability *currReach = [notification object];
    NetworkStatus status = [currReach currentReachabilityStatus];
    if (status == kNotReachable)
    {
        self.newworkStatus = NO;
        
    }
    else if (status == kReachableViaWiFi)
    {
        self.newworkStatus = YES;
    }
    else if (status == kReachableViaWWAN)
    {
        self.newworkStatus = YES;
    }
    
    if (self.scanType == QIYIScanQRCodeType_AR)
    {
        if (self.newworkStatus == NO)
        {
            self.errorARScanLabel.text = @"无网络连接，请检测网络设置";
            [self stopAnimationTimer];
        }
        else
        {
            self.errorARScanLabel.text = @"识别中";
            [self startAnimatioTimer];
        }
    }
    else
    {
        if (self.newworkStatus == NO)
        {
            [[QIYIHUDViewController sharedInstance] showErrorDelay1sWithString:@"当前网络不可用"];
        }
    }
}


#pragma mark  - 开始识别的动画timer
- (void)startAnimatioTimer
{
    [self.timer invalidate];
    self.timer = nil;
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(animationForHeartFlyARScan) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
}

- (void)stopAnimationTimer
{
    [self.timer invalidate];
    self.timer = nil;
}

- (void)animationForHeartFlyARScan
{
    NSInteger length = 20+random()%10;
    QIYIHeartView *heart = [[QIYIHeartView alloc] initWithFrame:CGRectMake(0, 0, length, length)];
    CGPoint fountainSource = CGPointMake(SCREEN_WIDTH / 2.0,  CGRectGetMinY(self.ARScanTipLabel.frame)-20);
    heart.center = fountainSource;
    [self.view addSubview:heart];
    [heart animateHearFlyInView:self.view];
    
    [self.view bringSubviewToFront:self.ARScanResultView];
}

#pragma mark -二维码扫描结果
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects
      fromConnection:(AVCaptureConnection *)connection
{
    if (self.scanType == QIYIScanQRCodeType_AR)
    {
        return;
    }
    
    //显示更多菜单时 不处理扫描到的结果
    if (self.isShowingMoreView)
    {
        return;
    }
    
    if (metadataObjects != nil && [metadataObjects count] > 0)
    {
        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];
        NSString *result;
        if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode])
        {
            result = metadataObj.stringValue;
            if ([self.from isEqualToString:@"H5"])
            {
                self.scanQRSuccessBlock(result);
            }
            else
            {
                [self performSelectorOnMainThread:@selector(reportScanResult:) withObject:result waitUntilDone:YES];
            }
        }
        else
        {
            NSLog(@"不是二维码");
        }
    }
}

#pragma mark -AR获取图片结果
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (self.scanType == QIYIScanQRCodeType_Normal)
    {
        return;
    }
    
    if (self.loadModelFinish == NO)
    {
        return;
    }
    
    if (self.handlingImage == YES)
    {
        return;
    }
    
    if (self.newworkStatus == NO)
    {
        return;
    }
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 9.0)
    {
        return;
    }
    
    self.handlingImage = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (![self.errorARScanLabel.text isEqualToString:@"识别中"])
        {
            self.errorARScanLabel.text = @"识别中";
            self.errorARScanLabel.hidden = NO;
            [self startAnimatioTimer];
        }

        if (self.timer == nil && [self.errorARScanLabel.text isEqualToString:@"识别中"])
        {
            [self startAnimatioTimer];
        }
    });
    
    CVImageBufferRef buffer;
    buffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CVPixelBufferLockBaseAddress(buffer, 0);
    uint8_t *base;
    size_t width, height, bytesPerRow;
    base = CVPixelBufferGetBaseAddress(buffer);
    width = CVPixelBufferGetWidth(buffer);
    height = CVPixelBufferGetHeight(buffer);
    bytesPerRow = CVPixelBufferGetBytesPerRow(buffer);
    
    //利用取得影像细部信息格式化 CGContextRef
    CGColorSpaceRef colorSpace;
    CGContextRef cgContext;
    colorSpace = CGColorSpaceCreateDeviceRGB();
    cgContext = CGBitmapContextCreate(base, width, height, 8, bytesPerRow, colorSpace,  kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    
    //透过 CGImageRef 将 CGContextRef 转换成 UIImage
    CGImageRef cgImage;
    cgImage = CGBitmapContextCreateImage(cgContext);
    UIImage *image = [UIImage imageWithCGImage:cgImage scale:1.0 orientation:UIImageOrientationRight];
    CGImageRelease(cgImage);
    CGContextRelease(cgContext);
    
    CVPixelBufferUnlockBaseAddress(buffer, 0);

    UIImage *image1 = [image fixOrientation];
    
    //先裁切图片为3:4
    CGRect rect = CGRectZero;
    CGSize size = image1.size;
    if (size.width/size.height > 0.75)
    {
        rect = CGRectMake((size.width-(size.height*3/4))/2, 0, size.height*3/4, size.height);
    }
    else
    {
        rect = CGRectMake(0, (size.height-(size.width*4/3))/2, size.width, size.width*4/3);
    }
    
    CGImageRef subImageRef = CGImageCreateWithImageInRect(image1.CGImage, rect);
    CGRect smallBounds = CGRectMake(0, 0, CGImageGetWidth(subImageRef), CGImageGetHeight(subImageRef));
    UIGraphicsBeginImageContext(smallBounds.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextDrawImage(context, smallBounds, subImageRef);
    UIImage *smallImage = [UIImage imageWithCGImage:subImageRef];
    UIGraphicsEndImageContext();
    CGImageRelease(subImageRef);

    NSDictionary *value = nil; //[[MDLHandposeManager shareInstance] invokeHandposeWithImage:smallImage];

    if (value.count > 0 && ([[value allKeys] containsObject:@"big"] || [[value allKeys] containsObject:@"middle"] || [[value allKeys] containsObject:@"small"]))
    {
        if (([[value allKeys] containsObject:@"big"] && [[value objectForKey:@"big"] floatValue] > 0.9) || ([[value allKeys] containsObject:@"middle"] && [[value objectForKey:@"middle"] floatValue] > 0.9) || ([[value allKeys] containsObject:@"small"] && [[value objectForKey:@"small"] floatValue] > 0.9))
        {
            
            CGFloat score = 0.0;
            if ([[value allKeys] containsObject:@"big"])
            {
                score = [[value objectForKey:@"big"] floatValue];
            }
            else if ([[value allKeys] containsObject:@"middle"])
            {
                score = [[value objectForKey:@"middle"] floatValue];
            }
            else if([[value allKeys] containsObject:@"small"])
            {
                score = [[value objectForKey:@"small"] floatValue];
            }
            
            NSLog(@"score:%f",score);
            
            NSString *cachePath = [NSFileManager tempPath];
            NSData *imageData = UIImageJPEGRepresentation(image1, 1.0f);
            
            NSString *cacheImagePath = [cachePath stringByAppendingString:@"ARTemImage"];
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:cacheImagePath])
            {
                [[NSFileManager defaultManager] removeItemAtPath:cacheImagePath error:nil];
            }
            
            [imageData writeToFile:cacheImagePath atomically:YES];
            
            WS
            [[QIYIScanQRCodeManager sharedInstance] getARScanResultWithImagePath:cacheImagePath finish:^(BOOL flag, QIYIARScanModel *model) {
                SS
                if (flag == YES && model)
                {
                    [self stopAnimationTimer];
                    for (UIView *view in self.view.subviews)
                    {
                        if ([view isKindOfClass:[QIYIHeartView class]])
                        {
                            view.hidden = YES;
                        }
                    }
                    
                    if (self.viewDidAppear == NO)
                    {
                        return ;
                    }
                    
                    [self.ARScanResultView showARResultVCWithQIYIARScanModel:model tapBtnBlock:^(NSInteger index) {
                        if (index == 0)
                        {
                            [UIView animateWithDuration:0.2 animations:^{
                                SS
                                self.ARScanResultView.frame = CGRectMake(0, SCREEN_HEIGHT, SCREEN_WIDTH, SCREEN_HEIGHT);
                            } completion:^(BOOL finished) {
                                [self startAnimatioTimer];
                                NSString *url = nil;
                                if (model && model.result && model.result.statsUrl.length > 0)
                                {
                                    url = model.result.statsUrl;
                                }
                                else
                                {
                                    return ;
                                }
                                
                                QIYIFalconViewController *falcon = [[QIYIFalconViewController alloc] init];
                                falcon.target = url;
                                falcon.isUnlogin = NO;
                                falcon.hidesBottomBarWhenPushed = YES;
                                [self.navigationController pushViewController:falcon animated:YES];
                            }];
                        }
                        else
                        {
                            //继续扫描
                            self.handlingImage = NO;
                            [UIView animateWithDuration:0.3 animations:^{
                                SS
                                self.ARScanResultView.frame = CGRectMake(0, SCREEN_HEIGHT, SCREEN_WIDTH, SCREEN_HEIGHT);
                            } completion:^(BOOL finished) {
                                [self startAnimatioTimer];
                            }];
                        }
                    }];
                    
                    [UIView animateWithDuration:0.3 animations:^{
                        SS
                        self.ARScanResultView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
                    } completion:^(BOOL finished) {
                        
                    }];
                    
                    [self scanVoice];
                }
                else if(flag == YES)
                {
                    [self stopAnimationTimer];
                    for (UIView *view in self.view.subviews)
                    {
                        if ([view isKindOfClass:[QIYIHeartView class]])
                        {
                            view.hidden = YES;
                        }
                    }
                    
                    if (self.viewDidAppear == NO)
                    {
                        return ;
                    }
                    
                    [self.ARScanResultView showARResultVCWithQIYIARScanModel:nil tapBtnBlock:^(NSInteger index) {
                        if (index == 0)
                        {
                            [UIView animateWithDuration:0.2 animations:^{
                                SS
                                self.ARScanResultView.frame = CGRectMake(0, SCREEN_HEIGHT, SCREEN_WIDTH, SCREEN_HEIGHT);
                            } completion:^(BOOL finished) {
                                
                                NSString *url = @"http://home.qiyi.domain/";
                                QIYIFalconViewController *falcon = [[QIYIFalconViewController alloc] init];
                                falcon.target = url;
                                falcon.isUnlogin = NO;
                                falcon.hidesBottomBarWhenPushed = YES;
                                [self.navigationController pushViewController:falcon animated:YES];
                            }];
                        }
                        else
                        {
                            //继续扫描
                            self.handlingImage = NO;
                            [UIView animateWithDuration:0.3 animations:^{
                                SS
                                self.ARScanResultView.frame = CGRectMake(0, SCREEN_HEIGHT, SCREEN_WIDTH, SCREEN_HEIGHT);
                            } completion:^(BOOL finished) {
                                [self startAnimatioTimer];
                            }];
                        }
                    }];
                    
                    [UIView animateWithDuration:0.3 animations:^{
                        SS
                        self.ARScanResultView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
                    } completion:^(BOOL finished) {
                        
                    }];
                    
                    [self scanVoice];
                }
            }];
            
            //识别成功的pingback
            dispatch_async(dispatch_get_main_queue(), ^{
                self.ARScanSucc = self.ARScanSucc + 1;
                [self uploadPinBackForARWithData1:[NSString stringWithFormat:@"%ld",self.ARScanFail] andData2:[NSString stringWithFormat:@"%ld",self.ARScanSucc]];
                self.ARScanFail = 0;
                self.ARScanSucc = 0;
            });
        }
        else
        {
            self.ARScanFail = self.ARScanFail + 1;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.handlingImage = NO;
            });
        }
    }
    else
    {
        self.ARScanFail = self.ARScanFail + 1;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.handlingImage = NO;
        });
    }
}

#pragma mark - 焦距变化
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if( [keyPath isEqualToString:@"adjustingFocus"] )
    {
        [[change objectForKey:NSKeyValueChangeNewKey] isEqualToNumber:[NSNumber numberWithInt:1]];
    }
}

- (void)reportScanResult:(NSString *)result
{
    [self stopReading];
    
    static BOOL isFinish = YES;
    if (!isFinish)
    {
        return;
    }
    
    isFinish = NO;
    // 以下处理了结果，继续下次扫描
    if (result == nil || result.length == 0)
    {
        [self scanVoice];
        
        [[QIYIHUDViewController sharedInstance] showErrorDelay1sWithString:NSLocalizedString(@"未识别到二维码", nil)];
    }
    else
    {
        [self actionWithScanResultString:result];
    }
    
    isFinish = YES;
    
    if ([self.from isEqualToString:@"public_menu"])
    {
        if (self.scanQRSuccessBlock)
        {
            self.scanQRSuccessBlock(result);
        }
    }
    
}

//打开系统灯光
- (void)systemLightSwitch:(BOOL)open
{
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([device hasTorch])
    {
        [device lockForConfiguration:nil];
        if (open)
        {
            [device setTorchMode:AVCaptureTorchModeOn];
        }
        else
        {
            [device setTorchMode:AVCaptureTorchModeOff];
        }
        [device unlockForConfiguration];
    }
}

#pragma mark - 处理点击二维码事件 -
- (void)tapMyQRCodeAction:(id)sender
{
    //跳转到我的二维码
    QIYIMyCodeViewController *myCodeVC = [[QIYIMyCodeViewController alloc] initWithNibName:nil bundle:nil];
    myCodeVC.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:myCodeVC animated:YES];
    
    [self stopReading];
}

- (void)tapShowMoreQRCodeView:(UITapGestureRecognizer *)tap
{
    self.isShowingMoreView = YES;
    
    NSString *temString = nil;
    
    [self getTorchStatus];
    
    if(self.lightState)
    {
        temString = NSLocalizedString(@"关闭闪光灯", nil);
    }
    else
    {
        temString = NSLocalizedString(@"打开闪光灯", nil);
    }
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
    {
        WS
        QIYIActionSheetView *actionView = [[QIYIActionSheetView alloc] initWithTips:nil tipsColor:nil actionNameArray:@[NSLocalizedString(@"从相册选择二维码图片", nil),temString] actionColorArray:nil cancelName:@"取消" cancelColor:nil cancelActionBlock:^{
            
        } actionBlock:^(NSUInteger index) {
            SS
            [self clickedButtonAtIndex:index];
        } dismissBlock:^{
            SS
            self.isShowingMoreView = NO;
        }];
        
        [actionView showOnWindow];
    }
    else
    {
        WS
        QIYIActionSheetView *actionView = [[QIYIActionSheetView alloc] initWithTips:nil tipsColor:nil actionNameArray:@[temString] actionColorArray:nil cancelName:@"取消" cancelColor:nil cancelActionBlock:^{
            
        } actionBlock:^(NSUInteger index) {
            SS
            [self clickedButtonAtIndex:index];
        } dismissBlock:^{
            SS
            [self startReading];
        }];
        
        [actionView showOnWindow];
    }
}

- (void)clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
    {
        if(buttonIndex == 0)
        {
            //相册权限处理一般逻辑
            if([QIYIAuthorizationCenter systemAlbumAuthorization] == NO)
            {
                return;
            }
            
            UIImagePickerController * picker = [[UIImagePickerController alloc] init];
            picker.delegate = self;
            
            [picker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
            [picker setAllowsEditing:NO];
            self.imagePickerController = picker;
            [self presentViewController:picker animated:YES completion:^{
                
            }];
        }
        else if (buttonIndex == 1)
        {
            BOOL torchStatus = !self.lightState;
            [self systemLightSwitch:torchStatus];
        }
    }
    else
    {
        BOOL torchStatus = !self.lightState;
        [self systemLightSwitch:torchStatus];
    }
}

#pragma mark - 切换到
- (void)changeToScanType:(QIYIScanQRCodeType)scanType
{
    //如果没有权限，则不显示底部tabbar按钮
    NSString *ARKey = [NSString stringWithFormat:@"%@_ARKey",[QIYIMyUserInfoManager sharedInstance].myUserName];
    NSString *AR = [[NSUserDefaults standardUserDefaults] objectForKey:ARKey];
    if (AR && [AR isEqualToString:@"YES"])
    {
        self.bottomView.hidden = NO;
    }
    else
    {
        self.bottomView.hidden = YES;
    }
    
    if (scanType == QIYIScanQRCodeType_Normal)
    {
        [self scanItemBtnPressAction:nil];
    }
    else
    {
        NSString *ARKey = [NSString stringWithFormat:@"%@_ARKey",[QIYIMyUserInfoManager sharedInstance].myUserName];
        NSString *AR = [[NSUserDefaults standardUserDefaults] objectForKey:ARKey];
        if (AR == nil || AR.length == 0 || [AR isEqualToString:@"NO"])
        {
            [self scanItemBtnPressAction:nil];
            return;
        }

        [self scanARItemBtnPressAction:nil];
    }
}


#pragma mark - 切换AR和二维码扫描
- (void)scanItemBtnPressAction:(id)sender
{
    if (self.scanItemBtn.selected == YES)
    {
        return;
    }
    
    self.scanItemBtn.selected = YES;
    self.scanARItemBtn.selected = NO;
    
    self.scanType = QIYIScanQRCodeType_Normal;
    
    if (self.isFrontCapture)
    {
        self.isFrontCapture = !self.isFrontCapture;
        [self changeCameraInputDeviceisFront:self.isFrontCapture];
    }
    
    //重置动画
    [self.lineImageView.layer removeAllAnimations];
    [self scanLineAnimation];
}

- (void)scanARItemBtnPressAction:(id)sender
{
    NSString *ARKey = [NSString stringWithFormat:@"%@_ARKey",[QIYIMyUserInfoManager sharedInstance].myUserName];
    NSString *AR = [[NSUserDefaults standardUserDefaults] objectForKey:ARKey];
    if (AR == nil || AR.length == 0 || [AR isEqualToString:@"NO"])
    {
        [self scanItemBtnPressAction:nil];
        return;
    }
    
    if (self.scanARItemBtn.selected == YES)
    {
        return;
    }
    
    self.handlingImage = NO;
    self.scanItemBtn.selected = NO;
    self.scanARItemBtn.selected = YES;
    
    self.scanType = QIYIScanQRCodeType_AR;
    
    if (self.newworkStatus == NO)
    {
        self.errorARScanLabel.text = @"无网络连接，请检测网络设置";
        self.errorARScanLabel.hidden = NO;
        [self stopAnimationTimer];
    }
    else
    {
        if (self.loadModelFinish == YES)
        {
            [self startAnimatioTimer];
        }
        else
        {
             [self stopAnimationTimer];
        }
    }
    
    //
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 9.0)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"AR识别需要iOS 9.0及以上版本" delegate:nil cancelButtonTitle:@"知道了" otherButtonTitles:nil];
            [alert show];
            
            self.errorARScanLabel.text = @"当前手机系统版本较低";
            self.errorARScanLabel.hidden = NO;
        });
        
        return;
    }
    
    //初始化AR模型
    if (NO)//([MDLHandposeManager shareInstance].modelIsExist == NO)
    {
        if (self.downloadingARModal == NO &&self.loadModelFinish == NO)
        {
            self.downloadingARModal = YES;
            
            self.errorARScanLabel.hidden = NO;
            self.errorARScanLabel.text = @"正在初始化，请稍候";
            iPhoneXMPPAppDelegate *delegate = (iPhoneXMPPAppDelegate *)[UIApplication sharedApplication].delegate;

            if([delegate.netStatus isEqualToString:@"14"])
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"使用AR识别心形手势前，需要从网络下载相关模型数据包。大约16MB，目前为移动网络，是否现在下载？" delegate:self cancelButtonTitle:@"稍后下载" otherButtonTitles:@"立即下载", nil];
                [alert show];
            }
            else if ([delegate.netStatus isEqualToString:@"1"])
            {
                /*
                WS
                [[MDLHandposeManager shareInstance] initHandposeModelWithFinishBlock:^(BOOL flag) {
                    if (flag)
                    {
                        SS
                        self.loadModelFinish = [[MDLHandposeManager shareInstance] loadHandposeModel];
                        if (self.loadModelFinish == NO)
                        {
                            //重试一次
                            self.loadModelFinish = [[MDLHandposeManager shareInstance] loadHandposeModel];
                            //如果还失败，则提示加载模型失败吧;
                            if (self.loadModelFinish == NO)
                            {
                                self.errorARScanLabel.hidden = NO;
                                self.errorARScanLabel.text = @"初始化失败，请稍后再试";
                            }
                            else
                            {
                                self.errorARScanLabel.text = @"";
                                self.errorARScanLabel.hidden = YES;
                            }
                        }
                        else
                        {
                            self.errorARScanLabel.text = @"";
                            self.errorARScanLabel.hidden = YES;
                        }
                        
                        self.downloadingARModal = NO;
                    }
                    else
                    {
                        self.downloadingARModal = NO;
                        self.errorARScanLabel.hidden = NO;
                        self.errorARScanLabel.text = @"初始化失败，请稍后再试";
                    }
                }];*/
            }
            else
            {
                self.downloadingARModal = NO;
                self.loadModelFinish = NO;
                self.errorARScanLabel.hidden = NO;
                self.errorARScanLabel.text = @"初始化失败，请稍后再试";
            }
        }
    }
    else
    {
        if (self.loadModelFinish == NO)
        {
            /*
            WS
            [[MDLHandposeManager shareInstance] initHandposeModelWithFinishBlock:^(BOOL flag) {
                if (flag)
                {
                    SS
                    self.loadModelFinish = [[MDLHandposeManager shareInstance] loadHandposeModel];
                    if (self.loadModelFinish == NO)
                    {
                        //重试一次
                        self.loadModelFinish = [[MDLHandposeManager shareInstance] loadHandposeModel];
                        //如果还失败，则提示加载模型失败吧;
                        if (self.loadModelFinish == NO)
                        {
                            self.errorARScanLabel.hidden = NO;
                            self.errorARScanLabel.text = @"初始化失败，请稍后再试";
                        }
                        else
                        {
                            self.errorARScanLabel.text = @"";
                            self.errorARScanLabel.hidden = YES;
                        }
                    }
                    else
                    {
                        self.errorARScanLabel.text = @"";
                        self.errorARScanLabel.hidden = YES;
                    }
                }
                else
                {
                    self.errorARScanLabel.hidden = NO;
                    self.errorARScanLabel.text = @"初始化失败，请稍后再试";
                }
            }];*/
        }
    }
}

#pragma mark -切换前后置摄像头
- (void)changeCameraInputDeviceisFront:(BOOL)isFront
{
    NSArray *inputs = self.captureSession.inputs;
    for (AVCaptureDeviceInput *input in inputs )
    {
        AVCaptureDevice *device = input.device;
        if ( [device hasMediaType:AVMediaTypeVideo] )
        {
            AVCaptureDevicePosition position = device.position;
            AVCaptureDevice *newCamera =nil;
            AVCaptureDeviceInput *newInput =nil;
            
            if (position ==AVCaptureDevicePositionFront)
            {
                newCamera = [self cameraWithPosition:AVCaptureDevicePositionBack];
            }
            else
            {
                newCamera = [self cameraWithPosition:AVCaptureDevicePositionFront];
            }
            newInput = [AVCaptureDeviceInput deviceInputWithDevice:newCamera error:nil];
            
            [self.captureSession beginConfiguration];
            [self.captureSession removeInput:input];
            [self.captureSession addInput:newInput];
            [self.captureSession commitConfiguration];
            
            [self changeCameraAnimation];
            
            break;
        }
    }
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices)
    {
        if ( device.position == position )
        {
            return device;
        }
    }
    
    return nil;
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
    [self.videoPreviewLayer addAnimation:changeAnimation forKey:@"changeAnimation"];
}

- (void)animationDidStart:(CAAnimation *)anim
{
    [self.captureSession startRunning];
}

#pragma mark - 自动对焦
- (void)subjectAreaDidChange:(NSNotification *)notification
{
    //先进行判断是否支持控制对焦
    if (self.captureDevice.isFocusPointOfInterestSupported &&[self.captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus])
    {
        //自动对焦
        [self setCaptureDeviceAutoFocusWithPoint:CGPointMake(SCREEN_WIDTH/2, SCREEN_HEIGHT/2)];
    }
}

#pragma mark - 获取闪光灯状态 -
- (void)getTorchStatus
{
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if(device.torchMode == AVCaptureTorchModeOn)
    {
        self.lightState = YES;
    }
    else if(device.torchMode ==AVCaptureTorchModeOff)
    {
        self.lightState = NO;
    }
}

#pragma mark - 点击屏幕对焦
- (void)setCaptureDeviceAutoFocusWithPoint:(CGPoint)point
{
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];;
    NSError *error;
    if ([captureDevice lockForConfiguration:&error])
    {
        CGPoint location = point;
        CGSize frameSize = self.videoPreviewLayer.frame.size;
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
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
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

- (UIImage *)drawImageWithLayer:(CALayer *)layer
{
    UIGraphicsBeginImageContext(layer.frame.size);
    [layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return viewImage;
}

#pragma mark - UIImage Picker Delegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    WS
    [picker dismissViewControllerAnimated:YES completion:^{
        SS
        UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
        CIImage *ciImage = [CIImage imageWithCGImage:[image CGImage]];
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
        {
            CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:nil];
            NSArray *arr = [detector featuresInImage:ciImage];
            if (arr.count>0)
            {
                CIQRCodeFeature *feature = arr[0];
                NSString *string = feature.messageString;
                [self actionWithScanResultString:string];
            }
            else
            {
                [self scanVoice];
                
                [[QIYIHUDViewController sharedInstance] showErrorDelay1sWithString:NSLocalizedString(@"未识别到二维码", nil)];

            }
        }
        else
        {
           //iOS7不支持从图片中读取二维码
        }
    }];
    
    [self stopReading];
}

- (BOOL)isURL:(NSString *)string
{
    
    NSString *regex = @"(((http[s]{0,1}|ftp)://){0,1}[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,8})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)|(www.[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,8})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)|((http[s]{0,1}|ftp)://){0,1}((25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9])\\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[0-9])(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [pred evaluateWithObject:string];
}

- (void)actionWithScanResultString:(NSString *)string
{
    [self scanVoice];
    
    if ([string hasPrefix:@"https://home.iqiyi.com/code/"])
    {
        //热聊能够处理的协议
        if ([string hasPrefix:@"https://home.iqiyi.com/code/s/"])
        {
            [self uploadPinBackWithExtra:@"card"];
            
            //扫描个人名片
            NSString *subString = [string substringFromIndex:[@"https://home.iqiyi.com/code/s/" length]];
            if(subString)
            {
                NNLHashids *hash = [[NNLHashids alloc] initWithSalt:salt];
                NSArray *array = [hash decode:subString];
                if (array && array.count > 0)
                {
                    NSNumber *number = array[0];
                    
                    NSString *userJidStr = [NSString stringWithFormat:@"%@",number];
                    
                    [[QIYISQLManager sharedSQLManager] getUserInfoFromAllUserInfoWithJid:userJidStr block:^(BOOL isFriend, BOOL isStar, QIYIUserModel *userModelBack) {
                        
                        UIViewController *vc;

                        if ([userModelBack.subtype isEqualToString:@"SERVICE_ACCOUNT"])
                        {
                            //公众号服务号类型直接跳转到聊天室即可
                            QIYIChatRoomViewController *chatRoom = [QIYIChatRoomViewController shareChatRoomViewController];
                            chatRoom.hidesBottomBarWhenPushed = YES;
                            chatRoom.isPopOne = YES;
                            
                            NSMutableDictionary *chatRoomInfoDict = [[NSMutableDictionary alloc] init];
                            chatRoomInfoDict[@"roomJidb"] = userJidStr;
                            chatRoomInfoDict[@"roomType"] = @"chat";
                            chatRoomInfoDict[@"defaultGroupName"] = userModelBack.chName;
                            chatRoom.chatInfoDict = chatRoomInfoDict;
                            vc = chatRoom;
                        }
                        else
                        {
                            if (isFriend)
                            {
                                QIYIChatRoomViewController *chatRoom = [QIYIChatRoomViewController shareChatRoomViewController];
                                chatRoom.hidesBottomBarWhenPushed = YES;
                                chatRoom.isPopOne = YES;
                                
                                NSMutableDictionary *chatRoomInfoDict = [[NSMutableDictionary alloc] init];
                                chatRoomInfoDict[@"roomJidb"] = userJidStr;
                                chatRoomInfoDict[@"roomType"] = @"chat";
                                chatRoomInfoDict[@"defaultGroupName"] = userModelBack.chName;
                                chatRoom.chatInfoDict = chatRoomInfoDict;
                                vc = chatRoom;
                                
                            }
                            else
                            {
                                if ([userModelBack.type isEqualToString:@"official"])
                                {
                                    QIYIOfficialViewController *officialVC = [[QIYIOfficialViewController alloc] init];
                                    officialVC.isFromRoomVC = NO;
                                    officialVC.officialJidStr = userJidStr;
                                    officialVC.navBarTitle = userModelBack.chName;
                                    officialVC.hidesBottomBarWhenPushed = YES;
                                    vc = officialVC;
                                    
                                }
                                else
                                {
                                    //进入个人信息页
                                    if ([userModelBack.jid isEqualToString:[QIYIMyUserInfoManager sharedInstance].myUid])
                                    {
                                        QIYIFriendInfoViewController *friendVC = [[QIYIFriendInfoViewController alloc] initWithNibName:nil bundle:nil];
                                        friendVC.friendsJidStr = userJidStr;
                                        friendVC.hidesBottomBarWhenPushed = YES;
                                        vc = friendVC;
                                        __weak __typeof(vc)weakVC = vc;
                                        friendVC.backBlock = ^(void){
                                            __strong __typeof(weakVC)strongVC = weakVC;
                                            [strongVC.navigationController popViewControllerAnimated:YES];
                                        };
                                    }
                                    else
                                    {
                                        //进入聊天室
                                        QIYIChatRoomViewController *chatRoom = [QIYIChatRoomViewController shareChatRoomViewController];
                                        chatRoom.hidesBottomBarWhenPushed = YES;
                                        chatRoom.isPopOne = YES;
                                        
                                        NSMutableDictionary *chatRoomInfoDict = [[NSMutableDictionary alloc] init];
                                        chatRoomInfoDict[@"roomJidb"] = userJidStr;
                                        chatRoomInfoDict[@"roomType"] = @"chat";
                                        chatRoomInfoDict[@"defaultGroupName"] = userModelBack.chName;
                                        chatRoom.chatInfoDict = chatRoomInfoDict;
                                        vc = chatRoom;
                                    }
                                    
                                }
                            }
                        }
                        
                        if (self.navigationController == nil)
                        {
                            
                        }
                        else
                        {
                            NSMutableArray *array = [NSMutableArray arrayWithArray:[[self.navigationController viewControllers] mutableCopy]];
                            for (UIViewController *temVC in array)
                            {
                                if ([temVC isKindOfClass:[QIYIScanQRCodeViewController class]])
                                {
                                    [array removeObject:temVC];
                                    break;
                                }
                            }
                            
                            [array addObject:vc];
                            
                            [self.navigationController setViewControllers:array animated:YES];
                        }
                    }];
                }
            }
            else
            {
                //数据错误了
                
                [[QIYIHUDViewController sharedInstance] showErrorWithString:@"二维码数据错误"];
                
                WS
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [[QIYIHUDViewController sharedInstance] dismiss];
                    SS
                    [self startReading];
                });

            }
            
        }
        else if([string hasPrefix:@"https://home.iqiyi.com/code/g/"])
        {
            [self uploadPinBackWithExtra:@"groupcard"];
            
            //扫描群聊名片
            NSString *subString = [string substringFromIndex:[@"https://home.iqiyi.com/code/g/" length]];
            if(subString)
            {
                WS
                [[QIYIScanQRCodeManager sharedInstance] isGroupMemberWithGroupToken:subString finishBlock:^(QIYIDataGroupMemberModel *model, NSError *error) {
                    SS
                    if(model && error == nil)
                    {
                        NNLHashids *hash = [[NNLHashids alloc] initWithSalt:salt];
                        NSArray *array = [hash decode:model.gid];
                        
                        if(model.isMember && array && array.count > 0)
                        {
                            NSString *gid = [NSString stringWithFormat:@"%@",array[0]];
                            [[QIYISQLManager sharedSQLManager] searchGroupWithJid:gid block:^(QIYIGroupModel *group) {
                                NSMutableDictionary *chatRoomInfoDict = [[NSMutableDictionary alloc] init];
                                if (group.jid == nil || group.jid.length == 0)
                                {
                                    [QIYIHUDViewController sharedInstance].disabled = YES;
                                    [[QIYIHUDViewController sharedInstance] showLoadingWithString:NSLocalizedString(@"正在更新群信息", nil)];
                                    [self updateGroupInfoWithJid:gid finishBlock:^(QIYIGroupModel *group1, NSError *error) {
                                        [[QIYIHUDViewController sharedInstance] dismiss];
                                        chatRoomInfoDict[@"jidStr"] = group1.jid;
                                        chatRoomInfoDict[@"roomType"] = @"groupchat";
                                        chatRoomInfoDict[@"defaultGroupName"] = ((group1.Name == nil ||group1.Name.length == 0)?@"群聊":group1.Name);
                                        chatRoomInfoDict[@"isGroupNameNil"] = [NSNumber numberWithBool:(group1.Name == nil || group1.Name.length == 0)?YES:NO];
                                        [[NSNotificationCenter defaultCenter] postNotificationName:kQIYIChatToChatRoomNotification object:chatRoomInfoDict];
                                        [[NSNotificationCenter defaultCenter] postNotificationName:kQIYIChatDidInertNotification object:nil];
                                    }];
                                }
                                else
                                {
                                    chatRoomInfoDict[@"jidStr"] = group.jid;
                                    chatRoomInfoDict[@"roomType"] = @"groupchat";
                                    chatRoomInfoDict[@"defaultGroupName"] = ((group.Name == nil ||group.Name.length == 0)?@"群聊":group.Name);
                                    chatRoomInfoDict[@"isGroupNameNil"] = [NSNumber numberWithBool:(group.Name == nil || group.Name.length == 0)?YES:NO];
                                    
                                    [[NSNotificationCenter defaultCenter] postNotificationName:kQIYIChatToChatRoomNotification object:chatRoomInfoDict];
                                    [[NSNotificationCenter defaultCenter] postNotificationName:kQIYIChatDidInertNotification object:nil];
                                }
                            }];
                            
                            return ;
                        }
                        else if(model.url)
                        {
                            UIViewController *temVC = nil;
                            for (UIViewController *vc in self.navigationController.viewControllers)
                            {
                                if ([vc isKindOfClass:[QIYIFalconViewController class]])
                                {
                                    temVC = vc;
                                    break;
                                }
                            }
                            
                            if (temVC)
                            {
                                QIYIFalconViewController *falcon = (QIYIFalconViewController *)temVC;
                                [falcon.webViewEngine loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:model.url]]];
                                WS
                                falcon.backBlock = ^(void){
                                    SS
                                    [self backAction];
                                };
                                falcon.isUnlogin = YES;
                                falcon.hidesBottomBarWhenPushed = YES;
                                [self.navigationController popToViewController:falcon animated:YES];
                            }
                            else
                            {
                                QIYIFalconViewController *falcon = [[QIYIFalconViewController alloc] init];
                                falcon.target = model.url;
                                
                                falcon.isUnlogin = YES;
                                falcon.hidesBottomBarWhenPushed = YES;
                               
                                __weak __typeof(falcon)weakfalcon = falcon;
                                falcon.backBlock = ^(void){
                                    __strong __typeof(weakfalcon)strongfalcon = weakfalcon;
                                    [strongfalcon.navigationController popViewControllerAnimated:YES];
                                };
                                
                                
                                NSMutableArray *array = [NSMutableArray arrayWithArray:[[self.navigationController viewControllers] mutableCopy]];
                                UIViewController *QRCodeVC = nil;
                                for (UIViewController *vc in array)
                                {
                                    if ([vc isKindOfClass:[QIYIScanQRCodeViewController class]])
                                    {
                                        QRCodeVC = vc;
                                        break;
                                    }
                                }
                                
                                if (QRCodeVC)
                                {
                                    [array removeObject:QRCodeVC];
                                }
                                
                                falcon.hidesBottomBarWhenPushed = YES;
                                [array addObject:falcon];
                                
                                [self.navigationController setViewControllers:array animated:YES];
                                
                            }
                            
                            return ;
                        }
                    }
                    else if (error)
                    {
                        if(error.code == NSURLErrorNotConnectedToInternet || error.code == NSURLErrorTimedOut)
                        {
                            [[QIYIHUDViewController sharedInstance] showErrorWithString:@"当前网络不可用"];
                            WS
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                [[QIYIHUDViewController sharedInstance] dismiss];
                                SS
                                [self startReading];
                            });
                        }
                        else if([error.domain isEqualToString:@"E001"])
                        {
                            [[QIYIHUDViewController sharedInstance] showErrorWithString:@"二维码已过期"];

                            WS
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                [[QIYIHUDViewController sharedInstance] dismiss];
                                SS
                                [self startReading];
                            });
                        }
                        else
                        {
                            [[QIYIHUDViewController sharedInstance] showErrorWithString:NSLocalizedString(@"二维码数据错误", nil)];

                            WS
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                [[QIYIHUDViewController sharedInstance] dismiss];
                                SS
                                [self startReading];
                            });
                        }
                    }
                    else
                    {
                        [[QIYIHUDViewController sharedInstance] showErrorWithString:NSLocalizedString(@"二维码数据错误", nil)];
                        
                        WS
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            [[QIYIHUDViewController sharedInstance] dismiss];
                            SS
                            [self startReading];
                        });
                    }
                }];
            }
            else
            {
                //数据错误了
                [[QIYIHUDViewController sharedInstance] showErrorWithString:NSLocalizedString(@"二维码数据错误", nil)];
                
                WS
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [[QIYIHUDViewController sharedInstance] dismiss];
                    SS
                    [self startReading];
                });
            }
        }
        else if ([string hasPrefix:@"https://home.iqiyi.com/code/l/"])
        {
            [self uploadPinBackWithExtra:@"login"];
            
            //扫描登录
            NSString *subString = [string substringFromIndex:[@"https://home.iqiyi.com/code/l/" length]];
            if(subString && subString.length > 1)
            {
                NSString *loginToken = [NSString stringWithFormat:@"%@",[subString substringWithRange:NSMakeRange(1, subString.length-1)]];
                WS
                [[QIYIScanQRCodeManager sharedInstance] uploadLoginToken:loginToken finishBlock:^(QIYIQRCodeLoginModel *loginModel, NSError *error) {
                    SS
                    if (loginModel && error == nil)
                    {
                        QIYIScanLoginViewController *loginVC = [[QIYIScanLoginViewController alloc] initWithNibName:nil bundle:nil];
                        
                        if (loginModel.data == nil || loginModel.data.type == nil)
                        {
                            if (loginModel.data == nil)
                            {
                                loginModel.data = [[QIYIQRCodeLoginDataModel alloc] init];
                            }
                            
                            NSString *typeString = [subString substringWithRange:NSMakeRange(0, 1)];
                            
                            if ([typeString isEqualToString:@"P"])
                            {
                                loginModel.data.type = @"PC";
                            }
                            else if ([typeString isEqualToString:@"L"])
                            {
                                loginModel.data.type = @"Linux";
                            }
                            else if ([typeString isEqualToString:@"W"])
                            {
                                loginModel.data.type = @"Web";
                            }
                            else if ([typeString isEqualToString:@"M"])
                            {
                                loginModel.data.type = @"Mac";
                            }
                            else
                            {
                                loginModel.data.type = @"PC";
                            }
                        }
                        
                        loginVC.model = loginModel;
                        loginVC.loginToken = loginToken;
                        [self presentViewController:loginVC animated:YES completion:nil];
                        
                        __weak __typeof(loginVC) weakVC = loginVC;
                        loginVC.cancelBlock = ^(void){
                            __strong __typeof(weakVC) strongVC = weakVC;
                            [strongVC dismissViewControllerAnimated:YES completion:nil];
                            [self.navigationController popViewControllerAnimated:NO];
                        };
                        
                        return ;
                    }
                    else if (error)
                    {
                        if(error.code == NSURLErrorNotConnectedToInternet || error.code == NSURLErrorTimedOut)
                        {
                            [[QIYIHUDViewController sharedInstance] showErrorWithString:NSLocalizedString(@"当前网络不可用", nil)];
                            
                            WS
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                [[QIYIHUDViewController sharedInstance] dismiss];
                                SS
                                [self startReading];
                            });

                        }
                        else
                        {
                            [[QIYIHUDViewController sharedInstance] showErrorWithString:NSLocalizedString(@"二维码数据错误", nil)];
                            
                            WS
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                [[QIYIHUDViewController sharedInstance] dismiss];
                                SS
                                [self startReading];
                            });
                        }
                    }
                }];
            }
            else
            {
                //缺少数据
                [[QIYIHUDViewController sharedInstance] showErrorWithString:NSLocalizedString(@"二维码数据错误", nil)];
                
                WS
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [[QIYIHUDViewController sharedInstance] dismiss];
                    SS
                    [self startReading];
                });

            }
        }
        else
        {
            //暂时不支持的协议
            [[QIYIHUDViewController sharedInstance] showErrorWithString:NSLocalizedString(@"二维码数据错误", nil)];
            
            WS
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[QIYIHUDViewController sharedInstance] dismiss];
                SS
                [self startReading];
            });
        }
    }
    else
    {
        if ([self isURL:string])
        {
            NSString *baseUrl;
            if ([[string lowercaseString] rangeOfString:@"http"].location == NSNotFound)
            {
                baseUrl = [NSString stringWithFormat:@"http://%@",string];
            }
            else
            {
                baseUrl = string;
            }
            
            QIYIFalconViewController *falcon = [[QIYIFalconViewController alloc] init];
            falcon.target = baseUrl;
            falcon.isUnlogin = NO;
            
//            __weak __typeof(falcon)weakfalcon = falcon;
//            falcon.backBlock = ^(void){
//                __strong __typeof(weakfalcon)strongfalcon = weakfalcon;
//                [strongfalcon.navigationController popViewControllerAnimated:YES];
//            };
            
            
            NSMutableArray *array = [NSMutableArray arrayWithArray:[[self.navigationController viewControllers] mutableCopy]];
            UIViewController *QRCodeVC = nil;
            for (UIViewController *vc in array)
            {
                if ([vc isKindOfClass:[QIYIScanQRCodeViewController class]])
                {
                    QRCodeVC = vc;
                    break;
                }
            }
            
            if (QRCodeVC)
            {
                [array removeObject:QRCodeVC];
            }
            
            falcon.hidesBottomBarWhenPushed = YES;
            [array addObject:falcon];
            
            [self.navigationController setViewControllers:array animated:YES];
            [self uploadPinBackWithExtra:@"link"];
        }
        else
        {
            QIYIScanResultViewController *scanResultVC = [[QIYIScanResultViewController alloc] initWithNibName:nil bundle:nil];
            scanResultVC.scanResult = string;
            scanResultVC.type = ScanResultTypeText;
           
            __weak __typeof(scanResultVC)weakscanResultVC = scanResultVC;
            scanResultVC.backBlock = ^(void){
                __strong __typeof(weakscanResultVC)strongscanResultVC = weakscanResultVC;
                [strongscanResultVC.navigationController popViewControllerAnimated:YES];
            };

            NSMutableArray *array = [NSMutableArray arrayWithArray:[[self.navigationController viewControllers] mutableCopy]];
            UIViewController *QRCodeVC = nil;
            for (UIViewController *vc in array)
            {
                if ([vc isKindOfClass:[QIYIScanQRCodeViewController class]])
                {
                    QRCodeVC = vc;
                    break;
                }
            }
            
            if (QRCodeVC)
            {
                [array removeObject:QRCodeVC];
            }
            
            scanResultVC.hidesBottomBarWhenPushed = YES;
            [array addObject:scanResultVC];
            
            [self.navigationController setViewControllers:array animated:YES];
            
            [self uploadPinBackWithExtra:@"txt"];
        }
    }
}

- (void)updateGroupInfoWithJid:(NSString *)jid finishBlock:(void(^)(QIYIGroupModel *group,NSError *error))finishBlock
{
    NSString *authCookie = [QIYIMyUserInfoManager sharedInstance].myAuthCookie;
    if (authCookie == nil)
    {
        return;
    }

    NSDictionary *headerField = [QYReliaoHttpManger getAFNetworkManagerHeaderField];;

    [[AFNetworkManager sharedAFNetworkManager] QIYI_GET:HotChatHttpUrl(@"/account/v2/public/group/info") headerField:headerField parameters:@{@"groupId":jid} progress:nil success:^(NSURLSessionDataTask *task, id responseObject){
        NSData *resultData = responseObject;
        NSDictionary *resultDict = [NSJSONSerialization JSONObjectWithData:resultData options:0 error:nil];
        if ([resultDict[@"code"] isEqualToString:@"A00000"] && [resultDict[@"data"] isKindOfClass:[NSDictionary class]] && [resultDict[@"data"][@"status"] isEqualToString:@"SUCC"])
        {
            NSDictionary *dict = resultDict[@"data"];
            
            if (dict && [dict isKindOfClass:[NSDictionary class]] && [dict objectForKey:@"groupInfo"] && [[dict objectForKey:@"groupInfo"] isKindOfClass:[NSDictionary class]])
            {
                NSDictionary *groupInfoDic = [dict objectForKey:@"groupInfo"];
                
                QIYIGroupModel *group = [[QIYIGroupModel alloc] init];
                NSString *jid = [NSString stringWithFormat:@"%@",groupInfoDic[@"gid"]];
                group.jid = jid;
                group.type = groupInfoDic[@"type"];
                group.memberNumber = [NSNumber numberWithInt:[groupInfoDic[@"num"] intValue]];
                group.Name = groupInfoDic[@"name"];
                group.iconUrl = groupInfoDic[@"icon"];
                group.groupFlag = [groupInfoDic[@"groupFlag"] intValue];
                group.jianPin = groupInfoDic[@"jianPin"];
                group.quanPin = groupInfoDic[@"quanPin"];
                group.defaultName = groupInfoDic[@"defaultName"];
                group.mailAddress = groupInfoDic[@"mailAddress"];
                
                if ([jid isEqualToString:groupInfoDic[@"gid"]])
                {
                    NSArray *memberArray;
                    if ([dict[@"status"] isEqualToString:@"GROUP_NOT_EXIST"])
                    {
                        memberArray = @[];
                        [QYReliaoHttpManger deleteGroupFromServerWithGroupJid:group.jid];
                    }
                    else
                    {
                        memberArray = groupInfoDic[@"members"];
                    }

                    //延迟执行，刷新快会导致session列表闪
                    [[QIYISQLManager sharedSQLManager] updateGroupWithGroup:group memberArray:memberArray owner:[NSString stringWithFormat:@"%@",groupInfoDic[@"owner"]] block:^{
                        finishBlock(group, nil);
                    }];
                }
                else
                {
                    NSError *error = [NSError errorWithDomain:@"jid不同" code:-1 userInfo:nil];
                    finishBlock(nil,error);
                }
                
                return ;
            }
        }
        else if ([resultDict[@"code"] isEqualToString:@"A00000"] && [resultDict[@"data"] isKindOfClass:[NSDictionary class]] && [resultDict[@"data"][@"status"] isEqualToString:@"NOT_GROUP_MEMBER"])
        {
            NSDictionary *dict = resultDict[@"data"];
            if (dict && [dict isKindOfClass:[NSDictionary class]] && [dict objectForKey:@"groupInfo"] && [[dict objectForKey:@"groupInfo"] isKindOfClass:[NSDictionary class]])
            {
                NSDictionary *groupInfoDic = [dict objectForKey:@"groupInfo"];
                QIYIGroupModel *group = [[QIYIGroupModel alloc] init];
                NSString *jid = [NSString stringWithFormat:@"%@",groupInfoDic[@"gid"]];
                group.jid = jid;
                group.type = groupInfoDic[@"type"];
                group.memberNumber = @0;
                group.Name = groupInfoDic[@"name"];
                group.iconUrl = groupInfoDic[@"icon"];
                group.groupFlag = [groupInfoDic[@"groupFlag"] intValue];
                group.jianPin = groupInfoDic[@"jianPin"];
                group.quanPin = groupInfoDic[@"quanPin"];
                group.defaultName = groupInfoDic[@"defaultName"];
                group.mailAddress = groupInfoDic[@"mailAddress"];
                
                [[QIYISQLManager sharedSQLManager] kickGroupWithGroupModel:group finishBlock:^(QIYIGroupModel *group){
                    finishBlock(group, nil);
                }];
            }
            else
            {
                [[QIYISQLManager sharedSQLManager] kickGroupWithGroupID:jid finishBlock:^(QIYIGroupModel *group){
                    finishBlock(group, nil);
                }];
            }
            
        }
        else if ([resultDict[@"code"] isEqualToString:@"A00002"])
        {            
            NSString *notifyObject = [NSString stringWithFormat:@"%@ %@ /account/v2/public/group/info,parameters:%@ \n result:%@",THIS_FILE,THIS_METHOD,@{@"authcookie":authCookie,@"gid":jid},resultDict];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"settingViewControllerClickQuiteButton" object:notifyObject];
        }

        
        NSError *error = [NSError errorWithDomain:@"网络拉取更新数据失败啊" code:-1 userInfo:nil];
        finishBlock(nil,error);
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        finishBlock(nil, error);
    }];
}

- (void)uploadPinBackWithExtra:(NSString *)extra
{
    //统计点击扫码
    iPhoneXMPPAppDelegate *delegate = (iPhoneXMPPAppDelegate *)[UIApplication sharedApplication].delegate;
    
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [dic setObject:@"scan" forKey:@"p"];
    
    if ([self.from isEqualToString:@"Me"] || [self.from isEqualToString:@"me_web"])
    {
        [dic setObject:@"me" forKey:@"m"];
    }
    else if ([self.from isEqualToString:@"Msg"])
    {
        [dic setObject:@"msg" forKey:@"m"];
    }
    else if ([self.from isEqualToString:@"Discover"])
    {
        [dic setObject:@"discover" forKey:@"m"];
    }
    else if ([self.from isEqualToString:@"Me_Group"])
    {
        [dic setObject:@"me" forKey:@"m"];
    }
    else if ([self.from isEqualToString:@"public_menu"])
    {
        [dic setObject:self.publicJid?:@"" forKey:@"m"];
    }
    else
    {
        [dic setObject:@"discover" forKey:@"m"];
    }
    
    [dic setObject:extra forKey:@"extra"];
    [delegate pingbackWithParams:dic];
}

- (void)uploadPinBackForARWithData1:(NSString *)data1 andData2:(NSString *)data2
{
    //统计点击扫码
    iPhoneXMPPAppDelegate *delegate = (iPhoneXMPPAppDelegate *)[UIApplication sharedApplication].delegate;
    
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [dic setObject:@"ar" forKey:@"p"];
    
    if ([self.from isEqualToString:@"Me"] || [self.from isEqualToString:@"me_web"])
    {
        [dic setObject:@"" forKey:@"m"];
    }
    else if ([self.from isEqualToString:@"Msg"])
    {
        [dic setObject:@"msg" forKey:@"m"];
    }
    else if ([self.from isEqualToString:@"Discover"])
    {
        [dic setObject:@"discover" forKey:@"m"];
    }
    else if ([self.from isEqualToString:@"Me_Group"])
    {
        [dic setObject:@"" forKey:@"m"];
    }
    else if ([self.from isEqualToString:@"public_menu"])
    {
        [dic setObject:@"" forKey:@"m"];
    }
    else if ([self.from isEqualToString:@"H5"])
    {
        [dic setObject:@"H5" forKey:@"m"];
    }
    else
    {
        [dic setObject:@"" forKey:@"m"];
    }
    
    [dic setObject:data1 forKey:@"data1"];
    [dic setObject:data2 forKey:@"data2"];
    [delegate pingbackWithParams:dic];
}

- (void)backAction
{
    NSString *classString = nil;
    if ([self.from isEqualToString:@"Me"])
    {
       classString = @"QIYIMyCodeViewController";
    }
    else if ([self.from isEqualToString:@"Msg"])
    {
        classString = @"ChatSessionController";
    }
    else if ([self.from isEqualToString:@"Discover"])
    {
       classString = @"QIYIDiscoverViewController";
    }
    else if ([self.from isEqualToString:@"Me_Group"])
    {
        classString = @"QIYIGroupQRCodeViewController";
    }
    
    if (classString && classString.length > 0)
    {
        UIViewController *temVC = nil;
        for(UIViewController *vc in self.navigationController.viewControllers)
        {
            if ([vc isKindOfClass:NSClassFromString(classString)])
            {
                temVC = vc;
                break;
            }
        }
        
        if (temVC)
        {
            [self.navigationController popToViewController:temVC animated:YES];
        }
        else
        {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
    else
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - 收到视频聊天通知处理
- (void)sacnQRCodeReceivedPresentVideoCallNotify
{
    if (self.scanType == QIYIScanQRCodeType_AR)
    {
        return;
    }
    
    if (self.imagePickerController)
    {
        [self.imagePickerController dismissViewControllerAnimated:NO completion:^{
            
        }];
    }
    
    [self getTorchStatus];
    if (self.lightState)
    {
        [self systemLightSwitch:NO];
    }
    
    NSMutableArray *array = [NSMutableArray arrayWithArray:[[self.navigationController viewControllers] mutableCopy]];
    NSMutableArray *temArray = [NSMutableArray array];
    for (NSInteger i = 0; i < array.count; i++)
    {
        UIViewController *vc = array[i];
        if ([vc isKindOfClass:[QIYIScanQRCodeViewController class]])
        {
            break;
        }
        else
        {
            [temArray addObject:vc];
        }
    }
    
    if (temArray.count > 0)
    {
        [self.navigationController setViewControllers:temArray animated:YES];
    }
}

//传入短边的尺寸和大约中点
- (UIBezierPath *)drawHeartWithMinLength:(CGFloat)minLength center:(CGPoint)center
{
    NSInteger angle = M_PI*3/4;
    
    //只取最小边的尺寸当成需要绘制的尺寸
    if (angle == M_PI*2/3)
    {
        //120度
        CGFloat drawingPadding = 50.0;
        //❤️上面的圆的半径 宽度减去两边空隙除以3，即可画出三分之一圆；三角函数计算获得
        CGFloat curveRadius = floor((minLength - 2*drawingPadding) / 3.0);
        
        //创建路径
        UIBezierPath *heartPath = [UIBezierPath bezierPath];
        
        //以💖的底部顶点为基点 顺时针画：弧度-半圆-半圆-弧度连接基点
        //1.移动到💖的底部顶点
        CGPoint bottomLocation = CGPointMake(center.x,center.y+2.0*curveRadius);
        [heartPath moveToPoint:bottomLocation];
        
        //2.画左边的弧形 贝赛尔曲线
        CGPoint endPintLeftCurve = CGPointMake(drawingPadding, center.y);
        [heartPath addQuadCurveToPoint:endPintLeftCurve controlPoint:CGPointMake(endPintLeftCurve.x, endPintLeftCurve.y + curveRadius)];
        
        //3.画左边的三分之一圆
        [heartPath addArcWithCenter:CGPointMake(endPintLeftCurve.x + curveRadius, endPintLeftCurve.y) radius:curveRadius startAngle:-M_PI endAngle:-M_PI/3 clockwise:YES];
        
        //4.画右边的三分之一圆
        CGPoint topRightCurveCenter = CGPointMake(endPintLeftCurve.x + 2*curveRadius, endPintLeftCurve.y);
        [heartPath addArcWithCenter:topRightCurveCenter radius:curveRadius startAngle:-M_PI*2/3 endAngle:0 clockwise:YES];
        
        //5.画右边的弧形 贝塞尔曲线
        CGPoint rightControlPoint = CGPointMake(minLength-drawingPadding, endPintLeftCurve.y + curveRadius);
        [heartPath addQuadCurveToPoint:bottomLocation controlPoint:rightControlPoint];
        
        return heartPath;
    }
    else
    {
        //135度
        //边距
        CGFloat drawingPadding = 50.0;
        //❤️上面的圆的半径 宽度减去两边空隙除以3，即可画出三分之一圆；三角函数计算获得
        CGFloat curveRadius = floor((minLength - 2*drawingPadding)/(2+sqrt(2)));
        
        //创建路径
        UIBezierPath *heartPath = [UIBezierPath bezierPath];
        
        //以💖的底部顶点为基点 顺时针画：弧度-半圆-半圆-弧度连接基点
        //1.移动到💖的底部顶点
        CGPoint bottomLocation = CGPointMake(center.x,center.y+2.0*curveRadius);
        [heartPath moveToPoint:bottomLocation];
        
        //2.画左边的弧形 贝赛尔曲线
        CGPoint endPintLeftCurve = CGPointMake(drawingPadding, center.y);
        [heartPath addQuadCurveToPoint:endPintLeftCurve controlPoint:CGPointMake(endPintLeftCurve.x, endPintLeftCurve.y + curveRadius)];
        
        //3.画左边的三分之一圆
        [heartPath addArcWithCenter:CGPointMake(endPintLeftCurve.x + curveRadius, endPintLeftCurve.y) radius:curveRadius startAngle:-M_PI endAngle:-M_PI/4 clockwise:YES];
        
        //4.画右边的三分之一圆
        CGPoint topRightCurveCenter = CGPointMake(endPintLeftCurve.x + (1+sqrt(2))*curveRadius, endPintLeftCurve.y);
        [heartPath addArcWithCenter:topRightCurveCenter radius:curveRadius startAngle:-M_PI*3/4 endAngle:0 clockwise:YES];
        
        //5.画右边的弧形 贝塞尔曲线
        CGPoint rightControlPoint = CGPointMake(minLength-drawingPadding, endPintLeftCurve.y + curveRadius);
        [heartPath addQuadCurveToPoint:bottomLocation controlPoint:rightControlPoint];
        
        return heartPath;
    }
}


@end
