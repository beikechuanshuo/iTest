//
//  QIYIScanQRCodeViewController.h
//  reliao
//
//  Created by liyanjun on 16/8/26.
//
//

#import <UIKit/UIKit.h>

typedef void(^QiyiScanQRSuccessBlock)(NSString *result);

typedef NS_ENUM(NSInteger, QIYIScanQRCodeType)
{
    QIYIScanQRCodeType_Normal,
    QIYIScanQRCodeType_AR,
};

//扫描二维码VC
@interface QIYIScanQRCodeViewController : UIViewController

@property (nonatomic, copy)NSString *backTitle;

@property (nonatomic, copy)NSString *roomJid;

@property (nonatomic, copy)NSString *from;

@property (nonatomic, copy)NSString *publicJid;

@property (nonatomic, copy)QiyiScanQRSuccessBlock scanQRSuccessBlock;

@property (nonatomic, assign) QIYIScanQRCodeType scanType;

+ (instancetype)sharedScanQRCodeInstance;

- (void)changeToScanType:(QIYIScanQRCodeType)scanType;

@end
