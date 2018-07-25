//
//  HMessageCommonModel+WCTTableCoding.h
//  reliao
//
//  Created by liyanjun on 2018/4/2.
//  Copyright © 2018年 iH. All rights reserved.
//

#import "HMessageCommonModel.h"
#import <WCDB/WCDB.h>

@interface HMessageCommonModel (WCTTableCoding) <WCTTableCoding>

WCDB_PROPERTY(db_id)
WCDB_PROPERTY(roomJIDStr)
WCDB_PROPERTY(fromJIDStr)
WCDB_PROPERTY(groupID)
WCDB_PROPERTY(messageID)
WCDB_PROPERTY(type)
WCDB_PROPERTY(time)
WCDB_PROPERTY(timeStamp)
WCDB_PROPERTY(isSend)
WCDB_PROPERTY(isFromMe)
WCDB_PROPERTY(isSync)
WCDB_PROPERTY(isDelete)
WCDB_PROPERTY(isRevoke)
WCDB_PROPERTY(isRead)
WCDB_PROPERTY(iType)
WCDB_PROPERTY(needTimeStamp)
WCDB_PROPERTY(isMute)
WCDB_PROPERTY(isReceipt)
WCDB_PROPERTY(isHaveReceipt)
WCDB_PROPERTY(unReceiveNumber)
WCDB_PROPERTY(unWatchNumber)
WCDB_PROPERTY(watchedNumber)
WCDB_PROPERTY(unReceiveArray)
WCDB_PROPERTY(unWatchArray)
WCDB_PROPERTY(watchedArray)
WCDB_PROPERTY(noChangeOrder)

@end
