//
//  iTestModel+WCTTableCoding.h
//  iTest
//
//  Created by liyanjun on 2018/1/4.
//  Copyright © 2018年 liyanjun. All rights reserved.
//

#import "iTestModel.h"
#import <WCDB/WCDB.h>

@interface iTestModel (WCTTableCoding) <WCTTableCoding>

WCDB_PROPERTY(roomJIDStr)
WCDB_PROPERTY(fromJIDStr)
WCDB_PROPERTY(groupID)
WCDB_PROPERTY(messageID)
WCDB_PROPERTY(type)
WCDB_PROPERTY(ownerJIDStr)
WCDB_PROPERTY(isSend)
WCDB_PROPERTY(isFromMe)
WCDB_PROPERTY(isSync)
WCDB_PROPERTY(isDelete)
WCDB_PROPERTY(isRevoke)
WCDB_PROPERTY(isRead)
WCDB_PROPERTY(body)
WCDB_PROPERTY(iType)
WCDB_PROPERTY(rcvTime)
WCDB_PROPERTY(time)
WCDB_PROPERTY(url)
WCDB_PROPERTY(needTimeStamp)
WCDB_PROPERTY(howLong)
WCDB_PROPERTY(db_id)
WCDB_PROPERTY(fileType)
WCDB_PROPERTY(isMute)
WCDB_PROPERTY(isReceipt)
WCDB_PROPERTY(isHaveReceipt)
WCDB_PROPERTY(unReceiveNumber)
WCDB_PROPERTY(unWatchNumber)
WCDB_PROPERTY(watchedNumber)
WCDB_PROPERTY(unReceiveArray)
WCDB_PROPERTY(unWatchArray)
WCDB_PROPERTY(watchedArray)
WCDB_PROPERTY(linkTitle)
WCDB_PROPERTY(linkImage)
WCDB_PROPERTY(linkDetail)
WCDB_PROPERTY(linkUrl)
WCDB_PROPERTY(localSourcePath)
WCDB_PROPERTY(coverLocalSourcePath)
WCDB_PROPERTY(coverUrl)
WCDB_PROPERTY(videoFileSize)
WCDB_PROPERTY(webCamType)
WCDB_PROPERTY(webCamAction)
WCDB_PROPERTY(transformResult)
WCDB_PROPERTY(stype)
WCDB_PROPERTY(msg)
WCDB_PROPERTY(thumb)
WCDB_PROPERTY(gif)
WCDB_PROPERTY(size)
WCDB_PROPERTY(md5)
WCDB_PROPERTY(width)
WCDB_PROPERTY(height)
WCDB_PROPERTY(productid)
WCDB_PROPERTY(designerid)
WCDB_PROPERTY(exttype)
WCDB_PROPERTY(content)
WCDB_PROPERTY(animation)
WCDB_PROPERTY(dim)
WCDB_PROPERTY(fileUuid)
WCDB_PROPERTY(chatLogTitle)
WCDB_PROPERTY(contentArray)
WCDB_PROPERTY(languageType)
WCDB_PROPERTY(roomName)
WCDB_PROPERTY(imgType)

@end
