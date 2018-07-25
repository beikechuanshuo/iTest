//
//  HAuthorizationCenter.h
//  reliao
//
//  Created by liyanjun on 2017/5/3.
//
//

#import <Foundation/Foundation.h>

#define CaptureAlertTag 10000
#define AlbumAlertTag 10001
#define AudioAlertTag 10002
#define LocationAlertTag 10003
#define NotificationAlertTag 10004

@interface HAuthorizationCenter : NSObject

//相机权限通常逻辑处理
+ (BOOL)systemCaptureAuthorization;

//相册权限通常逻辑处理
+ (BOOL)systemAlbumAuthorization;

//麦克风权限
+ (BOOL)systemAudioAuthorization;

//位置权限
+ (BOOL)systemLocationAuthorization;

//系统通知权限
+ (BOOL)systemNotificationAuthorization;

//跳转到系统设置的相关页面
+ (void)gotoSelfSettingWithTag:(NSInteger)tag;

@end
