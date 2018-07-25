//
//  HDevice.m
//  Test
//
//  Created by liyanjun on 15/12/14.
//  Copyright © 2015年 liyanjun. All rights reserved.
//

#import "HDevice.h"
#import <sys/sysctl.h>
#include <sys/socket.h>
#include <net/if.h>
#include <net/if_dl.h>
#import <objc/runtime.h>
#import <AdSupport/ASIdentifierManager.h>
#if __has_include(<SFHFKeychainUtils.h>)
#import "SFHFKeychainUtils.h"


#endif


@interface HDevice ()

@end

@implementation HDevice

+ (instancetype)shareInstance
{
    static HDevice *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HDevice alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        unsigned int count = 0;
        Method *methods = class_copyMethodList([HDevice class], &count);
        for (int i = 0; i < count; i++)
        {
            Method method = methods[i];
            SEL selector = method_getName(method);
            NSString *name = NSStringFromSelector(selector);
            if ([name hasPrefix:@"init_"])
            {
                do {
                _Pragma("clang diagnostic push")
                _Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"")
                [self performSelector:selector];
                _Pragma("clang diagnostic pop")
                } while (0);
            }
        }
    }
    return self;
}

- (void)dealloc
{
    unsigned int count = 0;
    Method *methods = class_copyMethodList([HDevice class], &count);
    for (int i = 0; i < count; i++)
    {
        Method method = methods[i];
        SEL selector = method_getName(method);
        NSString *name = NSStringFromSelector(selector);
        if ([name hasPrefix:@"dealloc_"])
        {
            do {
                _Pragma("clang diagnostic push")
                _Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"")
                [self performSelector:selector];
                _Pragma("clang diagnostic pop")
            } while (0);
        }
    }
    free(methods);
}

- (HDeviceModel)model
{
    static HDeviceModel temModel = HDeviceModel_other;
    static dispatch_once_t onceToken;
    __weak __typeof(self) weakSelf = self;
    dispatch_once(&onceToken, ^{
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        HDeviceLocalizedModel type = strongSelf.localizedModel;
        switch (type) {
            case HDeviceLocalizedModel_iPhone1:
            case HDeviceLocalizedModel_iPhone3G:
            case HDeviceLocalizedModel_iPhone3GS:
            case HDeviceLocalizedModel_iPhone4:
            case HDeviceLocalizedModel_iPhone4S:
            case HDeviceLocalizedModel_iPhone5:
            case HDeviceLocalizedModel_iPhone5S:
            case HDeviceLocalizedModel_iPhone5C:
            case HDeviceLocalizedModel_iPhone6:
            case HDeviceLocalizedModel_iPhone6P:
            case HDeviceLocalizedModel_iPhone6S:
            case HDeviceLocalizedModel_iPhone6SP:
            case HDeviceLocalizedModel_iPhoneSE:
            case HDeviceLocalizedModel_iPhone7:
            case HDeviceLocalizedModel_iPhone7P:
            case HDeviceLocalizedModel_iPhone8:
            case HDeviceLocalizedModel_iPhone8P:
            case HDeviceLocalizedModel_iPhoneX:
            {
                temModel = HDeviceModel_iPhone;
                return ;
            }

            case HDeviceLocalizedModel_iPad1:
            case HDeviceLocalizedModel_iPad2:
            case HDeviceLocalizedModel_iPad3:
            case HDeviceLocalizedModel_iPad4:
            case HDeviceLocalizedModel_iPadAir:
            case HDeviceLocalizedModel_iPadAir2:
            case HDeviceLocalizedModel_iPadPro_10:
            case HDeviceLocalizedModel_iPadPro_13:
            case HDeviceLocalizedModel_iPadPro2_13:
            case HDeviceLocalizedModel_iPadPro2_10:
            {
                temModel = HDeviceModel_iPad;
                return ;
            }

            case HDeviceLocalizedModel_iPadMini1:
            case HDeviceLocalizedModel_iPadMini2:
            case HDeviceLocalizedModel_iPadMini3:
            case HDeviceLocalizedModel_iPadMini4:
            {
                temModel = HDeviceModel_iPadMini;
                return ;
            }

            case HDeviceLocalizedModel_iPodTouch1:
            case HDeviceLocalizedModel_iPodTouch2:
            case HDeviceLocalizedModel_iPodTouch3:
            case HDeviceLocalizedModel_iPodTouch4:
            case HDeviceLocalizedModel_iPodTouch5:
            case HDeviceLocalizedModel_iPodTouch6:
            {
                temModel = HDeviceModel_iPodTouch;
                return ;
            }

            case HDeviceLocalizedModel_iWatch:
            {
                temModel = HDeviceModel_iWatch;
                return ;
            }

            case HDeviceLocalizedModel_Unknown:
            case HDeviceLocalizedModel_Simulator:
            case HDeviceLocalizedModel_AppleTV2:
            case HDeviceLocalizedModel_AppleTV3:
                return;

            default:
                return;
        }
    });
    return temModel;
}

