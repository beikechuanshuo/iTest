//
//  QIYIShowARResultView.m
//  reliao
//
//  Created by liyanjun on 2018/3/28.
//  Copyright © 2018年 iqiyi. All rights reserved.
//

#import "QIYIShowARResultView.h"
#import "QIYIMyUserInfoManager.h"
#import "UIImageView+WebCache.h"
#import "UIImage+Extension.h"

typedef void(^tapBtnBlock)(NSInteger index);

@interface QIYIShowARResultView ()

@property (nonatomic, strong) UIView *containerView;

@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, strong) UILabel *tipsLabel;

@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, strong) UIButton *myPieceBtn;

@property (nonatomic, strong) UIButton *scanARBtn;

@property (nonatomic, copy) tapBtnBlock tapBlock;

@end

@implementation QIYIShowARResultView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setupUI];
    }
    return self;
}

- (void)setupUI
{
    self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
    
    self.containerView = [[UIView alloc] initWithFrame:self.bounds];
    self.containerView.backgroundColor = [UIColor clearColor];
    [self addSubview:self.containerView];
    
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:18];
    
    [self.containerView addSubview:self.titleLabel];
    
    self.tipsLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.tipsLabel.textColor = [UIColor whiteColor];
    self.tipsLabel.textAlignment = NSTextAlignmentCenter;
    self.tipsLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:16];
    [self.containerView addSubview:self.tipsLabel];
    
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.containerView addSubview:self.imageView];
    
    self.myPieceBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.myPieceBtn.frame = CGRectMake(0, 0, 180, 40);
    [self.containerView addSubview:self.myPieceBtn];
    [self.myPieceBtn addTarget:self action:@selector(myPieceClickAction:) forControlEvents:UIControlEventTouchUpInside];
    
    self.scanARBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.scanARBtn.frame = CGRectMake(0, 0, 180, 40);
    [self.containerView addSubview:self.scanARBtn];
    [self.scanARBtn addTarget:self action:@selector(myScanClickAction:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)showARResultVCWithQIYIARScanModel:(QIYIARScanModel *)scanModel tapBtnBlock:(void(^)(NSInteger index))tapBtnBlock
{
    self.tapBlock = tapBtnBlock;
    CGFloat maxHeight = SCREEN_HEIGHT- [HDevice shareInstance].navViewHeight-80;
    if ([[HDevice shareInstance] localizedModel] == HDeviceLocalizedModel_iPhoneX)
    {
        maxHeight = maxHeight-34;
    }
    
    //图片比例固定为270*360
    if (maxHeight > 548+10)
    {
        CGFloat originY = (maxHeight - 548)/2 + [HDevice shareInstance].navViewHeight;
        self.titleLabel.frame = CGRectMake(0, originY, SCREEN_WIDTH, 28);
        self.tipsLabel.frame = CGRectMake(0, CGRectGetMaxY(self.titleLabel.frame), SCREEN_WIDTH, 25);
        if (scanModel == nil || scanModel.result.idx <= 0)
        {
            self.titleLabel.text = @"很遗憾";
            self.tipsLabel.text = @"本次没有抽中任何拼图";
        }
        else
        {
            NSDictionary *userInfo = [QIYIMyUserInfoManager sharedInstance].myUserInfoDict;
            NSString *cnName = [userInfo objectForKey:@"chname"];
            if (cnName != nil && cnName.length > 0)
            {
                self.titleLabel.text = [NSString stringWithFormat:@"恭喜你，%@",cnName];
            }
            else
            {
                self.titleLabel.text = [NSString stringWithFormat:@"恭喜你，%@",[QIYIMyUserInfoManager sharedInstance].myUserName];
            }
            
            NSString *string =  [NSString stringWithFormat:@"你抽中了%@拼图",scanModel.result.name];
            NSMutableAttributedString *AttributedStr = [[NSMutableAttributedString alloc] initWithString:string];
            [AttributedStr addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"Helvetica-Bold" size:16] range:NSMakeRange(0, 4)];
            [AttributedStr addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, 4)];
            
            [AttributedStr addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"Helvetica-Bold" size:18] range:NSMakeRange(4, scanModel.result.name.length)];
            [AttributedStr addAttribute:NSForegroundColorAttributeName value:kThemeColor range:NSMakeRange(4, scanModel.result.name.length)];
            
            NSInteger location = 4+scanModel.result.name.length;
            NSInteger length = string.length - location;
            
            [AttributedStr addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"Helvetica-Bold" size:16] range:NSMakeRange(location, length)];
            [AttributedStr addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(location, length)];
            
            self.tipsLabel.attributedText = AttributedStr;
        }
        
        self.imageView.frame = CGRectMake((SCREEN_WIDTH-270)/2, CGRectGetMaxY(self.tipsLabel.frame)+10, 270, 360);
       
        if (scanModel == nil)
        {
            self.imageView.image = [UIImage imageNamed:@"AR_NoResult"];
        }
        else
        {
            [self.imageView sd_setImageWithURL:[NSURL URLWithString:scanModel.result.img] placeholderImage:nil completed:nil];
        }
        
        self.myPieceBtn.frame = CGRectMake((SCREEN_WIDTH-180)/2, CGRectGetMaxY(self.imageView.frame)+20, 180, 40);
        if (scanModel == nil || scanModel.result.idx <= 0)
        {
            [self.myPieceBtn setImage:[UIImage imageNamed:@"ar_fail_view"] forState:UIControlStateNormal];
            [self.myPieceBtn setImage:[UIImage imageNamed:@"ar_fail_view"] forState:UIControlStateHighlighted];
        }
        else
        {
            [self.myPieceBtn setImage:[UIImage imageNamed:@"ar_succcess_view"] forState:UIControlStateNormal];
            [self.myPieceBtn setImage:[UIImage imageNamed:@"ar_succcess_view"] forState:UIControlStateHighlighted];
        }
        
        self.scanARBtn.frame = CGRectMake((SCREEN_WIDTH-180)/2, CGRectGetMaxY(self.myPieceBtn.frame)+15, 180, 40);
        if (scanModel == nil || scanModel.result.idx <= 0)
        {
            [self.scanARBtn setImage:[UIImage imageNamed:@"ar_fail_scan"] forState:UIControlStateNormal];
            [self.scanARBtn setImage:[UIImage imageNamed:@"ar_fail_scan"] forState:UIControlStateHighlighted];
        }
        else
        {
            [self.scanARBtn setImage:[UIImage imageNamed:@"ar_succcess_scan"] forState:UIControlStateNormal];
            [self.scanARBtn setImage:[UIImage imageNamed:@"ar_succcess_scan"] forState:UIControlStateHighlighted];
        }
    }
    else
    {
        self.titleLabel.frame = CGRectMake(0, [HDevice shareInstance].navViewHeight+5, SCREEN_WIDTH, 28);
        self.tipsLabel.frame = CGRectMake(0, CGRectGetMaxY(self.titleLabel.frame), SCREEN_WIDTH, 25);
        if (scanModel == nil || scanModel.result.idx <= 0)
        {
            self.titleLabel.text = @"很遗憾";
            self.tipsLabel.text = @"本次没有抽中任何拼图";
        }
        else
        {
            NSDictionary *userInfo = [QIYIMyUserInfoManager sharedInstance].myUserInfoDict;
            NSString *cnName = [userInfo objectForKey:@"chname"];
            if (cnName != nil && cnName.length > 0)
            {
                self.titleLabel.text = [NSString stringWithFormat:@"恭喜你，%@",cnName];
            }
            else
            {
                self.titleLabel.text = [NSString stringWithFormat:@"恭喜你，%@",[QIYIMyUserInfoManager sharedInstance].myUserName];
            }
            
            NSString *string =  [NSString stringWithFormat:@"你抽中了%@拼图",scanModel.result.name];
            NSMutableAttributedString *AttributedStr = [[NSMutableAttributedString alloc] initWithString:string];
            [AttributedStr addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"Helvetica-Bold" size:16] range:NSMakeRange(0, 4)];
            [AttributedStr addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, 4)];
            
            [AttributedStr addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"Helvetica-Bold" size:18] range:NSMakeRange(4, scanModel.result.name.length)];
            [AttributedStr addAttribute:NSForegroundColorAttributeName value:kThemeColor range:NSMakeRange(4, scanModel.result.name.length)];
            
            NSInteger location = 4+scanModel.result.name.length;
            NSInteger length = string.length - location;
            
            [AttributedStr addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"Helvetica-Bold" size:16] range:NSMakeRange(location, length)];
            [AttributedStr addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(location, length)];
            
            self.tipsLabel.attributedText = AttributedStr;
        }
        
        CGFloat maxBottomY = SCREEN_HEIGHT-80;
        if ([[HDevice shareInstance] localizedModel] == HDeviceLocalizedModel_iPhoneX)
        {
            maxBottomY = maxBottomY-34;
        }
        
        self.scanARBtn.frame = CGRectMake((SCREEN_WIDTH-180)/2, maxBottomY-5-40, 180, 40);
        if (scanModel == nil || scanModel.result.idx <= 0)
        {
            [self.scanARBtn setImage:[UIImage imageNamed:@"ar_fail_scan"] forState:UIControlStateNormal];
            [self.scanARBtn setImage:[UIImage imageNamed:@"ar_fail_scan"] forState:UIControlStateHighlighted];
        }
        else
        {
            [self.scanARBtn setImage:[UIImage imageNamed:@"ar_succcess_scan"] forState:UIControlStateNormal];
            [self.scanARBtn setImage:[UIImage imageNamed:@"ar_succcess_scan"] forState:UIControlStateHighlighted];
        }
        
        self.myPieceBtn.frame = CGRectMake((SCREEN_WIDTH-180)/2, CGRectGetMinY(self.scanARBtn.frame)-15-40, 180, 40);
        if (scanModel == nil || scanModel.result.idx <= 0)
        {
            [self.myPieceBtn setImage:[UIImage imageNamed:@"ar_fail_view"] forState:UIControlStateNormal];
            [self.myPieceBtn setImage:[UIImage imageNamed:@"ar_fail_view"] forState:UIControlStateHighlighted];
        }
        else
        {
            [self.myPieceBtn setImage:[UIImage imageNamed:@"ar_succcess_view"] forState:UIControlStateNormal];
            [self.myPieceBtn setImage:[UIImage imageNamed:@"ar_succcess_view"] forState:UIControlStateHighlighted];
        }
        
        CGFloat imageHeight = CGRectGetMinY(self.myPieceBtn.frame)-CGRectGetMaxY(self.tipsLabel.frame)-20-10;
        CGFloat imageWidth = imageHeight*0.75;
        
        self.imageView.frame = CGRectMake((SCREEN_WIDTH-imageWidth)/2, CGRectGetMaxY(self.tipsLabel.frame)+10, imageWidth, imageHeight);
        if (scanModel == nil)
        {
            self.imageView.image = [UIImage imageNamed:@"AR_NoResult"];
        }
        else
        {
            [self.imageView sd_setImageWithURL:[NSURL URLWithString:scanModel.result.img] placeholderImage:nil completed:nil];
        }
    }
}

- (void)myPieceClickAction:(id)sender
{
    if (self.tapBlock)
    {
        self.tapBlock(0);
    }
}

- (void)myScanClickAction:(id)sender
{
    if (self.tapBlock)
    {
        self.tapBlock(1);
    }
}


@end
