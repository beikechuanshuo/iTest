//
//  HAuthorizationCenter.m
//  reliao
//
//  Created by liyanjun on 2017/5/3.
//
//

#import "HAuthorizationCenter.h"
#import <CoreLocation/CoreLocation.h>
#import <Photos/Photos.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface HAuthorizationCenter ()

@end

static CLLocationManager * locationManager;

@implementation HAuthorizationCenter

+ (instancetype)sharedAuthorizationCenter
{
    static HAuthorizationCenter *center = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        center = [[HAuthorizationCenter alloc] init];
    });
    
    return center;
}


+ (BOOL)systemCaptureAuthorization
{
    //请求相机权限
    AVAuthorizationStatus status =  [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if(AVAuthorizationStatusNotDetermined == status)
    {
        //未授权时，请求权限
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted)
         {
             
         }];
        
        return NO;
    }
    else if(status == AVAuthorizationStatusRestricted || status == AVAuthorizationStatusDenied)
    {
        //没有相机权限
        HAuthorizationCenter *center = [HAuthorizationCenter sharedAuthorizationCenter];
        
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"" message:@"请在iPhone的“设置-隐私-相机选项中，允许爱奇艺之家访问你的相机”" delegate:center cancelButtonTitle:@"取消" otherButtonTitles:@"设置",nil];
        [av show];
        av.tag = CaptureAlertTag;
        
        return NO;
    }
    else
    {
        //有权限 不做其他处理，继续以后的逻辑
        return YES;
    }
}

+ (BOOL)systemAlbumAuthorization
{
    //请求相册权限
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0)
    {
        PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
        
        if(status == PHAuthorizationStatusNotDetermined)
        {
            //未授权
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                
            }];
            
            return NO;
        }
        else if (status == PHAuthorizationStatusRestricted || status == PHAuthorizationStatusDenied)
        {
            //无权限
            HAuthorizationCenter *center = [HAuthorizationCenter sharedAuthorizationCenter];
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:NSLocalizedString(@"ImagePickerNoAlbumAuthorizationTip", @"") delegate:center cancelButtonTitle:@"取消" otherButtonTitles:@"设置",nil];
            [alertView show];
            alertView.tag = AlbumAlertTag;
            
            return NO;
        }
    }
    else
    {
        ALAuthorizationStatus status = [ALAssetsLibrary authorizationStatus];
        if (status == ALAuthorizationStatusNotDetermined)
        {
            //第一次调用的时候 会弹出权限框
            [[ALAssetsLibrary new] enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                
            } failureBlock:^(NSError *error) {
                
            }];
            return NO;
        }
        else if (status == ALAuthorizationStatusRestricted || status == ALAuthorizationStatusDenied)
        {
            HAuthorizationCenter *center = [HAuthorizationCenter sharedAuthorizationCenter];
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:NSLocalizedString(@"ImagePickerNoAlbumAuthorizationTip", @"") delegate:center cancelButtonTitle:@"取消" otherButtonTitles:@"设置",nil];
            [alertView show];
            alertView.tag = AlbumAlertTag;
            
            return NO;
        }
    }
    
    return YES;
}

+ (BOOL)systemAudioAuthorization
{
    __block BOOL bCanRecord = NO;
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
        
        if (bCanRecord == NO)
        {
            HAuthorizationCenter *center = [HAuthorizationCenter sharedAuthorizationCenter];
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"无麦克风权限，请在iPhone的“设置-隐私-麦克风”选项中，允许爱奇艺之家访问你的手机麦克风" delegate:center cancelButtonTitle:@"取消" otherButtonTitles:@"设置", nil];
            [alert show];
            alert.tag = AudioAlertTag;
            
            return NO;
        }
    }
    
    return bCanRecord;
}

