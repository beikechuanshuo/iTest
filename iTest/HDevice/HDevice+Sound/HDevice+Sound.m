//
//  HDevice+Sound.m
//  Test
//
//  Created by liyanjun on 15/12/14.
//  Copyright © 2015年 liyanjun. All rights reserved.
//

#import "HDevice+Sound.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

@implementation HDevice (Sound)

/**
 *  获取系统音量
 *
 *  @return 返回当前系统音量
 */
- (CGFloat)volume
{
    CGFloat volume;
    
    if ([[AVAudioSession sharedInstance] respondsToSelector:@selector(outputVolume)])
    {
        volume = (CGFloat)[[AVAudioSession sharedInstance] outputVolume];
    }
    else
    {
        MPMusicPlayerController *player = nil;
        if ([MPMusicPlayerController instancesRespondToSelector:@selector(systemMusicPlayer)])
        {
            player = [MPMusicPlayerController systemMusicPlayer];
        }
        else
        {
            player = [MPMusicPlayerController applicationMusicPlayer];
        }
        volume = (CGFloat)[[player valueForKey:@"volume"] floatValue];
    }
    
    return volume;
}


/**
 *    检测麦克风隐私设置是否关闭
 *
 *    @return    返回是否启用麦克风
 */
- (BOOL)checkAudioEnable
{
    __block BOOL bRet = YES;
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    if ([session respondsToSelector:@selector(requestRecordPermission:)])
    {
        [session requestRecordPermission:^(BOOL granted) {
            bRet = granted;
        }];
    }
    
    return bRet;
}

@end
