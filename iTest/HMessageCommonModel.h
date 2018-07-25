//
//  HMessageCommonModel.h
//  reliao
//
//  Created by liyanjun on 2018/4/2.
//  Copyright © 2018年 liyanjun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HMessageCommonModel : NSObject

@property (nonatomic, assign) NSInteger db_id;
@property (nonatomic,copy) NSString *roomJIDStr;
@property (nonatomic,copy) NSString *fromJIDStr;
@property (nonatomic,strong) NSNumber *groupID;
@property (nonatomic,copy) NSString *messageID;
@property (nonatomic,copy) NSString *type;
@property (nonatomic,copy) NSString *time;
@property (nonatomic,copy) NSNumber *timeStamp;
@property (nonatomic,strong) NSNumber *isSend;
@property (nonatomic,strong) NSNumber *isFromMe;
@property (nonatomic,strong) NSNumber *isSync;
@property (nonatomic,strong) NSNumber *isDelete;
@property (nonatomic,strong) NSNumber *isRevoke;
@property (nonatomic,strong) NSNumber *isRead;
@property (nonatomic,copy) NSString *iType;
@property (nonatomic,strong) NSNumber *needTimeStamp;
@property (nonatomic,strong) NSNumber *isMute;
@property (nonatomic,strong) NSNumber *isReceipt;
@property (nonatomic,strong) NSNumber *isHaveReceipt;
@property (nonatomic,strong) NSNumber *unReceiveNumber;
@property (nonatomic,strong) NSNumber *unWatchNumber;
@property (nonatomic,strong) NSNumber *watchedNumber;
@property (nonatomic,copy) NSString *unReceiveArray;
@property (nonatomic,copy) NSString *unWatchArray;
@property (nonatomic,copy) NSString *watchedArray;
//是否更新session操作时间来改变顺序，默认0改变顺序，1不改变，（退出群聊alert等不改变session顺序）
@property (nonatomic,copy) NSNumber *noChangeOrder;

@end
