//
//  NSDate+Extension.h
//  HExtension
//
//  Created by liyanjun on 16/3/15.
//  Copyright © 2016年 liyanjun. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, NSDateDescStyle)
{
    NSDateDescStyle_yyyyMMdd,
    NSDateDescStyle_yyyyMMddHHmmss,
    NSDateDescStyle_yyyyMMddhhmmss,
    NSDateDescStyle_Other
};

@interface NSDate (Extension)

+ (NSDate *)dateWithString:(NSString *)dateStr style:(NSDateDescStyle)style;

//判断系统时24小时制还是12小时制
+ (BOOL)checkDateSetting24Hours;

@end
