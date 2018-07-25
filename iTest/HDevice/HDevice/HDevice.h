//
//  HDevice.h
//  Test
//
//  Created by liyanjun on 15/12/14.
//  Copyright © 2015年 liyanjun. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

static NSString *const kUserNameForKeyChain = @"kUserNameForKeyChain_Reliao";
static NSString *const kIDFVKeyForKeyChain = @"kIDFVKeyForKeyChain_Reliao";
static NSString *const kIDFAKeyForKeyChain = @"kIDFAKeyForKeyChain_Reliao";
static NSString *const kUUIDKeyForKeyChain = @"kUUIDKeyForKeyChain_Reliao";


/** 设备类型 **/
typedef NS_ENUM(NSInteger, HDeviceModel)
{
    HDeviceModel_iPhone,
    HDeviceModel_iPad,
    HDeviceModel_iPadMini,
    HDeviceModel_iPodTouch,
    HDeviceModel_iWatch,
    HDeviceModel_other,
};

/**
 设备支持的安全验证类型
 **/
typedef NS_ENUM(NSInteger, HDeviceSafeType)
{
    HDeviceSafeType_Gesture,
    HDeviceSafeType_TouchID,
    HDeviceSafeType_FaceID
};


/** 设备本地化类型 **/
typedef NS_ENUM(NSInteger, HDeviceLocalizedModel)
{
    HDeviceLocalizedModel_Unknown, //
    HDeviceLocalizedModel_Simulator, //模拟器
    
    //iPhone
    HDeviceLocalizedModel_iPhone1,
    HDeviceLocalizedModel_iPhone3G,
    HDeviceLocalizedModel_iPhone3GS,
    HDeviceLocalizedModel_iPhone4,
    HDeviceLocalizedModel_iPhone4S,
    HDeviceLocalizedModel_iPhone5,
    HDeviceLocalizedModel_iPhone5S,
    HDeviceLocalizedModel_iPhone5C,
    HDeviceLocalizedModel_iPhone6,
    HDeviceLocalizedModel_iPhone6P,
    HDeviceLocalizedModel_iPhone6S,
    HDeviceLocalizedModel_iPhone6SP,
    HDeviceLocalizedModel_iPhoneSE,
    HDeviceLocalizedModel_iPhone7,
    HDeviceLocalizedModel_iPhone7P,
    HDeviceLocalizedModel_iPhone8,
    HDeviceLocalizedModel_iPhone8P,
    HDeviceLocalizedModel_iPhoneX,
    //iPad
    HDeviceLocalizedModel_iPad1,
    HDeviceLocalizedModel_iPad2,
    HDeviceLocalizedModel_iPad3,
    HDeviceLocalizedModel_iPad4,
    HDeviceLocalizedModel_iPadAir,
    HDeviceLocalizedModel_iPadAir2,
    HDeviceLocalizedModel_iPad5,
    
    //iPadMini
    HDeviceLocalizedModel_iPadMini1,
    HDeviceLocalizedModel_iPadMini2,
    HDeviceLocalizedModel_iPadMini3,
    HDeviceLocalizedModel_iPadMini4,
    
    //iPadPro
    HDeviceLocalizedModel_iPadPro_10,
    HDeviceLocalizedModel_iPadPro_13,
    HDeviceLocalizedModel_iPadPro2_13,
    HDeviceLocalizedModel_iPadPro2_10,
    
    
    //iPodTouch
    HDeviceLocalizedModel_iPodTouch1,
    HDeviceLocalizedModel_iPodTouch2,
    HDeviceLocalizedModel_iPodTouch3,
    HDeviceLocalizedModel_iPodTouch4,
    HDeviceLocalizedModel_iPodTouch5,
    HDeviceLocalizedModel_iPodTouch6,
    
    //iWatch
    HDeviceLocalizedModel_iWatch,
    
    //TV
    HDeviceLocalizedModel_AppleTV2,
    HDeviceLocalizedModel_AppleTV3
};

//设备等级
typedef NS_ENUM(NSInteger, HDeviceLevel)
{
    HDeviceLevel_VeryLow,  //iPhone5 5C及以下设备
    HDeviceLevel_Low,      //iPhone6 6P一下
    HDeviceLevel_Medium,   //iPhone6s iPhone6SP以上
    HDeviceLevel_High,     //iPhone8 8P X以上
};

/**
 *  常用国家MCC代码
 */
typedef NS_ENUM(NSUInteger, HDeviceMC)
{
    /**
     *  空
     */
    HDeviceMC_None,
    /**
     *  460,461
     */
    HDeviceMC_China,
    /**
     *  440,441
     */
    HDeviceMC_Japan,
    /**
     *  466
     */
    HDeviceMC_TW,
    /**
     *  520
     */
    HDeviceMC_Thai,
    /** 其他 */
    HDeviceMC_Other
};

@interface HDevice : NSObject

//TODO:区分属性名
/**
 * 设备种类 iPhone iTouch iPad iPadMini等
 */
@property (nonatomic, readonly) HDeviceModel model;

/**
 * 设备本地化类型
 */
@property (nonatomic, readonly) HDeviceLocalizedModel localizedModel;

/**
 *设备本地化类型
 */
@property (nonatomic, readonly) NSString *localizedModelString;

/**
 * 设备等级情况
 */
@property (nonatomic, readonly) HDeviceLevel deviceLevel;

/**
 *  设备硬件代号
 */
@property (nonatomic, readonly) NSString *deviceHWName;

/**
 *  判断是否是iphone4s、ipad3、ipod5及以上机型
 */
@property (nonatomic, readonly) BOOL isProDevice;

/**
 * 系统返回的设备方向
 */
@property (nonatomic, readonly) UIDeviceOrientation orientation;

/**
 * 设备总空间，单位为字节
 */
@property (nonatomic, readonly) unsigned long long totalSpace;

/**
 *  设备剩余空间，单位为字节
 */
@property (nonatomic, readonly) unsigned long long freeSpace;

/*
 * 是否支持系统指纹识别TouchID
 */
@property (nonatomic, readonly) HDeviceSafeType supportedSafeType;

/**
 * 是否支持3DTouch
 */
@property (nonatomic, readonly) BOOL supported3DTouch;

/**
 *  UUID用来充当唯一标示
 */
- (NSString *)UUIDString;

/**
 *  系统提供的替代udid的唯一识别字符串，但是在用户把应用开发商所有的应用都删除之后，再重新下载，会生成一个新的值
 */
@property (nonatomic, readonly) NSString *identifierForVendor;

/**
 *  广告标识符
 */
@property (nonatomic, readonly) NSString *advertisingIdentifier;

/**
 *  屏幕亮度，返回一个0.0到1.0的值
 */
@property (nonatomic, readonly) CGFloat screenBrightNess;

/**
 *  设备当前电量，返回一个0.0到1.0的值
 */
@property (nonatomic, readonly) CGFloat batteryLevel;

/**
 * 设备电池状态
 */
@property (nonatomic, readonly) UIDeviceBatteryState batteryState;

/**
 *
 * Mac地址
 */
@property (nonatomic, readonly) NSString *macAddress;


@property (nonatomic,assign) CGFloat toolBarHeight;

@property (nonatomic,assign) CGFloat navViewHeight;

//webview是否有图片长按弹出actionsheet，根据此值来屏蔽webview的图片点击事件
@property (nonatomic,assign) BOOL isWebViewImageActionSheetAppear;

/**
 * 获取实例对象
 */
+ (instancetype)shareInstance;

/**
 * 设备名称转化
 */
- (NSString *)localizedModelToString:(HDeviceLocalizedModel)localizedModel;

@end
