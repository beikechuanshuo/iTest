//
//  HHUDViewController.m
//  reliao
//
//  Created by liyanjun on 16/8/29.
//
//

#import "HHUDViewController.h"
#import "UIColor+Extension.h"

#define kHUD_Width 120
#define kHUD_icon_width 50
#define kHUD_icon_y 50

#define kHUD_Txt_Height 40

#define kHUD_image_width 50

#define kTxtMaxWidth 280

#define AlertMaxWidth 250

#define TitleFontSize 17
#define MessageFontSize 14

#define MessageSpaceLeft_Right 10
#define BottomViewHeight 45
#define kAutoDismissDisplay 1.0

@interface HHUDViewController ()

typedef void(^FinishBlock)(NSInteger index);

@property (nonatomic, strong) UIView *containerView;

@property (nonatomic, strong) UIView *iconView;

//子控件
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *titleView;
@property (nonatomic, strong) UILabel *messageView;

//子控件
@property (nonatomic, strong) UIView *bottomContainerView;
@property (nonatomic, strong) UIButton *leftBtn;
@property (nonatomic, strong) UIButton *rightBtn;

@property (nonatomic, copy) FinishBlock finishBlock;
@property (nonatomic, strong) UIActivityIndicatorView *loadingView;

@property (nonatomic, strong) UIView *hudView;


@end

@implementation HHUDViewController

+ (instancetype)sharedInstance
{
    static HHUDViewController *sharedVC = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedVC = [[HHUDViewController alloc] init];
    });
    return sharedVC;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initUI];
}


