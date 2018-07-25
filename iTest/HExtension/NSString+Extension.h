//
//  NSString+Extension.h
//  HExtension
//
//  Created by liyanjun on 16/3/15.
//  Copyright © 2016年 liyanjun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Extension)

- (NSString *)encode;

- (NSString *)decode;

- (NSString *)md5StringLowercaseString;

+ (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString;

@end
