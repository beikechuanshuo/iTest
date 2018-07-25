//
//  HDevice+Network.m
//  Test
//
//  Created by liyanjun on 15/12/14.
//  Copyright © 2015年 liyanjun. All rights reserved.
//

#import "HDevice+Network.h"
#import <objc/runtime.h>

@implementation HDevice (Network)

static const void *temNetworktype = &temNetworktype;
static const void *temReach = &temReach;
static const void *temCarrier = &temCarrier;
static const void *temTelephonyNetworkInfo = &temTelephonyNetworkInfo;

@dynamic networkType;
@dynamic reach;
@dynamic carrier;
@dynamic telephonyNetworkInfo;

- (void)init_network
{
    self.reach = [Reachability reachabilityWithHostName:@"www.baidu.com"];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged:)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    [self.reach startNotifier];
    
    self.telephonyNetworkInfo = [[CTTelephonyNetworkInfo alloc] init];
    self.carrier = self.telephonyNetworkInfo.subscriberCellularProvider;
    __weak __typeof (&*self) weakSelf = self;
    self.telephonyNetworkInfo.subscriberCellularProviderDidUpdateNotifier = ^(CTCarrier *carrier) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.carrier = carrier;
    };
}

- (void)dealloc_network
{
    self.reach = nil;
    self.telephonyNetworkInfo = nil;
    self.carrier = nil;
}

- (void)setReach:(Reachability *)reach
{
    objc_setAssociatedObject(self, temReach, reach, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (Reachability *)reach
{
    return objc_getAssociatedObject(self, temReach);
}

- (void)setNetworkType:(HNetworkType)networkType
{
    objc_setAssociatedObject(self, temNetworktype, @(networkType), OBJC_ASSOCIATION_ASSIGN);
}

- (HNetworkType)networkType
{
    return (HNetworkType)[objc_getAssociatedObject(self, temNetworktype) integerValue];
}

- (NSString *)networkTypeString
{
    NSString *network;
    switch (self.networkType)
    {
        case HNetworkType_WiFi:
            network = @"WIFI";
            break;
        case HNetworkType_Mobile:
            if(self.telephonyNetworkInfo != nil && self.telephonyNetworkInfo.currentRadioAccessTechnology != nil &&
               [self.telephonyNetworkInfo.currentRadioAccessTechnology isEqualToString:@""])
            {
                network = self.telephonyNetworkInfo.currentRadioAccessTechnology;
            }
            else
            {
                network = @"3G";
            }
            break;
        case HNetworkType_NoNetwork:
        default:
            network = @"unknow";
            break;
    }
    return network;
}

- (void)setCarrier:(CTCarrier *)carrier
{
    objc_setAssociatedObject(self, temCarrier, carrier, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CTCarrier *)carrier
{
    return objc_getAssociatedObject(self, temCarrier);
}

- (void)setTelephonyNetworkInfo:(CTTelephonyNetworkInfo *)telephonyNetworkInfo
{
    objc_setAssociatedObject(self, temTelephonyNetworkInfo, telephonyNetworkInfo, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CTTelephonyNetworkInfo *)telephonyNetworkInfo
{
    return objc_getAssociatedObject(self, temTelephonyNetworkInfo);
}

- (NSString *)mcc
{
    static NSString *mccCode = nil;
    static dispatch_once_t onceToken;
    __weak __typeof(self) weakSelf = self;
    dispatch_once(&onceToken, ^{
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        CTCarrier *carrier = [strongSelf.telephonyNetworkInfo subscriberCellularProvider];
        mccCode = carrier.mobileCountryCode;
        if (mccCode == nil) {
            mccCode = @"";
        }
    });
   
    return mccCode;
}

- (NSString *)mnc
{
    static NSString *mncCode = nil;
    static dispatch_once_t onceToken;
    __weak __typeof(self) weakSelf = self;
    dispatch_once(&onceToken, ^{
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        CTCarrier *carrier = [strongSelf.telephonyNetworkInfo subscriberCellularProvider];
         mncCode = carrier.mobileNetworkCode;
        if (mncCode == nil) {
            mncCode = @"";
        }
    });
    
    return mncCode;
}

- (NSString *)icc
{
    static NSString *iccCode = nil;
    static dispatch_once_t onceToken;
    __weak __typeof(self) weakSelf = self;
    dispatch_once(&onceToken, ^{
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        CTCarrier *carrier = [strongSelf.telephonyNetworkInfo subscriberCellularProvider];
        iccCode = carrier.isoCountryCode;
        if (iccCode == nil) {
            iccCode = @"";
        }
    });
    return iccCode;
}

- (HDeviceMC)mobileCountry
{
    static HDeviceMC mc = HDeviceMC_None;
    static dispatch_once_t onceToken;
    __weak __typeof(self) weakSelf = self;
    dispatch_once(&onceToken, ^{
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        CTCarrier *carrier = [strongSelf.telephonyNetworkInfo subscriberCellularProvider];
        NSString *mcc = carrier.mobileCountryCode;
        NSString *mnc = carrier.mobileNetworkCode;
        NSString *icc = carrier.isoCountryCode;
        
        if (mcc == nil || [mcc isEqualToString:@""] || mnc == nil ||
            [mnc isEqualToString:@""] || icc == nil || [icc isEqualToString:@""])
        {
            return;
        }
        
        NSInteger mccCode = [mcc integerValue];
        switch (mccCode) {
            case 460:
            case 461:
            {
                mc = HDeviceMC_China;
                return ;
            }
                
            case 440:
            case 441:
            {
                mc = HDeviceMC_Japan;
                return;
            }
                
            case 466:
            {
                mc = HDeviceMC_TW;
                return;
            }
                
            case 520:
                mc = HDeviceMC_Thai;
                return;
                
            default:
                mc = HDeviceMC_Other;
                break;
        }
    });
    return mc;
}

- (NSString *)networkOperator
{
    CTCarrier *carrier = [self.telephonyNetworkInfo subscriberCellularProvider];
    NSString *carrierName = carrier.carrierName;
    return carrierName;
}


#pragma mark --通知--
- (void)reachabilityChanged:(NSNotification *)notif
{
    Reachability *reach = [notif object];
    if (reach.isReachable == NO)
    {
        self.networkType = HNetworkType_NoNetwork;
    }
    else if (reach.isReachableViaWiFi)
    {
        self.networkType = HNetworkType_WiFi;
    }
    else if (reach.isReachableViaWWAN)
    {
        self.networkType = HNetworkType_Mobile;
    }
    else
    {
        self.networkType = HNetworkType_NoNetwork;
    }
}

@end