+ (BOOL)systemLocationAuthorization
{
    if (locationManager == nil)
    {
       locationManager = [[CLLocationManager alloc] init];
    }
    
    if(![CLLocationManager locationServicesEnabled])
    {
        HAuthorizationCenter *center = [HAuthorizationCenter sharedAuthorizationCenter];
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"无法获取你的位置信息" message:@"请到手机系统的「设置」->「隐私」->「定位服务」中打开定位服务，并允许爱奇艺之家使用定位服务。" delegate:center cancelButtonTitle:@"取消" otherButtonTitles:@"设置", nil];
        alertView.tag = LocationAlertTag;
        [alertView show];
        
        return NO;
    }
    
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if(status == kCLAuthorizationStatusNotDetermined)
    {
        if ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0)
        {
            [locationManager requestWhenInUseAuthorization];
        }
        
        return NO;
    }
    else if (status == kCLAuthorizationStatusDenied || status == kCLAuthorizationStatusRestricted)
    {
        HAuthorizationCenter *center = [HAuthorizationCenter sharedAuthorizationCenter];
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"无法获取你的位置信息" message:@"请到手机系统的「设置」->「隐私」->「定位服务」中打开定位服务，并允许爱奇艺之家使用定位服务。" delegate:center cancelButtonTitle:@"取消" otherButtonTitles:@"设置", nil];
        alertView.tag = LocationAlertTag;
        [alertView show];
        
        return NO;
    }
    else
    {
        [locationManager startUpdatingLocation];
        return YES;
    }
}

//系统通知权限
+ (BOOL)systemNotificationAuthorization
{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
    {
        UIUserNotificationType userType =  [[UIApplication sharedApplication] currentUserNotificationSettings].types;
        
        //总通知没打开
        if (userType == UIUserNotificationTypeNone)
        {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"接收新消息通知已关闭，无法及时收到消息通知。请在「系统」-「通知」中找到「爱奇艺之家」，打开「允许通知」。" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"设置", nil];
            alertView.tag = NotificationAlertTag;
            [alertView show];
            
            return NO;
        }
    }
    
    return YES;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
    {
         [HAuthorizationCenter gotoSelfSettingWithTag:alertView.tag];
    }
}

+ (void)gotoSelfSettingWithTag:(NSInteger)tag
{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
    {
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        
        if ([[UIApplication sharedApplication] canOpenURL:url])
        {
            
            [[UIApplication sharedApplication] openURL:url];
        }
    }
    else
    {
        if (tag == CaptureAlertTag)
        {
            NSURL *url = [NSURL URLWithString:@"prefs:root=Privacy&path=CAMERA"];
            
            if ([[UIApplication sharedApplication] canOpenURL:url])
            {
                
                [[UIApplication sharedApplication] openURL:url];
                
            }
            return;
        }
        else if (tag == AlbumAlertTag)
        {
            NSURL *url = [NSURL URLWithString:@"prefs:root=Privacy&path=PHOTOS"];
            
            if ([[UIApplication sharedApplication] canOpenURL:url])
            {
                
                [[UIApplication sharedApplication] openURL:url];
                
            }
            return;
        }
        else if (tag == AudioAlertTag)
        {
            NSURL *url = [NSURL URLWithString:@"prefs:root=Privacy&path=MICROPHONE"];
            
            if ([[UIApplication sharedApplication] canOpenURL:url])
            {
                
                [[UIApplication sharedApplication] openURL:url];
                
            }
            return;
        }
        else if (tag == LocationAlertTag)
        {
            NSURL *url = [NSURL URLWithString:@"prefs:root=LOCATION_SERVICES"];
            
            if ([[UIApplication sharedApplication] canOpenURL:url])
            {
                
                [[UIApplication sharedApplication] openURL:url];
                
            }
            return;
        }
        else if (tag == NotificationAlertTag)
        {
            NSURL *url = [NSURL URLWithString:@"prefs:root=NOTIFICATIONS_ID&path=com.iH.reliao"];
            
            if ([[UIApplication sharedApplication] canOpenURL:url])
            {
                
                [[UIApplication sharedApplication] openURL:url];
                
            }
        }
    }
}

@end
