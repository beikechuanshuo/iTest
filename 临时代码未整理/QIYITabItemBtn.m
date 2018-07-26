//
//  QIYITabItemBtn.m
//  reliao
//
//  Created by liyanjun on 2018/3/27.
//  Copyright © 2018年 iqiyi. All rights reserved.
//

#import "QIYITabItemBtn.h"


@implementation QIYITabItemBtn

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.font = [UIFont systemFontOfSize:12.0];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.imageView.frame = CGRectMake((CGRectGetWidth(self.frame)-25)/2, 15, 25, 25);
    self.titleLabel.frame = CGRectMake(5, CGRectGetMaxY(self.imageView.frame)+5,CGRectGetWidth(self.frame)-10 , 15);
}

@end