- (void)initUI
{
    self.hudView = [[UIView alloc] initWithFrame:CGRectZero];
    self.hudView.backgroundColor = [UIColor clearColor];
    
    self.containerView = [[UIView alloc] initWithFrame:CGRectZero];
    self.containerView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
    self.containerView.layer.cornerRadius = 5;
    self.containerView.layer.masksToBounds = YES;
    [self.hudView addSubview:self.containerView];

    
    self.titleView = [[UILabel alloc] initWithFrame:CGRectZero];
    self.titleView.backgroundColor = [UIColor clearColor];
    self.titleView.center = self.containerView.center;
    self.titleView.textAlignment = NSTextAlignmentCenter;
    self.titleView.font = [UIFont systemFontOfSize:TitleFontSize];
    self.titleView.textColor = [UIColor whiteColor];
    self.titleView.numberOfLines = 1;
    self.titleView.adjustsFontSizeToFitWidth = YES;
    [self.containerView addSubview:self.titleView];
    
    self.iconView = [[UIView alloc] initWithFrame:CGRectZero];
    self.iconView.backgroundColor = [UIColor clearColor];
//    self.iconView.contentMode = UIViewContentModeScaleAspectFill;
    [self.containerView addSubview:self.iconView];

    
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    self.imageView.center = self.iconView.center;
    self.imageView.backgroundColor = [UIColor clearColor];
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.iconView addSubview:self.imageView];
    
    self.loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [self.iconView addSubview:self.loadingView];
    
    self.messageView = [[UILabel alloc] initWithFrame:CGRectZero];
    self.messageView.center = self.containerView.center;
    self.messageView.backgroundColor = [UIColor clearColor];
    self.messageView.textAlignment = NSTextAlignmentCenter;
    self.messageView.font = [UIFont systemFontOfSize:MessageFontSize];
    self.messageView.numberOfLines = 0;
    self.messageView.textColor = [UIColor whiteColor];
    self.messageView.lineBreakMode = NSLineBreakByCharWrapping;
    [self.containerView addSubview:self.messageView];
    
    self.bottomContainerView = [[UIView alloc] initWithFrame:CGRectZero];
    self.bottomContainerView.backgroundColor = [[UIColor colorWithHex:0x09141f] colorWithAlphaComponent:0.13];
    [self.containerView addSubview:self.bottomContainerView];
    
    self.leftBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.leftBtn.backgroundColor = [UIColor clearColor];
    self.leftBtn.tag = 1000;
    [self.leftBtn addTarget:self action:@selector(tapBtn:withIndex:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomContainerView addSubview:self.leftBtn];
    
    self.rightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.rightBtn.backgroundColor = [UIColor clearColor];
    self.rightBtn.tag = 1001;
    [self.rightBtn addTarget:self action:@selector(tapBtn:withIndex:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomContainerView addSubview:self.rightBtn];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
}

- (void)setDisabled:(BOOL)disabled
{
    _disabled = disabled;
    
    if (_disabled)
    {
        [UIApplication sharedApplication].keyWindow.userInteractionEnabled = NO;
    }
    else
    {
         [UIApplication sharedApplication].keyWindow.userInteractionEnabled = YES;;
    }
}

- (void)showViewWithTitle:(NSString *)title message:(NSString *)message image:(UIImage *)image btnTitle:(NSArray *)array hasMask:(BOOL)hasMask andHUDType:(HHUDType)type finishBlock:(void(^)(NSInteger index))finishBlock
{
    //可调用viewDidLoad
    self.view.backgroundColor = [UIColor clearColor];
    
    if (finishBlock)
    {
        self.finishBlock = finishBlock;
    }
    else
    {
        self.finishBlock = nil;
    }
    
    if(type == HHUDTypeLoading)
    {
        self.messageView.textColor = [UIColor whiteColor];
        
        if (self.hudView.superview == nil)
        {
            UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
            
            UIView *guidview = nil;
            
            for (UIView *view in keyWindow.subviews)
            {
                if ([view isKindOfClass:NSClassFromString(@"HGuideView")])
                {
                    guidview = view;
                }
            }
            
            if (guidview)
            {
                [keyWindow insertSubview:self.hudView belowSubview:guidview];
            }
            else
            {
                [keyWindow addSubview:self.hudView];
            }
        }
        
        self.containerView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
        self.imageView.hidden = YES;
        self.iconView.backgroundColor = [UIColor clearColor];
        self.iconView.frame = CGRectMake((kHUD_Width - kHUD_icon_width)/2, 25, kHUD_icon_width, kHUD_icon_width);
        self.loadingView.frame = CGRectMake(0, 0, kHUD_icon_width, kHUD_icon_width);
        self.loadingView.center = CGPointMake(kHUD_icon_width/2, kHUD_icon_width/2);

        [self.loadingView startAnimating];
        self.loadingView.hidden = NO;
        
        //设置message
        if (message && message.length > 0)
        {
            self.messageView.frame = CGRectMake(MessageSpaceLeft_Right, CGRectGetMaxY(self.iconView.frame)+10, kHUD_Width-MessageSpaceLeft_Right*2, 20);
            self.messageView.text = message;
        }
        else
        {
            self.messageView.frame = CGRectMake(MessageSpaceLeft_Right, CGRectGetMaxY(self.iconView.frame)+10, kHUD_Width-MessageSpaceLeft_Right*2, 0);
            self.messageView.text = nil;
        }
        
        //loading的最大宽度设置成120
        self.containerView.frame = CGRectMake(0, 0, kHUD_Width, kHUD_Width);
        self.hudView.frame = self.containerView.bounds;
        self.hudView.center = [UIApplication sharedApplication].keyWindow.center;
    }
    else if (type == HHUDTypeSuccess || type == HHUDTypeError || type == HHUDTypeCustomImg)
    {
        
        if (self.hudView.superview == nil)
        {
            UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
            [keyWindow addSubview:self.hudView];
        }

        self.loadingView.hidden = YES;

        CGSize size = [message boundingRectWithSize:CGSizeMake(kHUD_Width - MessageSpaceLeft_Right*2, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:MessageFontSize]} context:nil].size;
        
        CGFloat tipsWidth = 0;
        
        if (size.height > 20)
        {
            //说明多余一行，则使用最大的宽度
            tipsWidth = kHUD_Width;
        }
        else
        {
            //只有一行
            tipsWidth = size.width+MessageSpaceLeft_Right*2 < kHUD_Width ? kHUD_Width : size.width + MessageSpaceLeft_Right*2;
        }
        
        self.iconView.frame = CGRectMake((kHUD_Width - kHUD_icon_width)/2, 25, kHUD_icon_width, kHUD_icon_width);

        //设置image
        CGFloat offset = 10;
        if (image)
        {
            self.imageView.frame = CGRectMake((tipsWidth - kHUD_icon_width)/2, 0, kHUD_icon_width, kHUD_icon_width);
            
            self.imageView.center = CGPointMake(kHUD_icon_width/2, kHUD_icon_width/2);
            self.imageView.image = image;
        }
        else
        {
            offset = 0;
            self.imageView.frame = CGRectMake((tipsWidth - kHUD_icon_width)/2, 0, kHUD_icon_width, 0);
            self.imageView.center = self.iconView.center;

            self.imageView.image = nil;
            self.containerView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
            
        }
        
        self.imageView.hidden = NO;
        
        //设置message
        if (message && message.length > 0)
        {
            self.messageView.frame = CGRectMake(MessageSpaceLeft_Right, CGRectGetMaxY(self.iconView.frame) + offset, tipsWidth-MessageSpaceLeft_Right*2, 20);
            self.messageView.text = message;
        }
        else
        {
            self.messageView.frame = CGRectMake(MessageSpaceLeft_Right, CGRectGetMaxY(self.iconView.frame) + offset, tipsWidth-MessageSpaceLeft_Right*2, 0);
            self.messageView.text = nil;
        }
        
        self.containerView.frame = CGRectMake(0, 0, kHUD_Width, kHUD_Width);

        self.hudView.frame = self.containerView.bounds;
        self.hudView.center = [UIApplication sharedApplication].keyWindow.center;
        

    }
    else if (type == HHUDTypeText)
    {
        if (self.hudView.superview == nil)
        {
            UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
            [keyWindow addSubview:self.hudView];
        }

        self.loadingView.hidden = YES;
        
        CGSize size = [message boundingRectWithSize:CGSizeMake(kTxtMaxWidth - MessageSpaceLeft_Right*2, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:MessageFontSize]} context:nil].size;
        
        CGFloat tipsWidth = 0;
        
        if (size.height > 20)
        {
            //说明多余一行，则使用最大的宽度
            tipsWidth = kTxtMaxWidth;
        }
        else
        {
            //只有一行
            tipsWidth = size.width+MessageSpaceLeft_Right*2 < kHUD_Width ? kHUD_Width : size.width + MessageSpaceLeft_Right*2;
        }
        
        self.iconView.frame = CGRectMake(0, 0, 0, 0);
        
        //设置image
        CGFloat offset = 10;
        if (image)
        {
            self.imageView.frame = CGRectMake((tipsWidth - kHUD_icon_width)/2, 0, kHUD_icon_width, kHUD_icon_width);
            
            self.imageView.center = CGPointMake(kHUD_icon_width/2, kHUD_icon_width/2);
            self.imageView.image = image;
        }
        else
        {
            offset = 0;
            self.imageView.frame = CGRectMake((tipsWidth - kHUD_icon_width)/2, 0, kHUD_icon_width, 0);
            self.imageView.center = self.iconView.center;
            
            self.imageView.image = nil;
            self.containerView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
        }
        
        self.imageView.hidden = NO;
        
        //设置message
        if (message && message.length > 0)
        {
            self.messageView.frame = CGRectMake(MessageSpaceLeft_Right, 10, tipsWidth-MessageSpaceLeft_Right*2, 20);
            self.messageView.text = message;
        }
        else
        {
            self.messageView.frame = CGRectMake(MessageSpaceLeft_Right, CGRectGetMaxY(self.iconView.frame) + offset, tipsWidth-MessageSpaceLeft_Right*2, 0);
            self.messageView.text = nil;
        }
        
        self.containerView.frame = CGRectMake(0, 0, tipsWidth, kHUD_Txt_Height);
        
        self.hudView.frame = self.containerView.bounds;
        self.hudView.center = [UIApplication sharedApplication].keyWindow.center;

    }
    else if (type == HHUDTypeAlert)
    {
        
        self.titleView.textColor = [UIColor colorWithHex:0x000000];
        self.titleView.font = [UIFont boldSystemFontOfSize:17];
        self.messageView.textColor = [UIColor colorWithHex:0x000000];
        self.messageView.font = [UIFont systemFontOfSize:13];
        self.containerView.backgroundColor = [[UIColor colorWithHex:0xF3F3F3] colorWithAlphaComponent:0.96];
        self.containerView.layer.cornerRadius = 14;
        self.containerView.layer.masksToBounds = YES;
        
        //设置title
        if (title && title.length > 0)
        {
            self.titleView.frame = CGRectMake(0, 18, AlertMaxWidth, 20);
            self.titleView.text = title;
        }
        else
        {
            self.titleView.frame = CGRectMake(0, 0, AlertMaxWidth, 0);
            self.titleView.text = nil;
        }
        
        //设置image
        if (image)
        {
            self.imageView.frame = CGRectMake((AlertMaxWidth - kHUD_icon_width)/2, CGRectGetMaxY(self.titleView.frame), kHUD_icon_width, kHUD_icon_width);
            self.imageView.image = image;
        }
        else
        {
            self.imageView.frame = CGRectMake((AlertMaxWidth - kHUD_icon_width)/2, CGRectGetMaxY(self.titleView.frame), kHUD_icon_width, 0);
            self.imageView.image = nil;
        }
        
        self.imageView.hidden = NO;
        self.loadingView.frame = CGRectMake((kHUD_Width - kHUD_icon_width)/2, CGRectGetMaxY(self.titleView.frame), kHUD_icon_width, 0);
        [self.loadingView startAnimating];
        self.loadingView.hidden = YES;
        
        //设置message
        if (message && message.length > 0)
        {
            self.messageView.textAlignment = NSTextAlignmentCenter;
            
            CGSize size = [message boundingRectWithSize:CGSizeMake(AlertMaxWidth-MessageSpaceLeft_Right*2, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:MessageFontSize]} context:nil].size;
            if (size.height > 20)
            {
                //多余一行
                self.messageView.frame = CGRectMake(MessageSpaceLeft_Right, CGRectGetMaxY(self.imageView.frame)+5, AlertMaxWidth-MessageSpaceLeft_Right*2, size.height+5);
            }
            else
            {
                self.messageView.frame = CGRectMake(MessageSpaceLeft_Right, CGRectGetMaxY(self.imageView.frame)+5, AlertMaxWidth-MessageSpaceLeft_Right*2, size.height+5);
            }
            
            self.messageView.text = message;
        }
        else
        {
            self.messageView.frame = CGRectMake(MessageSpaceLeft_Right, CGRectGetMaxY(self.imageView.frame)+5, AlertMaxWidth-MessageSpaceLeft_Right*2, 0);
            self.messageView.text = nil;
        }
        
        //设置按钮
        if (array && array.count > 0)
        {
            self.bottomContainerView.frame = CGRectMake(0, CGRectGetMaxY(self.messageView.frame)+10, AlertMaxWidth, BottomViewHeight);
            
            if (array.count == 1)
            {
                //一个按钮
                self.leftBtn.frame = CGRectMake(0, 0.5, AlertMaxWidth, BottomViewHeight-0.5);
                [self.leftBtn setTitle:[array objectAtIndex:0] forState:UIControlStateNormal];
                self.leftBtn.titleLabel.font = [UIFont boldSystemFontOfSize:17];
                [self.leftBtn setTitleColor:[UIColor colorWithHex:0x007AFF] forState:UIControlStateNormal];
                
            }
            else if (array.count == 2)
            {
                //两个按钮
                self.leftBtn.frame = CGRectMake(0, 0.5, AlertMaxWidth/2, BottomViewHeight-0.5);
                [self.leftBtn setTitle:[array objectAtIndex:0] forState:UIControlStateNormal];
                
                self.rightBtn.frame = CGRectMake(CGRectGetMaxX(self.leftBtn.frame)+0.5, 0.5, AlertMaxWidth/2-0.5, BottomViewHeight-0.5);
                [self.rightBtn setTitle:[array objectAtIndex:1] forState:UIControlStateNormal];
                
                self.leftBtn.titleLabel.font = [UIFont boldSystemFontOfSize:17];
                [self.leftBtn setTitleColor:[UIColor colorWithHex:0x007AFF] forState:UIControlStateNormal];
                
                self.rightBtn.titleLabel.font = [UIFont systemFontOfSize:17];
                [self.rightBtn setTitleColor:[UIColor colorWithHex:0x007AFF] forState:UIControlStateNormal];
                
            }
            else
            {
                
            }
        }
        else
        {
            self.bottomContainerView.frame = CGRectMake(0, CGRectGetMaxY(self.messageView.frame), AlertMaxWidth, 0);
            self.leftBtn.frame = CGRectMake(0, 0.5, 0, 0);
            [self.leftBtn setTitle:nil forState:UIControlStateNormal];
            
            self.leftBtn.frame = CGRectMake(0, 0.5, 0, 0);
            [self.rightBtn setTitle:nil forState:UIControlStateNormal];
        }
        
        self.containerView.backgroundColor = [UIColor whiteColor];
        self.leftBtn.backgroundColor = [UIColor whiteColor];
        self.rightBtn.backgroundColor = [UIColor whiteColor];
        
        //loading的最大宽度设置成150
        self.containerView.frame = CGRectMake(0, 0, AlertMaxWidth, CGRectGetMaxY(self.bottomContainerView.frame));
        self.hudView.frame = self.containerView.bounds;
        self.hudView.center = [UIApplication sharedApplication].keyWindow.center;

    }
    else if (type == HHUDTypeDismiss)
    {
        self.disabled = NO;

        if (self.hudView.superview)
        {
            [self.hudView removeFromSuperview];
        }
        if (self.finishBlock)
        {
            self.finishBlock(0);
        }
    }
    
}

