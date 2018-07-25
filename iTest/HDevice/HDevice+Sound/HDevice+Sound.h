//
//  HDevice+Sound.h
//  Test
//
//  Created by liyanjun on 15/12/14.
//  Copyright © 2015年 liyanjun. All rights reserved.
//

#import "HDevice.h"

@interface HDevice (Sound)

/**
 *  当前音量，如果正在播放音乐返回播放器的音量，如果使用耳机 返回耳机的音量
 */
@property (nonatomic, readonly) CGFloat volume;

/**
 *  检查当前麦克风服务是否打开，如果第一次安装调用此方法会弹出提示框
 */
@property (nonatomic, readonly) BOOL checkAudioEnable;

@end
