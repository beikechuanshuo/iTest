//
//  HDevice+Network.h
//  Test
//
//  Created by liyanjun on 15/12/14.
//  Copyright © 2015年 liyanjun. All rights reserved.
//

#import "HDevice.h"
#import "Reachability.h"
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CoreTelephonyDefines.h>

//网络状况
typedef NS_ENUM(NSInteger, HNetworkType)
{
    HNetworkType_Unknown,          //未知状态
    HNetworkType_NoNetwork,    //当前没有网络连接
    HNetworkType_WiFi,         //当前网络为wifi
    HNetworkType_Mobile        //当前网络为2G或者3G
};

@interface HDevice (Network)

//以下一个为扩展的私有属性，请不要对外使用
@property (nonatomic,strong) Reachability *reach;

/**
 *  当前网络状态枚举，始终保存最新值
 */
@property (nonatomic, assign) HNetworkType networkType;

/**
 *  当前网络状态
 */
@property (nonatomic, readonly) NSString *networkTypeString;

/**
 * 获取移动国家码，移动网络码，iso国家码等需要的对象
 */
@property (nonatomic, strong) CTCarrier *carrier;

/**
 * 获取手机网络为2G/3G/4G等需要的对象
 */
@property (nonatomic, strong) CTTelephonyNetworkInfo *telephonyNetworkInfo;

/**
 * 移动国家码
 */
@property (nonatomic, readonly) NSString *mcc;

/**
 * 移动网络码
 */
@property (nonatomic, readonly) NSString *mnc;

/**
 * iso国家代码
 */
@property (nonatomic, readonly) NSString *icc;

/**
 *  mibile country
 */
@property (nonatomic, readonly) HDeviceMC mobileCountry;

/**
 *  网络运营商名称
 */
@property (nonatomic, readonly) NSString *networkOperator;

@end