- (void)tapBtn:(UIButton *)button withIndex:(NSInteger)index
{
    if (button.tag == 1000)
    {
        if (self.finishBlock)
        {
            self.finishBlock(0);
        }
    }
    else if(button.tag == 1001)
    {
        if (self.finishBlock)
        {
            self.finishBlock(1);
        }
    }
}

- (void)showViewForWebRtc
{
    [self showTextWithString:@"正在通话中，请稍后再试" delay:2];
}

- (void)showLoadingWithString:(NSString *)string
{
    
    [self showViewWithTitle:@"" message:string image:nil btnTitle:nil hasMask:NO andHUDType:HHUDTypeLoading finishBlock:nil];

}

- (void)dismiss
{
    self.disabled = NO;

    [self showViewWithTitle:@"" message:@"" image:nil btnTitle:nil hasMask:NO andHUDType:HHUDTypeDismiss finishBlock:nil];
}



- (void)dismissWithCompleteBlock:(void (^)(void))completeBlock
{
    self.disabled = NO;
    
    [self showViewWithTitle:@"" message:@"" image:nil btnTitle:nil hasMask:NO andHUDType:HHUDTypeDismiss finishBlock:^(NSInteger index) {
        
        if (completeBlock)
        {
            completeBlock();
        }
    }];
}


