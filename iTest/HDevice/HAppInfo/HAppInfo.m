//
//  HAppInfo.m
//  Test
//
//  Created by liyanjun on 15/12/14.
//  Copyright © 2015年 liyanjun. All rights reserved.
//

#import "HAppInfo.h"

@interface HAppInfo ()


@end

@implementation HAppInfo

@synthesize pushToken;

+ (instancetype)shareInstance
{
    static HAppInfo *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HAppInfo alloc]init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}


- (NSString *)appChannel
{
    static NSString*ret = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ret = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"APP_CHANNEL"];
    });
    
    return ret;
}

- (NSString *)appVersionInfo
{
    static NSString *ret = nil;
    static dispatch_once_t token;
    __strong __typeof(self) weakSelf = self;
    dispatch_once(&token, ^{
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        NSString *versionInfo = nil;
        NSString *strProduct = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleNameKey];
        NSString *strPlatform = @"iphone";
        NSString *strAppVersion = [strongSelf appVersion];
        if (strProduct && strPlatform && strAppVersion)
        {
            versionInfo = [NSString stringWithFormat:@"%@_%@_%@", strProduct, strPlatform, strAppVersion];
            NSString *strSubVersion = [strongSelf appSubVersion];
            if (strSubVersion)
            {
                versionInfo = [versionInfo stringByAppendingFormat:@"_%@", strSubVersion];
            }
        }
        
        ret = versionInfo;
    });
    return ret;
}

- (NSString *)appName
{
    static NSString *ret = nil;
    static dispatch_once_t token;
    
    dispatch_once(&token, ^{
        ret = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleNameKey];
    });
    return ret;
}

/**
 *  获取当前应用版本的字符串
 *
 *  @return 返回当前应用版本的字符串
 */
- (NSString *)appVersion
{
    static NSString *ret = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        NSDictionary *infoDic = [[NSBundle mainBundle] infoDictionary];
        ret = [infoDic valueForKey:@"CFBundleShortVersionString"];
    });
    return ret;
}

- (NSInteger)appMajorVersion
{
    static NSInteger ret = 0;
    static dispatch_once_t token;
    __strong __typeof(self) weakSelf = self;
    dispatch_once(&token, ^{
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        NSArray *const versionArray = [strongSelf versionArray];
        if (versionArray.count == 1)
        {
            ret = [versionArray.firstObject intValue];
        }
    });
    return ret;
}


- (NSInteger)appMinorVersion
{
    static NSInteger ret = 0;
    static dispatch_once_t token;
    __strong __typeof(self) weakSelf = self;
    dispatch_once(&token, ^{
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        NSArray *const versionArray = [strongSelf versionArray];
        if (versionArray.count == 2)
        {
            ret = [versionArray[1] intValue];
        }
    });
    return ret;
}


- (NSInteger)appPatchVersion
{
    static NSInteger ret = 0;
    static dispatch_once_t token;
    __strong __typeof(self) weakSelf = self;
    dispatch_once(&token, ^{
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        NSArray *const versionArray = [strongSelf versionArray];
        if (versionArray.count == 3)
        {
            ret = [versionArray[2] intValue];
        }
    });
    return ret;
}


- (NSInteger)appBuildVersion
{
    static NSInteger ret = 0;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        NSDictionary *infoDic = [[NSBundle mainBundle] infoDictionary];
        ret = [[infoDic valueForKey:@"CFBundleVersion"] intValue];
    });
    return ret;
}


#pragma mark --私有方法--
- (NSString *)appSubVersion
{
#ifdef INHOUSE
    return @"InHouse";
#endif
    
#ifdef DEBUG
    return @"Debug";
#else
    return @"Release";
#endif
}

- (NSArray *)versionArray
{
    NSString *const appVersion = [self appVersion];
    NSArray *const versionArray = [appVersion componentsSeparatedByString:@"."];
    return versionArray;
}

@end
