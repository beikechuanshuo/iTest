//
//  HRecordingCircleButton.h
//  reliao
//
//  Created by liyanjun on 2017/6/7.
//  Copyright © 2017年 liyanjun. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HRecordingCircleButton;

@protocol HRecordingCircleButtonDeletage <NSObject>

- (void)eventDownButtonBeganTouchDown;

- (void)eventDownButtonOutOfView;

- (void)touchMove:(NSSet<UITouch *> *)touches;

- (void)touchEndAction:(id)sender;

- (void)touchMoveSpeedY:(CGFloat)speedY;

- (void)recordingCircleButton:(HRecordingCircleButton *)recordingBtn updateProgress:(CGFloat)progress;

@end

@interface HRecordingCircleButton : UIButton

@property (nonatomic, assign) CGFloat recordMaxTime; //录音最大时间

@property (nonatomic, weak)id<HRecordingCircleButtonDeletage> delegate;

- (instancetype)initWithCircleRadius:(CGFloat)radius center:(CGPoint)center;

@end