- (void)showSuccessWithString:(NSString *)string
{
    [self showViewWithTitle:@"   " message:string image:[UIImage imageNamed:@"Toast_Success"] btnTitle:nil hasMask:NO andHUDType:HHUDTypeSuccess finishBlock:nil];

}

- (void)showErrorWithString:(NSString *)string
{
    [self showViewWithTitle:nil message:string image:[UIImage imageNamed:@"Toast_Fail"] btnTitle:nil hasMask:NO andHUDType:HHUDTypeError finishBlock:nil];
}

- (void)showTextWithString:(NSString *)string;
{
    [self showViewWithTitle:nil message:string image:nil btnTitle:nil hasMask:NO andHUDType:HHUDTypeText finishBlock:nil];
}


- (void)showLoadingDelay1sWithString:(NSString *)string
{
    [self showLoadingWithString:string];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kAutoDismissDisplay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self dismiss];
    });
    
}


- (void)showSuccessDelay1sWithString:(NSString *)string
{
    [self showSuccessWithString:string];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kAutoDismissDisplay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self dismiss];
    });

}
- (void)showErrorDelay1sWithString:(NSString *)string
{
    [self showErrorWithString:string];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kAutoDismissDisplay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self dismiss];
    });


}
- (void)showTextDelay1sWithString:(NSString *)string
{
    [self showTextWithString:string];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kAutoDismissDisplay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self dismiss];
    });

}

