//
//  QIYIShowARResultView.h
//  reliao
//
//  Created by liyanjun on 2018/3/28.
//  Copyright © 2018年 iqiyi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QIYIScanQRCodeManager.h"

@interface QIYIShowARResultView : UIView

- (void)showARResultVCWithQIYIARScanModel:(QIYIARScanModel *)scanModel tapBtnBlock:(void(^)(NSInteger index))tapBtnBlock;

@end