- (HDeviceLocalizedModel)localizedModel
{
    static HDeviceLocalizedModel locModel = HDeviceLocalizedModel_Unknown;
    static dispatch_once_t onceToken;
    __weak __typeof(self) weakSelf = self;
    dispatch_once(&onceToken, ^{
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        NSString *hwName = [strongSelf hwName];
        if (hwName == nil || [hwName length] == 0)
        {
            return;
        }

        NSNumber *device = [[self deviceHwNames] objectForKey:hwName];
        if (device == nil)
        {
            return;
        }

        locModel = (HDeviceLocalizedModel)[device integerValue];
        if (locModel == HDeviceLocalizedModel_iPhoneX)
        {
            self.toolBarHeight = 83;
            self.navViewHeight = 88;
        }
        else
        {
            self.toolBarHeight = 49;
            self.navViewHeight = 64;
        }

    });
    return locModel;
}

- (NSString *)localizedModelString
{
    return [self localizedModelToString:self.localizedModel];
}


- (UIDeviceOrientation)orientation
{
    return [[UIDevice currentDevice] orientation];
}

- (unsigned long long)totalSpace
{
    static dispatch_once_t onceToken;
    static unsigned long long totol = 0;
    dispatch_once(&onceToken, ^{
        NSError *error = nil;
        NSDictionary *fattributes
        = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:&error];
        if (error)
        {
            totol = 0;
            return;
        }

        totol = [fattributes[NSFileSystemSize] unsignedLongLongValue];

    });

    return totol;
}

- (unsigned long long)freeSpace
{
    NSError *error = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error:&error];
    if (error == nil && dictionary != nil && [[dictionary allKeys] containsObject:NSFileSystemFreeSize])
    {
        return [dictionary[NSFileSystemFreeSize] unsignedLongLongValue];
    }

    return 0;
}

- (HDeviceSafeType)supportedSafeType
{
    HDeviceLocalizedModel type = self.localizedModel;
    switch (type) {
        case HDeviceLocalizedModel_iPhone1:
        case HDeviceLocalizedModel_iPhone3G:
        case HDeviceLocalizedModel_iPhone3GS:
        case HDeviceLocalizedModel_iPhone4:
        case HDeviceLocalizedModel_iPhone4S:
        case HDeviceLocalizedModel_iPhone5:
        case HDeviceLocalizedModel_iPhone5C:
            
        case HDeviceLocalizedModel_iPad1:
        case HDeviceLocalizedModel_iPad2:
        case HDeviceLocalizedModel_iPad3:
        case HDeviceLocalizedModel_iPad4:
        case HDeviceLocalizedModel_iPadAir:
            
        case HDeviceLocalizedModel_iPadMini1:
        case HDeviceLocalizedModel_iPadMini2:
            
        case HDeviceLocalizedModel_iPodTouch1:
        case HDeviceLocalizedModel_iPodTouch2:
        case HDeviceLocalizedModel_iPodTouch3:
        case HDeviceLocalizedModel_iPodTouch4:
        case HDeviceLocalizedModel_iPodTouch5:
        case HDeviceLocalizedModel_iPodTouch6:
            
        case HDeviceLocalizedModel_iWatch:
            
        case HDeviceLocalizedModel_AppleTV2:
        case HDeviceLocalizedModel_AppleTV3:
            
        case HDeviceLocalizedModel_Unknown:
        case HDeviceLocalizedModel_Simulator:
            return HDeviceSafeType_Gesture;
        case HDeviceLocalizedModel_iPhoneX:
            return HDeviceSafeType_FaceID;
        default:
            return HDeviceSafeType_TouchID;
    }
}
- (BOOL)supported3DTouch
{
    static BOOL support = NO;
    static dispatch_once_t onceToken;
    __weak __typeof(self) weakSelf = self;
    dispatch_once(&onceToken, ^{
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        HDeviceLocalizedModel type = strongSelf.localizedModel;
        switch (type) {
            case HDeviceLocalizedModel_iPhone6S:
            case HDeviceLocalizedModel_iPhone6SP:
            case HDeviceLocalizedModel_iPhone7:
            case HDeviceLocalizedModel_iPhone7P:
            case HDeviceLocalizedModel_iPhone8:
            case HDeviceLocalizedModel_iPhone8P:
            case HDeviceLocalizedModel_iPhoneX:
                support = YES;
                return;
            default:
                return;
        }
    });
    return support;
}


