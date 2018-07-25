//
//  NSFileManager+Extension.h
//  HExtension
//
//  Created by liyanjun on 16/3/15.
//  Copyright © 2016年 liyanjun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSFileManager (Extension)

+ (NSString *)libPath;

+ (NSString *)cachesPath;

+ (NSString *)documentPath;

+ (NSString *)tempPath;

+ (NSString *)appPath;

+ (NSString *)resourcePath;

+ (BOOL)creatFinderWithFinderPath:(NSString *)finderPath;

+ (BOOL)removeFinderWithFinderPath:(NSString *)finderPath;

+ (BOOL)creatFileWithFilePath:(NSString *)filePath;

@end
