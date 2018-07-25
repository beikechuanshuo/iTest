//
//  HNewRecordingViewController.h
//  reliao
//
//  Created by liyanjun on 2017/6/7.
//  Copyright © 2017年 liyanjun. All rights reserved.
//

#import <UIKit/UIKit.h>

NSString *const kSightVideoServerPathKey = @"kSightVideoServerPathKey";
NSString *const kSightVideoNameKey = @"kSightVideoNameKey";
NSString *const kSightVideoPathKey = @"kSightVideoPathKey";
NSString *const kSightVideoThumbnailKey = @"kSightVideoThumbnailKey";
NSString *const kSightVideoThumbnailArrayKey = @"kSightVideoThumbnailArrayKey";
NSString *const kSightVideoThumbnailCapturedDurationKey = @"kSightVideoThumbnailCapturedDurationKey";
NSString *const kSightVideoSizeKey = @"kSightVideoSizeKey";

@protocol HNewRecordingViewControllerDelegate <NSObject>

@optional
/** 录制完成代理 */
- (void)recordingViewDidEndRecordWithInfo:(NSDictionary *)recordInfo;

@end

@interface HNewRecordingViewController : UIViewController

@property (weak, nonatomic) id<HNewRecordingViewControllerDelegate> recordDelegate;

@end
