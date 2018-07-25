//
//  HHUDViewController.h
//  reliao
//
//  Created by liyanjun on 16/8/29.
//
//

#import <UIKit/UIKit.h>


typedef NS_ENUM(NSInteger, HHUDType)
{
    HHUDTypeLoading,
    HHUDTypeSuccess,
    HHUDTypeError,
    HHUDTypeText,
    HHUDTypeAlert,
    HHUDTypeDismiss,
    HHUDTypeCustomImg,
};

@interface HHUDViewController : UIViewController

//YES禁止下方点击事件，默认NO
@property (nonatomic, assign) BOOL disabled;

+ (instancetype)sharedInstance;

- (void)showViewWithTitle:(NSString *)title message:(NSString *)message image:(UIImage *)image btnTitle:(NSArray *)array hasMask:(BOOL)hasMask andHUDType:(HHUDType)type finishBlock:(void(^)(NSInteger index))finishBlock;

- (void)showViewForWebRtc;

//增加方法，统一
- (void)showSuccessWithString:(NSString *)string;
- (void)showErrorWithString:(NSString *)string;
- (void)showTextWithString:(NSString *)string;


//1s后自动消失，不需要dismiss
- (void)showSuccessDelay1sWithString:(NSString *)string;
- (void)showErrorDelay1sWithString:(NSString *)string;
- (void)showTextDelay1sWithString:(NSString *)string;
- (void)showLoadingDelay1sWithString:(NSString *)string;


- (void)showSuccessWithString:(NSString *)string delay:(CGFloat)delay;
- (void)showErrorWithString:(NSString *)string delay:(CGFloat)delay;
- (void)showTextWithString:(NSString *)string delay:(CGFloat)delay;
- (void)showLoadingWithString:(NSString *)string delay:(CGFloat)delay;

- (void)showSuccessWithString:(NSString *)string delay:(CGFloat)delay complete:(void (^)(void))completeBlock;
- (void)showErrorWithString:(NSString *)string delay:(CGFloat)delay complete:(void (^)(void))completeBlock;
- (void)showTextWithString:(NSString *)string delay:(CGFloat)delay complete:(void (^)(void))completeBlock;
- (void)showLoadingWithString:(NSString *)string delay:(CGFloat)delay complete:(void (^)(void))completeBlock;
- (void)showLoadingWithString:(NSString *)string;

- (void)dismiss;

- (void)dismissWithCompleteBlock:(void(^)(void))completeBlock;


//暂未实现
//- (void)showSuccessWithString:(NSString *)string toView:(UIView *)view;
//
//- (void)showErrorWithString:(NSString *)string toView:(UIView *)view;
//
//- (void)showLoadingWithString:(NSString *)string toView:(UIView *)view;
//
//- (void)showTextWithString:(NSString *)string toView:(UIView *)view;
//

@end
