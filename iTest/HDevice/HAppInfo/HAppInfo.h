//
//  HAppInfo.h
//  Test
//
//  Created by liyanjun on 15/12/14.
//  Copyright © 2015年 liyanjun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface HAppInfo : NSObject


/**
 * 获取appChannel
 */
@property (nonatomic, readonly) NSString *appChannel;

/**
 * 获取app版本信息
 */
@property (nonatomic, readonly) NSString *appVersionInfo;

/**
 * 获取appName
 */
@property (nonatomic, readonly) NSString *appName;

/**
 * 获取app版本号
 */
@property (nonatomic, readonly) NSString *appVersion;

/**
 * 获取app主版本号
 */
@property (nonatomic, readonly) NSInteger appMajorVersion;

/**
 * 获取小版本号
 */
@property (nonatomic, readonly) NSInteger appMinorVersion;

/**
 *
 */
@property (nonatomic, readonly) NSInteger appPatchVersion;

/**
 * 获取build版本号
 */
@property (nonatomic, readonly) NSInteger appBuildVersion;

/**
 * 推送token
 */
@property (nonatomic,strong) NSString *pushToken;

/**
 * 获取实例对象
 */
+ (instancetype)shareInstance;


@end