- (NSString *)UUIDString
{
#if __has_include(<SFHFKeychainUtils.h>)
    static NSString *savedUUID;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError *error = nil;
        NSString *savedUuidString = [SFHFKeychainUtils getPasswordForUsername:kUserNameForKeyChain
                                                      andServiceName:kUUIDKeyForKeyChain
                                                               error:&error];
        
        if ((error == nil) &&
            (savedUuidString != nil) &&
            ([savedUuidString length] > 0))
        {
            //keychain中有对应的idfv值，直接返回
            savedUUID = savedUuidString;
            return;
        }
        
        CFUUIDRef puuid = CFUUIDCreate(nil);
        CFStringRef uuidString = CFUUIDCreateString(nil, puuid );
        NSString * result = (NSString *)CFBridgingRelease(CFStringCreateCopy(NULL, uuidString));
        CFRelease(puuid);
        CFRelease(uuidString);
        
        //第一次读取出来时，保存到keychain中
        [SFHFKeychainUtils storeUsername:kUserNameForKeyChain
                             andPassword:result
                          forServiceName:kUUIDKeyForKeyChain
                          updateExisting:YES
                                   error:nil];
        
        savedUUID = result;
        return ;
    });
    
    return savedUUID;
    
#else
    CFUUIDRef puuid = CFUUIDCreate(nil);
    CFStringRef uuidString = CFUUIDCreateString(nil, puuid );
    NSString * result = (NSString *)CFBridgingRelease(CFStringCreateCopy(NULL, uuidString));
    CFRelease(puuid);
    CFRelease(uuidString);
    
    return result;
#endif
}


/**
 *  系统提供的替代udid的唯一识别字符串，但是在用户把应用开发商所有的应用都删除之后，再重新下载，会生成一个新的值
 *
 *  @return 当前的唯一识别值
 */
- (NSString *)identifierForVendor
{
#if __has_include(<SFHFKeychainUtils.h>)
    static NSString *savedIdfv;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError *error = nil;
        NSString * sidfv = [SFHFKeychainUtils getPasswordForUsername:kUserNameForKeyChain
                                                      andServiceName:kIDFVKeyForKeyChain
                                                               error:&error];

        if ((error == nil) &&
            (sidfv != nil) &&
            ([sidfv length] > 0))
        {
            //keychain中有对应的idfv值，直接返回
            savedIdfv = sidfv;
            return;
        }


        NSString *idfv = [[UIDevice currentDevice] identifierForVendor].UUIDString;
        //第一次读取出来时，保存到keychain中
        [SFHFKeychainUtils storeUsername:kUserNameForKeyChain
                             andPassword:idfv
                          forServiceName:kIDFVKeyForKeyChain
                          updateExisting:YES
                                   error:nil];
        savedIdfv = idfv;
        return ;
    });

    return savedIdfv;


#else
    return [[UIDevice currentDevice] identifierForVendor].UUIDString;
#endif
}

/**
 *  广告标识符
 *
 *  @return 当前的唯一识别值
 */
- (NSString *)advertisingIdentifier
{
#if __has_include(<SFHFKeychainUtils.h>)
    static NSString *savedIdfa;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

    NSError *error = nil;
    NSString * sidfa = [SFHFKeychainUtils getPasswordForUsername:kUserNameForKeyChain
                                           andServiceName:kIDFAKeyForKeyChain
                                                    error:&error];

    if ((error == nil) &&
        (sidfa != nil) &&
        ([sidfa length] > 0))
    {
        //keychain中有对应的idfa值，直接返回
        savedIdfa = sidfa;
        return ;
    }

    NSString *idfa = nil;
    if ([self isAdTrackingEnable] || 1)
    {
        idfa = [ASIdentifierManager sharedManager].advertisingIdentifier.UUIDString;
    }

    //第一次读取出来时，保存到keychain中
    [SFHFKeychainUtils storeUsername:kUserNameForKeyChain
                         andPassword:idfa
                      forServiceName:kIDFAKeyForKeyChain
                      updateExisting:YES
                               error:nil];

    ;
        savedIdfa = idfa;
        return ;
    });

    return savedIdfa;

