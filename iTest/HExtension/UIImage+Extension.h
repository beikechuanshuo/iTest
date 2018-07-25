//
//  UIImage+Extension.h
//  HExtension
//
//  Created by liyanjun on 16/3/15.
//  Copyright © 2016年 liyanjun. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Extension)

+ (UIImage *)imageFromView:(UIView *)theView;

+(UIImage *)imageFromView:(UIView *)theView frame:(CGRect)frame;

+ (UIImage *)imageFromColor:(UIColor *)color;

+ (UIImage *)imageFromColor:(UIColor *)color size:(CGSize)size;

//高斯模糊的照片
+ (UIImage *)blurImageFromImage:(UIImage *)image;

//屏幕照片
+ (UIImage *)imageWithScreenWindow;

//拍照和系统相册图片矫正方向
- (UIImage *)normalizedImage;

- (UIImage *)normalizedImageByDrawImage;

- (UIImage *)normalizedImageWithSize:(CGSize)size;

/** 纠正图片的方向 */
- (UIImage *)fixOrientation;

/** 按给定的方向旋转图片 */
- (UIImage*)rotate:(UIImageOrientation)orient;

/** 垂直翻转 */
- (UIImage *)flipVertical;

/** 水平翻转 */
- (UIImage *)flipHorizontal;

/** 将图片旋转degrees角度 */
- (UIImage *)imageRotatedByDegrees:(CGFloat)degrees;

/** 将图片旋转radians弧度 */
- (UIImage *)imageRotatedByRadians:(CGFloat)radians;

//截取部分图像
- (UIImage *)getSubImage:(CGRect)rect;

@end
