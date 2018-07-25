//
//  HSystem.h
//  Test
//
//  Created by liyanjun on 15/12/14.
//  Copyright © 2015年 liyanjun. All rights reserved.
//

#import <Foundation/Foundation.h>

//系统版本判断
#define IS_IOS5_OR_HIGHER  ([[[UIDevice currentDevice] systemVersion] floatValue] >= 5.0)
#define IS_IOS6_OR_HIGHER  ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6.0)
#define IS_IOS7_OR_HIGHER  ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
#define IS_IOS8_OR_HIGHER  ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
#define IS_IOS9_OR_HIGHER  ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0)

@interface HSystem : NSObject

/**
 * 设备系统名称 如iOS
 */
@property (nonatomic, readonly) NSString *systemName;

/**
 *  系统版本
 */
@property (nonatomic, readonly, strong) NSString *systemVersion;

/**
 *  是否越狱
 */
@property (nonatomic, readonly) BOOL isJailbroken;

/**
 *  当前系统语言
 */
@property (nonatomic, readonly) NSString *curLanguage;

/**
 * 获取实例对象
 */
+ (instancetype)shareInstance;

@end