- (void)showLoadingWithString:(NSString *)string delay:(CGFloat)delay
{
    [self showLoadingWithString:string];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self dismiss];
    });
}

- (void)showSuccessWithString:(NSString *)string delay:(CGFloat)delay
{
    [self showSuccessWithString:string];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self dismiss];
    });
}
- (void)showErrorWithString:(NSString *)string delay:(CGFloat)delay
{
    [self showErrorWithString:string];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self dismiss];
    });

}
- (void)showTextWithString:(NSString *)string delay:(CGFloat)delay
{
    [self showTextWithString:string];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self dismiss];
    });

}

- (void)showTextWithString:(NSString *)string delay:(CGFloat)delay complete:(void (^)(void))completeBlock
{
    [self showTextWithString:string];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self dismissWithCompleteBlock:^{
            if (completeBlock)
            {
                completeBlock();
            }
            
        }];
    });
}

- (void)showSuccessWithString:(NSString *)string delay:(CGFloat)delay complete:(void (^)(void))completeBlock
{
    [self showSuccessWithString:string];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self dismissWithCompleteBlock:^{
            if (completeBlock)
            {
                completeBlock();
            }
            
        }];
    });

}
- (void)showErrorWithString:(NSString *)string delay:(CGFloat)delay complete:(void (^)(void))completeBlock
{
    [self showErrorWithString:string];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self dismissWithCompleteBlock:^{
            if (completeBlock)
            {
                completeBlock();
            }
            
        }];
    });

}
- (void)showLoadingWithString:(NSString *)string delay:(CGFloat)delay complete:(void (^)(void))completeBlock
{
    [self showLoadingWithString:string];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self dismissWithCompleteBlock:^{
            if (completeBlock)
            {
                completeBlock();
            }
            
        }];
    });
    

}


@end
