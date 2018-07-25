//
//  HRecordVideoEncoder.h
//  reliao
//
//  Created by liyanjun on 16/9/23.
//
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>

@interface HRecordVideoEncoder : NSObject

@property (nonatomic, readonly) NSString *path;

/**
 *  HRecordVideoEncoder遍历构造器的
 *
 *  @param path 媒体存发路径
 *  @param cy   视频分辨率的高
 *  @param cx   视频分辨率的宽
 *  @param ch   音频通道
 *  @param rate 音频的采样比率
 *
 *  @return HRecordVideoEncoder的实体
 */
+ (HRecordVideoEncoder*)encoderForPath:(NSString*)path Height:(NSInteger)cy width:(NSInteger)cx channels: (int)ch samples:(Float64)rate;

/**
 *  初始化方法
 *
 *  @param path 媒体存发路径
 *  @param cy   视频分辨率的高
 *  @param cx   视频分辨率的宽
 *  @param ch   音频通道
 *  @param rate 音频的采样率
 *
 *  @return WCLRecordEncoder的实体
 */
- (instancetype)initPath:(NSString*)path Height:(NSInteger)cy width:(NSInteger)cx channels: (int)ch samples:(Float64)rate;

/**
 *  完成视频录制时调用
 *
 *  @param handler 完成的回掉block
 */
- (void)finishWithCompletionHandler:(void (^)(void))handler;

/**
 *  通过这个方法写入数据
 *
 *  @param sampleBuffer 写入的数据
 *  @param isVideo      是否写入的是视频
 *
 *  @return 写入是否成功
 */
- (BOOL)encodeFrame:(CMSampleBufferRef)sampleBuffer isVideo:(BOOL)isVideo;


@end
