//
//  iTestModel.m
//  iTest
//
//  Created by liyanjun on 2018/1/4.
//  Copyright © 2018年 liyanjun. All rights reserved.
//

#import "iTestModel.h"
#import "iTestModel+WCTTableCoding.h"
#import <WCDB/WCDB.h>

@implementation iTestModel

WCDB_IMPLEMENTATION(iTestModel)
WCDB_SYNTHESIZE(iTestModel, roomJIDStr)
WCDB_SYNTHESIZE(iTestModel, fromJIDStr)
WCDB_SYNTHESIZE(iTestModel, groupID)
WCDB_SYNTHESIZE(iTestModel, messageID)
WCDB_SYNTHESIZE(iTestModel, type)
WCDB_SYNTHESIZE(iTestModel, ownerJIDStr)
WCDB_SYNTHESIZE(iTestModel, isSend)
WCDB_SYNTHESIZE(iTestModel, isFromMe)
WCDB_SYNTHESIZE(iTestModel, isSync)
WCDB_SYNTHESIZE(iTestModel, isDelete)
WCDB_SYNTHESIZE(iTestModel, isRevoke)
WCDB_SYNTHESIZE(iTestModel, isRead)
WCDB_SYNTHESIZE(iTestModel, body)
WCDB_SYNTHESIZE(iTestModel, iType)
WCDB_SYNTHESIZE(iTestModel, rcvTime)
WCDB_SYNTHESIZE(iTestModel, time)
WCDB_SYNTHESIZE(iTestModel, url)
WCDB_SYNTHESIZE(iTestModel, needTimeStamp)
WCDB_SYNTHESIZE(iTestModel, howLong)
WCDB_SYNTHESIZE(iTestModel, db_id)
WCDB_SYNTHESIZE(iTestModel, fileType)
WCDB_SYNTHESIZE(iTestModel, isMute)
WCDB_SYNTHESIZE(iTestModel, isReceipt)
WCDB_SYNTHESIZE(iTestModel, isHaveReceipt)
WCDB_SYNTHESIZE(iTestModel, unReceiveNumber)
WCDB_SYNTHESIZE(iTestModel, unWatchNumber)
WCDB_SYNTHESIZE(iTestModel, watchedNumber)
WCDB_SYNTHESIZE(iTestModel, unReceiveArray)
WCDB_SYNTHESIZE(iTestModel, unWatchArray)
WCDB_SYNTHESIZE(iTestModel, watchedArray)
WCDB_SYNTHESIZE(iTestModel, linkTitle)
WCDB_SYNTHESIZE(iTestModel, linkImage)
WCDB_SYNTHESIZE(iTestModel, linkDetail)
WCDB_SYNTHESIZE(iTestModel, linkUrl)
WCDB_SYNTHESIZE(iTestModel, localSourcePath)
WCDB_SYNTHESIZE(iTestModel, coverLocalSourcePath)
WCDB_SYNTHESIZE(iTestModel, coverUrl)
WCDB_SYNTHESIZE(iTestModel, videoFileSize)
WCDB_SYNTHESIZE(iTestModel, webCamType)
WCDB_SYNTHESIZE(iTestModel, webCamAction)
WCDB_SYNTHESIZE(iTestModel, transformResult)
WCDB_SYNTHESIZE(iTestModel, stype)
WCDB_SYNTHESIZE(iTestModel, msg)
WCDB_SYNTHESIZE(iTestModel, thumb)
WCDB_SYNTHESIZE(iTestModel, gif)
WCDB_SYNTHESIZE(iTestModel, size)
WCDB_SYNTHESIZE(iTestModel, md5)
WCDB_SYNTHESIZE(iTestModel, width)
WCDB_SYNTHESIZE(iTestModel, height)
WCDB_SYNTHESIZE(iTestModel, productid)
WCDB_SYNTHESIZE(iTestModel, designerid)
WCDB_SYNTHESIZE(iTestModel, exttype)
WCDB_SYNTHESIZE(iTestModel, content)
WCDB_SYNTHESIZE(iTestModel, animation)
WCDB_SYNTHESIZE(iTestModel, dim)
WCDB_SYNTHESIZE(iTestModel, fileUuid)
WCDB_SYNTHESIZE(iTestModel, chatLogTitle)
WCDB_SYNTHESIZE(iTestModel, contentArray)
WCDB_SYNTHESIZE(iTestModel, languageType)
WCDB_SYNTHESIZE(iTestModel, roomName)
WCDB_SYNTHESIZE_COLUMN(iTestModel,imageType,"imgType")

WCDB_INDEX(iTestModel, "MessageID", messageID)

@end
