//
//  UITextField+Extension.h
//  reliao
//
//  Created by liyanjun on 2017/9/5.
//  Copyright © 2017年 liyanjun. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITextField (Extension)

//光标所在位置
- (NSRange)selectedRange;

//设置光标位置
- (void)setSelectedRange:(NSRange)range;

@end
