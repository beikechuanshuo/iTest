//
//  NSData+Extension.m
//  HExtension
//
//  Created by liyanjun on 16/3/15.
//  Copyright © 2016年 liyanjun. All rights reserved.
//

#import "NSData+Extension.h"
#import<CommonCrypto/CommonDigest.h>

@implementation NSData (Extension)

+ (NSString *)toHexString:(NSData *)data
{
    if (data == nil || [data length] == 0)
    {
        return @"";
    }
    
    Byte *bytes = (Byte *)[data bytes];
    NSMutableString *hexString = [NSMutableString string];
    for (int i = 0; i < [data length]; i++)
    {
        [hexString appendString:[NSString stringWithFormat:@"%02x",bytes[i]&0xFF]];
    }
    return hexString;
}

- (NSString *)hexSting
{
    return [NSData toHexString:self];
}

- (NSString *)md5StringLowercaseString
{
    // Create byte array of unsigned chars
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    
    // Create 16 byte MD5 hash value, store in buffer
    CC_MD5(self.bytes, (CC_LONG)self.length, md5Buffer);
    
    // Convert unsigned char buffer to NSString of hex values
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x",md5Buffer[i]];
    
    return output;
}

@end
