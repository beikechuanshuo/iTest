//
//  iTestModel.h
//  iTest
//
//  Created by liyanjun on 2018/1/4.
//  Copyright © 2018年 liyanjun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface iTestModel : NSObject

@property (nonatomic,assign) NSInteger db_id;

@property (nonatomic,copy) NSString *roomJIDStr;
@property (nonatomic,copy) NSString *fromJIDStr;
@property (nonatomic,strong) NSNumber *groupID;
@property (nonatomic,copy) NSString *messageID;
@property (nonatomic,copy) NSString *type;
@property (nonatomic,copy) NSString *ownerJIDStr;
@property (nonatomic,strong) NSNumber *isSend;
@property (nonatomic,strong) NSNumber *isFromMe;
@property (nonatomic,strong) NSNumber *isSync;
@property (nonatomic,strong) NSNumber *isDelete;
@property (nonatomic,strong) NSNumber *isRevoke;
@property (nonatomic,strong) NSNumber *isRead;

@property (nonatomic,copy) NSString *body;
@property (nonatomic,copy) NSString *iType;
@property (nonatomic,copy) NSString *rcvTime;
@property (nonatomic,copy) NSString *time;
@property (nonatomic,copy) NSString *url;
@property (nonatomic,strong) NSNumber *needTimeStamp;
@property (nonatomic,copy) NSString *howLong;

@property (nonatomic,copy) NSString *fileType;

@property (nonatomic,strong) NSNumber *isMute;

@property (nonatomic,strong) NSNumber *isReceipt;
@property (nonatomic,strong) NSNumber *isHaveReceipt;
@property (nonatomic,strong) NSNumber *unReceiveNumber;
@property (nonatomic,strong) NSNumber *unWatchNumber;
@property (nonatomic,strong) NSNumber *watchedNumber;
@property (nonatomic,strong) NSArray *unReceiveArray;
@property (nonatomic,strong) NSArray *unWatchArray;
@property (nonatomic,strong) NSArray *watchedArray;

@property (nonatomic,copy) NSString *linkTitle;
@property (nonatomic,copy) NSString *linkImage;
@property (nonatomic,copy) NSString *linkDetail;
@property (nonatomic,copy) NSString *linkUrl;

@property (nonatomic,copy) NSString *localSourcePath;

@property (nonatomic,copy) NSString *coverLocalSourcePath;
@property (nonatomic,copy) NSString *coverUrl;
@property (nonatomic,strong) NSNumber *videoFileSize;

//视频聊天相关
@property (nonatomic,copy) NSNumber *webCamType;
@property (nonatomic,copy) NSNumber *webCamAction;
@property (nonatomic,copy) NSString *transformResult;

//新版表情相关
@property (nonatomic,copy) NSString *stype;
@property (nonatomic,copy) NSString *msg;
@property (nonatomic,copy) NSString *thumb;
@property (nonatomic,copy) NSString *gif;
@property (nonatomic,copy) NSString *size;
@property (nonatomic,copy) NSString *md5;
@property (nonatomic,copy) NSString *width;
@property (nonatomic,copy) NSString *height;
@property (nonatomic,copy) NSString *productid;
@property (nonatomic,copy) NSString *designerid;
@property (nonatomic,copy) NSString *exttype;
@property (nonatomic,copy) NSString *content;
@property (nonatomic,copy) NSNumber *animation;

@property (nonatomic,copy) NSString *imageType;

//小视频消息添加一个尺寸的字段
@property (nonatomic,copy) NSString *dim;

@property (nonatomic, copy) NSString *fileUuid;

//合并转发类消息
@property (nonatomic,copy) NSString *chatLogTitle;

@property (nonatomic,strong) NSArray * contentArray;

/** 仅收藏消息用 */
@property (nonatomic, copy) NSString *roomName;
@property (nonatomic, copy) NSString *senderName;

//code类型
@property (nonatomic,copy) NSString *languageType;

@end
