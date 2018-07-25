//
//  NSFileManager+Extension.m
//  HExtension
//
//  Created by liyanjun on 16/3/15.
//  Copyright © 2016年 liyanjun. All rights reserved.
//

#import "NSFileManager+Extension.h"

@implementation NSFileManager (Extension)

+ (NSString *)libPath
{
    return [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
}

+ (NSString *)cachesPath
{
    return [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
}

+ (NSString *)documentPath
{
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
}

+ (NSString *)tempPath
{
    return NSTemporaryDirectory();
}

+ (NSString *)appPath
{
    return [NSSearchPathForDirectoriesInDomains(NSApplicationDirectory, NSUserDomainMask, YES) objectAtIndex:0];
}

+ (NSString *)resourcePath
{
   return [[NSBundle mainBundle] resourcePath];
}

+ (BOOL)creatFinderWithFinderPath:(NSString *)finderPath
{
    if (finderPath == nil && [finderPath length] == 0)
    {
        return NO;
    }
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:finderPath])
    {
        //不存在文件夹
        NSError *error = nil;
        BOOL flag = [[NSFileManager defaultManager] createDirectoryAtPath:finderPath withIntermediateDirectories:YES attributes:nil error:&error];
        return flag;
    }
    
    //已经存在文件了
    return YES;
}

+ (BOOL)creatFileWithFilePath:(NSString *)filePath
{
    if (filePath == nil && [filePath length] == 0)
    {
        return NO;
    }
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:filePath])
    {
        return [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
        
    }
    
    //已经存在文件了
    return YES;
}

+ (BOOL)removeFinderWithFinderPath:(NSString *)finderPath
{
    if (finderPath == nil)
    {
        return NO;
    }
    
    if([[NSFileManager defaultManager] fileExistsAtPath:finderPath])
    {
        NSError *error = nil;
        return [[NSFileManager defaultManager] removeItemAtPath:finderPath error:&error];
        
    }
    
    //不存在文件
    return YES;
}

@end
