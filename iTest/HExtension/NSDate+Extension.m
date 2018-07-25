//
//  NSDate+Extension.m
//  HExtension
//
//  Created by liyanjun on 16/3/15.
//  Copyright © 2016年 liyanjun. All rights reserved.
//

#import "NSDate+Extension.h"

@implementation NSDate (Extension)

+ (NSDate *)dateWithString:(NSString *)dateStr style:(NSDateDescStyle)style
{
    if(dateStr)
    {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        NSString *format = nil;
        switch (style) {
            case NSDateDescStyle_yyyyMMdd:
                format = @"yyyy-MM-dd";
                break;
            case NSDateDescStyle_yyyyMMddHHmmss:
                format = @"yyyy-MM-dd HH:mm:ss";
                break;
            case NSDateDescStyle_yyyyMMddhhmmss:
                format = @"yyyy-MM-dd hh:mm:ss";
                break;
            default:
                format = @"yyyy-MM-dd HH:mm:ss";
                break;
        }
        [dateFormatter setDateFormat:format];
        [dateFormatter setLocale:[NSLocale systemLocale]];
        NSDate *date = [dateFormatter dateFromString:dateStr];
        return date;
    }
    else
        return nil;
}

//判断系统时24小时制还是12小时制
+ (BOOL)checkDateSetting24Hours
{
    BOOL is24Hours = YES;
    NSString *dateStr = [[NSDate date] descriptionWithLocale:[NSLocale currentLocale]];
    NSArray  *sysbols = @[[[NSCalendar currentCalendar] AMSymbol],[[NSCalendar currentCalendar] PMSymbol]];
    for (NSString *symbol in sysbols)
    {
        if ([dateStr rangeOfString:symbol].location != NSNotFound)
        {
            is24Hours = NO;
            break;
        }
    }
    return is24Hours;
}


@end