#else
    return [ASIdentifierManager sharedManager].advertisingIdentifier.UUIDString;
#endif
}

- (CGFloat)screenBrightNess
{
    return [[UIScreen mainScreen] brightness];
}

- (CGFloat)batteryLevel
{
    return [[UIDevice currentDevice] batteryLevel];
}

- (UIDeviceBatteryState)batteryState
{
    return [[UIDevice currentDevice] batteryState];
}

- (HDeviceLevel)deviceLevel
{
    static HDeviceLevel level = HDeviceLevel_VeryLow;
    static dispatch_once_t onceToken;
    __weak __typeof(self) weakSelf = self;
    dispatch_once(&onceToken, ^{
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        HDeviceLocalizedModel type = strongSelf.localizedModel;
        switch (type) {
            case HDeviceLocalizedModel_iPodTouch1:
            case HDeviceLocalizedModel_iPodTouch2:
            case HDeviceLocalizedModel_iPodTouch3:
            case HDeviceLocalizedModel_iPodTouch4:
            case HDeviceLocalizedModel_iPodTouch5:
            case HDeviceLocalizedModel_iPhone1:
            case HDeviceLocalizedModel_iPhone3G:
            case HDeviceLocalizedModel_iPhone3GS:
            case HDeviceLocalizedModel_iPhone4:
            case HDeviceLocalizedModel_iPhone4S:
            case HDeviceLocalizedModel_iPad1:
            case HDeviceLocalizedModel_iPad2:
            case HDeviceLocalizedModel_iPadMini1:
            case HDeviceLocalizedModel_iWatch:
            case HDeviceLocalizedModel_AppleTV2:
            case HDeviceLocalizedModel_AppleTV3:
            case HDeviceLocalizedModel_Simulator:
            case HDeviceLocalizedModel_iPhone5:
            case HDeviceLocalizedModel_iPhone5C:
                return;

            case HDeviceLocalizedModel_iPhone5S:
            case HDeviceLocalizedModel_iPhone6:
            case HDeviceLocalizedModel_iPhone6P:
            case HDeviceLocalizedModel_iPad3:
            case HDeviceLocalizedModel_iPad4:
            case HDeviceLocalizedModel_iPadAir:
            case HDeviceLocalizedModel_iPadMini2:
            case HDeviceLocalizedModel_iPadMini3:
            {
                level = HDeviceLevel_Low;
                return;
            }

            case HDeviceLocalizedModel_iPhone6S:
            case HDeviceLocalizedModel_iPhone6SP:
            case HDeviceLocalizedModel_iPadAir2:
            case HDeviceLocalizedModel_iPodTouch6:
            case HDeviceLocalizedModel_iPhoneSE:
            case HDeviceLocalizedModel_iPhone7:
            case HDeviceLocalizedModel_iPhone7P:
            {
                level = HDeviceLevel_Medium;
                return ;
            }
            
            case HDeviceLocalizedModel_iPhone8:
            case HDeviceLocalizedModel_iPhone8P:
            case HDeviceLocalizedModel_iPhoneX:
            case HDeviceLocalizedModel_Unknown://未来可能出现的设备
            {
                level = HDeviceLevel_High;
                return ;
            }

            default:
            {
                level = HDeviceLevel_High;
                return ;
            }
        }
    });

    return level;
}

- (NSString *)deviceHWName
{
    return [self hwName];
}

- (BOOL)isProDevice
{
    static BOOL ret = NO;
    static dispatch_once_t onceToken;
    __weak __typeof(self) weakSelf = self;
    dispatch_once(&onceToken, ^{
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        HDeviceLocalizedModel type = strongSelf.localizedModel;
        switch (type)
        {
            case HDeviceLocalizedModel_iPhone1:
            case HDeviceLocalizedModel_iPhone3G:
            case HDeviceLocalizedModel_iPhone3GS:
            case HDeviceLocalizedModel_iPhone4:
            case HDeviceLocalizedModel_iPad1:
            case HDeviceLocalizedModel_iPad2:
            case HDeviceLocalizedModel_iPodTouch1:
            case HDeviceLocalizedModel_iPodTouch2:
            case HDeviceLocalizedModel_iPodTouch3:
            case HDeviceLocalizedModel_iPodTouch4:
            case HDeviceLocalizedModel_iPodTouch5:
            case HDeviceLocalizedModel_Simulator:
            case HDeviceLocalizedModel_iWatch:
            case HDeviceLocalizedModel_AppleTV2:
            case HDeviceLocalizedModel_AppleTV3:
                return;

            default:
            {
                ret = YES;
                return;
            }
        }
    });
    return ret;
}

