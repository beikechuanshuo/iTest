//
//  NSData+Extension.h
//  HExtension
//
//  Created by liyanjun on 16/3/15.
//  Copyright © 2016年 liyanjun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (Extension)

+ (NSString *)toHexString:(NSData *)data;

- (NSString *)hexSting;

- (NSString *)md5StringLowercaseString;

@end