- (NSString *)macAddress
{
    static dispatch_once_t onceToken;
    static NSString *outstring = nil;
    dispatch_once(&onceToken, ^{
        int mib[6];
        size_t len;
        char *buf;
        unsigned char *ptr;
        struct if_msghdr *ifm;
        struct sockaddr_dl *sdl;

        mib[0] = CTL_NET;
        mib[1] = AF_ROUTE;
        mib[2] = 0;
        mib[3] = AF_LINK;
        mib[4] = NET_RT_IFLIST;

        if ((mib[5] = if_nametoindex("en0")) == 0)
        {
            NSLog(@"Error: if_nametoindex error\n");
            outstring = @"";
            return;
        }

        if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0)
        {
            NSLog(@"Error: sysctl, take 1\n");
            outstring = @"";
            return;
        }

        if ((buf = malloc(len)) == NULL)
        {
            NSLog(@"Could not allocate memory. error!\n");
            outstring = @"";
            return;
        }

        if (sysctl(mib, 6, buf, &len, NULL, 0) < 0)
        {
            NSLog(@"Error: sysctl, take 2");
            free(buf);
            outstring = @"";
            return;
        }

        ifm = (struct if_msghdr *)buf;
        sdl = (struct sockaddr_dl *)(ifm + 1);
        ptr = (unsigned char *)LLADDR(sdl);
        outstring = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",
                               *ptr, *(ptr + 1), *(ptr + 2), *(ptr + 3), *(ptr + 4), *(ptr + 5)];
        free(buf);

    });

    return outstring;
}

- (NSString *)localizedModelToString:(HDeviceLocalizedModel)localizedModel
{
    NSString *localizedModelName = nil;
    switch (localizedModel) {

        case HDeviceLocalizedModel_iPhone1:
        {
            localizedModelName = @"iPhone";
            break;
        }
        case HDeviceLocalizedModel_iPhone3G:
        {
            localizedModelName = @"iPhone3";
            break;
        }
        case HDeviceLocalizedModel_iPhone3GS:
        {
            localizedModelName = @"iPhone3GS";
            break;
        }
        case HDeviceLocalizedModel_iPhone4:
        {
            localizedModelName = @"iPhone4";
            break;
        }
        case HDeviceLocalizedModel_iPhone4S:
        {
            localizedModelName = @"iPhone4S";
            break;
        }
        case HDeviceLocalizedModel_iPhone5:
        {
            localizedModelName = @"iPhone5";
            break;
        }
        case HDeviceLocalizedModel_iPhone5S:
        {
            localizedModelName = @"iPhone5S";
            break;
        }
        case HDeviceLocalizedModel_iPhone5C:
        {
            localizedModelName = @"iPhone5C";
            break;
        }
        case HDeviceLocalizedModel_iPhone6:
        {
            localizedModelName = @"iPhone6";
            break;
        }
        case HDeviceLocalizedModel_iPhone6P:
        {
            localizedModelName = @"iPhone6 Plus";
            break;
        }
        case HDeviceLocalizedModel_iPhone6S:
        {
            localizedModelName = @"iPhone6S";
            break;
        }
        case HDeviceLocalizedModel_iPhone6SP:
        {
            localizedModelName = @"iPhone6S Plus";
            break;
        }
        case HDeviceLocalizedModel_iPhoneSE:
        {
            localizedModelName = @"iPhoneSE";
            break;
        }
        case HDeviceLocalizedModel_iPhone7:
        {
            localizedModelName = @"iPhone7";
            break;
        }
        case HDeviceLocalizedModel_iPhone7P:
        {
            localizedModelName = @"iPhone7 Plus";
            break;
        }
        case HDeviceLocalizedModel_iPhone8:
        {
            localizedModelName = @"iPhone8";
            break;
        }
        case HDeviceLocalizedModel_iPhone8P:
        {
             localizedModelName = @"iPhone8P";
            break;
        }
        case HDeviceLocalizedModel_iPhoneX:
        {
            localizedModelName = @"iPhoneX";
            break;
        }
        case HDeviceLocalizedModel_iPad1:
        {
            localizedModelName = @"iPad";
            break;
        }
        case HDeviceLocalizedModel_iPad2:
        {
            localizedModelName = @"iPad2";
            break;
        }
        case HDeviceLocalizedModel_iPad3:
        {
            localizedModelName = @"iPad3";
            break;
        }
        case HDeviceLocalizedModel_iPad4:
        {
            localizedModelName = @"iPad4";
            break;
        }
        case HDeviceLocalizedModel_iPadAir:
        {
            localizedModelName = @"iPad Air";
            break;
        }
        case HDeviceLocalizedModel_iPadAir2:
        {
            localizedModelName = @"iPad Air2";
            break;
        }
        case HDeviceLocalizedModel_iPadMini1:
        {
            localizedModelName = @"iPad Mini";
            break;
        }
        case HDeviceLocalizedModel_iPadMini2:
        {
            localizedModelName = @"iPad Mini2";
            break;
        }
        case HDeviceLocalizedModel_iPadMini3:
        {
            localizedModelName = @"iPad Mini3";
            break;
        }
        case HDeviceLocalizedModel_iPadMini4:
        {
            localizedModelName = @"iPad Mini4";
            break;
        }
        case HDeviceLocalizedModel_iPadPro_10:
        {
            localizedModelName = @"iPad pro(9.7)";
            break;
        }
        case HDeviceLocalizedModel_iPadPro_13:
        {
            localizedModelName = @"iPad pro(12.9)";
            break;
        }
        case HDeviceLocalizedModel_iPadPro2_10:
        {
            localizedModelName = @"iPad pro(10.5)";
            break;
        }
        case HDeviceLocalizedModel_iPadPro2_13:
        {
            localizedModelName = @"iPad pro(12.9,2nd gen)";
            break;
        }
        case HDeviceLocalizedModel_iPodTouch1:
        {
            localizedModelName = @"iTouch1";
            break;
        };
        case HDeviceLocalizedModel_iPodTouch2:
        {
            localizedModelName = @"iTouch2";
            break;
        };
        case HDeviceLocalizedModel_iPodTouch3:
        {
            localizedModelName = @"iTouch3";
            break;
        };
        case HDeviceLocalizedModel_iPodTouch4:
        {
            localizedModelName = @"iTouch4";
            break;
        }
        case HDeviceLocalizedModel_iPodTouch5:
        {
            localizedModelName = @"iTouch5";
            break;
        }
        case HDeviceLocalizedModel_iPodTouch6:
        {
            localizedModelName = @"iTouch6";
            break;
        }

        case HDeviceLocalizedModel_Simulator:
        case HDeviceLocalizedModel_Unknown:
        case HDeviceLocalizedModel_AppleTV2:
        case HDeviceLocalizedModel_AppleTV3:
        case HDeviceLocalizedModel_iWatch:
        default:
        {
            localizedModelName = @"Unknown";
            break;
        }
    }

    return localizedModelName;
}

#pragma mark -私有方法
- (BOOL)isAdTrackingEnable
{
    if (NSClassFromString(@"ASIdentifierManager"))
    {
        return [ASIdentifierManager sharedManager].advertisingTrackingEnabled;
    }
    return NO;
}

- (NSString *)hwName
{
    static NSString *ret = nil;
    static dispatch_once_t token;

    dispatch_once(&token, ^{
        const char *typeSpecifier = "hw.machine";
        size_t size;
        sysctlbyname(typeSpecifier, NULL, &size, NULL, 0);

        char *answer = malloc(size);
        sysctlbyname(typeSpecifier, answer, &size, NULL, 0);

        ret = @(answer);
        free(answer);
    });

    return ret;
}

- (NSDictionary *)deviceHwNames
{
    static NSDictionary *inner = nil;
    static dispatch_once_t token;

    dispatch_once(&token, ^{
        // check this @see http://support.hockeyapp.net/kb/client-integration-ios-mac-os-x/ios-device-types
        // and this @see http://theiPhonewiki.com/wiki/Models
        inner = @{
                  @"iPhone1,1" : @(HDeviceLocalizedModel_iPhone1),    //  iPhone
                  @"iPhone1,2" : @(HDeviceLocalizedModel_iPhone3G),   //  iPhone 3G
                  @"iPhone2,1" : @(HDeviceLocalizedModel_iPhone3GS),  //  iPhone 3GS
                  @"iPhone3,1" : @(HDeviceLocalizedModel_iPhone4),    //  iPhone 4 (GSM)
                  @"iPhone3,2" : @(HDeviceLocalizedModel_iPhone4),    //  iPhone 4 (GSM) ??
                  @"iPhone3,3" : @(HDeviceLocalizedModel_iPhone4),    //  iPhone 4 (CDMA)
                  @"iPhone4,1" : @(HDeviceLocalizedModel_iPhone4S),   //  iPhone 4S
                  @"iPhone5,1" : @(HDeviceLocalizedModel_iPhone5),    //  iPhone 5 (A1428)
                  @"iPhone5,2" : @(HDeviceLocalizedModel_iPhone5),    //  iPhone 5 (A1429)
                  @"iPhone5,3" : @(HDeviceLocalizedModel_iPhone5C),   //  iPhone 5c (A1456/A1532)
                  @"iPhone5,4" : @(HDeviceLocalizedModel_iPhone5C),   //  iPhone 5c (A1507/A1516/A1529)
                  @"iPhone6,1" : @(HDeviceLocalizedModel_iPhone5S),   //  iPhone 5s (A1433/A1453)
                  @"iPhone6,2" : @(HDeviceLocalizedModel_iPhone5S),   //  iPhone 5s (A1457/A1518/A1530)
                  @"iPhone7,1" : @(HDeviceLocalizedModel_iPhone6P),   //  iPhone 6 Plus
                  @"iPhone7,2" : @(HDeviceLocalizedModel_iPhone6),    //  iPhone 6
                  @"iPhone8,1" : @(HDeviceLocalizedModel_iPhone6S),   //  iPhone 6S
                  @"iPhone8,2" : @(HDeviceLocalizedModel_iPhone6SP),  //  iPhone 6S Plus
                  @"iPhone8,4" : @(HDeviceLocalizedModel_iPhoneSE),
                  @"iPhone9,1" : @(HDeviceLocalizedModel_iPhone7),
                  @"iPhone9,3" : @(HDeviceLocalizedModel_iPhone7),
                  @"iPhone9,2" : @(HDeviceLocalizedModel_iPhone7P),
                  @"iPhone9,4" : @(HDeviceLocalizedModel_iPhone7P),
                  @"iPhone10,1": @(HDeviceLocalizedModel_iPhone8),
                  @"iPhone10,4": @(HDeviceLocalizedModel_iPhone8),
                  @"iPhone10,2": @(HDeviceLocalizedModel_iPhone8P),
                  @"iPhone10,5": @(HDeviceLocalizedModel_iPhone8P),
                  @"iPhone10,3": @(HDeviceLocalizedModel_iPhoneX),
                  @"iPhone10,6": @(HDeviceLocalizedModel_iPhoneX),
                  
                  @"iPad1,1" : @(HDeviceLocalizedModel_iPad1),      //  iPad
                  @"iPad2,1" : @(HDeviceLocalizedModel_iPad2),      //  iPad 2 (Wi-Fi)
                  @"iPad2,2" : @(HDeviceLocalizedModel_iPad2),      //  iPad 2 (GSM)
                  @"iPad2,3" : @(HDeviceLocalizedModel_iPad2),      //  iPad 2 (CDMA)
                  @"iPad2,4" : @(HDeviceLocalizedModel_iPad2),      //  iPad 2 (Wi-Fi: revised)
                  @"iPad2,5" : @(HDeviceLocalizedModel_iPadMini1),  //  iPad mini (Wi-Fi)
                  @"iPad2,6" : @(HDeviceLocalizedModel_iPadMini1),  //  iPad mini (A1454)
                  @"iPad2,7" : @(HDeviceLocalizedModel_iPadMini1),  //  iPad mini (A1455)
                  @"iPad3,1" : @(HDeviceLocalizedModel_iPad3),      //  iPad (3rd gen: Wi-Fi)
                  @"iPad3,2" : @(HDeviceLocalizedModel_iPad3),      //  iPad (3rd gen: Wi-Fi+LTE Verizon)
                  @"iPad3,3" : @(HDeviceLocalizedModel_iPad3),      //  iPad (3rd gen: Wi-Fi+LTE AT&T)
                  @"iPad3,4" : @(HDeviceLocalizedModel_iPad4),      //  iPad (4th gen: Wi-Fi)
                  @"iPad3,5" : @(HDeviceLocalizedModel_iPad4),      //  iPad (4th gen: A1459)
                  @"iPad3,6" : @(HDeviceLocalizedModel_iPad4),      //  iPad (4th gen: A1460)
                  @"iPad4,1" : @(HDeviceLocalizedModel_iPadAir),    //  iPad Air (Wi-Fi)
                  @"iPad4,2" : @(HDeviceLocalizedModel_iPadAir),    //  iPad Air (Wi-Fi+LTE)
                  @"iPad4,4" : @(HDeviceLocalizedModel_iPadMini2),  //  iPad mini (2nd gen: Wi-Fi)
                  @"iPad4,5" : @(HDeviceLocalizedModel_iPadMini2),  //  iPad mini (2nd gen: Wi-Fi+LTE)
                  @"iPad4,6" : @(HDeviceLocalizedModel_iPadMini2),  //  iPad mini (2nd gen: Wi-Fi+LTE) ??
                  @"iPad4,7" : @(HDeviceLocalizedModel_iPadMini3),  //  iPad mini (3rd gen: A1599)
                  @"iPad4,8" : @(HDeviceLocalizedModel_iPadMini3),  //  iPad mini (3rd gen: A1600)
                  @"iPad4,9" : @(HDeviceLocalizedModel_iPadMini3),  //  iPad mini (3rd gen: A1601)
                  @"iPad5,3" : @(HDeviceLocalizedModel_iPadAir2),   //  iPad Air (2nd gen: 1566)
                  @"iPad5,4" : @(HDeviceLocalizedModel_iPadAir2),   //  iPad Air (2nd gen: 1567)
                  @"iPad5,1" : @(HDeviceLocalizedModel_iPadMini4),  // iPad mini (4th gen: A1538)
                  @"iPad5,2" : @(HDeviceLocalizedModel_iPadMini4),  // iPad mini (4th gen: A1550)
                  @"iPad6,3" : @(HDeviceLocalizedModel_iPadPro_10), //  iPad (3nd gen: A1673)
                  @"iPad6,4" : @(HDeviceLocalizedModel_iPadPro_10), //  iPad (3nd gen: A1674/A1675)
                  @"iPad6,7" : @(HDeviceLocalizedModel_iPadPro_13), //  iPad pro (3nd gen: A1584)
                  @"iPad6,8" : @(HDeviceLocalizedModel_iPadPro_13), //  iPad pro (3nd gen: A1652)
                  @"iPad6,11": @(HDeviceLocalizedModel_iPad5),// iPad 9.7-Inch 5th Gen (Wi-Fi Only)
                  @"iPad6,12": @(HDeviceLocalizedModel_iPad5),//iPad 9.7-Inch 5th Gen (Wi-Fi/Cellular)
                  @"iPad7,1" : @(HDeviceLocalizedModel_iPadPro2_13), //iPad Pro (12.9-inch, 2nd generation)
                  @"iPad7,2" : @(HDeviceLocalizedModel_iPadPro2_13), //iPad Pro (12.9-inch, 2nd generation)
                  @"iPad7,3" : @(HDeviceLocalizedModel_iPadPro2_10), //iPad Pro (10.5-inch)
                  @"iPad7,4" : @(HDeviceLocalizedModel_iPadPro2_10), //iPad Pro (10.5-inch)
                  

                  @"iPod1,1" : @(HDeviceLocalizedModel_iPodTouch1), //  iPod touch
                  @"iPod2,1" : @(HDeviceLocalizedModel_iPodTouch2), //  iPod touch (2nd gen)
                  @"iPod3,1" : @(HDeviceLocalizedModel_iPodTouch3), //  iPod touch (3rd gen)
                  @"iPod4,1" : @(HDeviceLocalizedModel_iPodTouch4), //  iPod touch (4th gen)
                  @"iPod5,1" : @(HDeviceLocalizedModel_iPodTouch5), //  iPod touch (5th gen)
                  @"iPod7,1" : @(HDeviceLocalizedModel_iPodTouch6), //  iPod touch (6th gen)

                  @"AppleTV2,1" : @(HDeviceLocalizedModel_AppleTV2), //  Apple TV 2
                  @"AppleTV3,1" : @(HDeviceLocalizedModel_AppleTV3), //  Apple TV 3
                  @"AppleTV3,2" : @(HDeviceLocalizedModel_AppleTV3), //  Apple TV 3

                  @"Watch1,1" : @(HDeviceLocalizedModel_iWatch), //  Apple Watch
                  @"Watch1,2" : @(HDeviceLocalizedModel_iWatch), //  Apple Watch


                  @"x86_64" : @(HDeviceLocalizedModel_Simulator)     //  iOS Simulator
                  };
    });
    return inner;
}


#pragma mark 返回手机的状态栏高度
-(CGFloat)navViewHeight
{
    if ([[UIApplication sharedApplication] statusBarOrientation] ==  UIInterfaceOrientationLandscapeLeft || [[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeRight) {
        return 64;
    }
    return _navViewHeight;
}

@end
