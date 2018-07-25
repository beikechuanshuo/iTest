//
//  HMessageCommonModel.mm
//  reliao
//
//  Created by liyanjun on 2018/4/2.
//  Copyright © 2018年 liyanjun. All rights reserved.
//

#import "HMessageCommonModel+WCTTableCoding.h"
#import "HMessageCommonModel.h"
#import <WCDB/WCDB.h>

@implementation HMessageCommonModel

WCDB_IMPLEMENTATION(HMessageCommonModel)

WCDB_SYNTHESIZE(HMessageCommonModel, db_id)
WCDB_SYNTHESIZE_DEFAULT(HMessageCommonModel, roomJIDStr,@"")
WCDB_SYNTHESIZE_DEFAULT(HMessageCommonModel, fromJIDStr,@"")
WCDB_SYNTHESIZE_DEFAULT(HMessageCommonModel, groupID,@0)
WCDB_SYNTHESIZE_DEFAULT(HMessageCommonModel, messageID,@"")
WCDB_SYNTHESIZE_DEFAULT(HMessageCommonModel, type,@"")
WCDB_SYNTHESIZE_DEFAULT(HMessageCommonModel, time,@"")
WCDB_SYNTHESIZE_DEFAULT(HMessageCommonModel, timeStamp,@0)
WCDB_SYNTHESIZE_COLUMN_DEFAULT(HMessageCommonModel, isSend,"issend",@0)
WCDB_SYNTHESIZE_COLUMN_DEFAULT(HMessageCommonModel, isFromMe,"isfromme",@0)
WCDB_SYNTHESIZE_COLUMN_DEFAULT(HMessageCommonModel, isSync,"issync",@0)
WCDB_SYNTHESIZE_COLUMN_DEFAULT(HMessageCommonModel, isDelete,"isdelete",@0)
WCDB_SYNTHESIZE_COLUMN_DEFAULT(HMessageCommonModel, isRevoke,"isrevoke",@0)
WCDB_SYNTHESIZE_COLUMN_DEFAULT(HMessageCommonModel, isRead,"isread",@0)
WCDB_SYNTHESIZE_COLUMN_DEFAULT(HMessageCommonModel, iType,"itype",@"")
WCDB_SYNTHESIZE_COLUMN_DEFAULT(HMessageCommonModel, needTimeStamp,"needtimestamp",@0)
WCDB_SYNTHESIZE_COLUMN_DEFAULT(HMessageCommonModel, isMute,"ismute",@"")
WCDB_SYNTHESIZE_COLUMN_DEFAULT(HMessageCommonModel, isReceipt,"isreceipt",@0)
WCDB_SYNTHESIZE_COLUMN_DEFAULT(HMessageCommonModel, isHaveReceipt,"ishavereceipt",@0)
WCDB_SYNTHESIZE_COLUMN_DEFAULT(HMessageCommonModel, unReceiveNumber,"unreceivenumber",@0)
WCDB_SYNTHESIZE_COLUMN_DEFAULT(HMessageCommonModel, unReceiveArray,"unreceivearray",@"")
WCDB_SYNTHESIZE_COLUMN_DEFAULT(HMessageCommonModel, unWatchNumber,"unwatcnumber",@0)
WCDB_SYNTHESIZE_COLUMN_DEFAULT(HMessageCommonModel, unWatchArray,"unwatcharray",@"")
WCDB_SYNTHESIZE_COLUMN_DEFAULT(HMessageCommonModel, watchedArray,"watchedarray",@"")
WCDB_SYNTHESIZE_COLUMN_DEFAULT(HMessageCommonModel, watchedNumber,"watchednumber",@0)
WCDB_SYNTHESIZE_COLUMN_DEFAULT(HMessageCommonModel, noChangeOrder,"nochangeorder",@0)

WCDB_UNIQUE_INDEX(HMessageCommonModel, "MessageID_Index", messageID)

WCDB_NOT_NULL(HMessageCommonModel, roomJIDStr)
WCDB_NOT_NULL(HMessageCommonModel, fromJIDStr)
WCDB_NOT_NULL(HMessageCommonModel, messageID)
WCDB_NOT_NULL(HMessageCommonModel, type)
WCDB_NOT_NULL(HMessageCommonModel, time)
WCDB_NOT_NULL(HMessageCommonModel, iType)
WCDB_NOT_NULL(HMessageCommonModel, isMute)

- (NSString *)roomJIDStr
{
    return _roomJIDStr == nil ? @"" :([_roomJIDStr isKindOfClass:[NSString class]] ? _roomJIDStr :[NSString stringWithFormat:@"%@",_roomJIDStr]);
}

- (NSString *)fromJIDStr
{
    return _fromJIDStr == nil ? @"" :([_fromJIDStr isKindOfClass:[NSString class]] ? _fromJIDStr :[NSString stringWithFormat:@"%@",_fromJIDStr]);
}

- (NSNumber *)groupID
{
    return _groupID == nil ? @0 :([_groupID isKindOfClass:[NSNumber class]] ? _groupID :@0);
}

- (NSString *)messageID
{
    return _messageID == nil ? @"" :([_messageID isKindOfClass:[NSString class]] ? _messageID :[NSString stringWithFormat:@"%@",_messageID]);
}

- (NSString *)type
{
    return _type == nil ? @"" :([_type isKindOfClass:[NSString class]] ? _type :[NSString stringWithFormat:@"%@",_type]);
}

- (NSString *)time
{
    return _time == nil ? @"" :([_time isKindOfClass:[NSString class]] ? _time :[NSString stringWithFormat:@"%@",_time]);
}

- (NSNumber *)timeStamp
{
    return _timeStamp == nil ? @0 :([_timeStamp isKindOfClass:[NSNumber class]] ? _timeStamp :@0);
}

- (NSNumber *)isSend
{
    return _isSend == nil ? @0 :([_isSend isKindOfClass:[NSNumber class]] ? _isSend :@0);
}
- (NSNumber *)isFromMe
{
    return _isFromMe == nil ? @0 :([_isFromMe isKindOfClass:[NSNumber class]] ? _isFromMe :@0);
}
- (NSNumber *)isSync
{
    return _isSync == nil ? @0 :([_isSync isKindOfClass:[NSNumber class]] ? _isSync :@0);
}
- (NSNumber *)isDelete
{
    return _isDelete == nil ? @0 :([_isDelete isKindOfClass:[NSNumber class]] ? _isDelete :@0);
}
- (NSNumber *)isRevoke
{
    return _isRevoke == nil ? @0 :([_isRevoke isKindOfClass:[NSNumber class]] ? _isRevoke :@0);
}


- (NSNumber *)isRead
{
    return _isRead == nil ? @0 :([_isRead isKindOfClass:[NSNumber class]] ? _isRead :@0);
}

- (NSString *)iType
{
    return _iType == nil ? @"" :([_iType isKindOfClass:[NSString class]] ? _iType :[NSString stringWithFormat:@"%@",_iType]);
}

- (NSNumber *)needTimeStamp
{
    return _needTimeStamp == nil ? @0 :([_needTimeStamp isKindOfClass:[NSNumber class]] ? _needTimeStamp :@0);
}

- (NSNumber *)isMute
{
    return _isMute == nil ? @0 :([_isMute isKindOfClass:[NSNumber class]] ? _isMute :@0);
}

- (NSNumber *)isReceipt
{
    return _isReceipt == nil ? @0 :([_isReceipt isKindOfClass:[NSNumber class]] ? _isReceipt :@0);
}

- (NSNumber *)isHaveReceipt
{
    return _isHaveReceipt == nil ? @0 :([_isHaveReceipt isKindOfClass:[NSNumber class]] ? _isHaveReceipt :@0);
}

- (NSNumber *)unReceiveNumber
{
    return _unReceiveNumber == nil ? @0 :([_unReceiveNumber isKindOfClass:[NSNumber class]] ? _unReceiveNumber :@0);
}

- (NSNumber *)unWatchNumber
{
    return _unWatchNumber == nil ? @0 :([_unWatchNumber isKindOfClass:[NSNumber class]] ? _unWatchNumber :@0);
}

- (NSNumber *)watchedNumber
{
    return _watchedNumber == nil ? @0 :([_watchedNumber isKindOfClass:[NSNumber class]] ? _watchedNumber :@0);
}


- (NSString *)unReceiveArray
{
    return _unReceiveArray == nil ? @"" :([_unReceiveArray isKindOfClass:[NSString class]] ? _unReceiveArray :[NSString stringWithFormat:@"%@",_unReceiveArray]);
    
}

- (NSString *)unWatchArray
{
    return _unWatchArray == nil ? @"" :([_unWatchArray isKindOfClass:[NSString class]] ? _unWatchArray :[NSString stringWithFormat:@"%@",_unWatchArray]);
    
}

- (NSString *)watchedArray
{
    return _watchedArray == nil ? @"" :([_watchedArray isKindOfClass:[NSString class]] ? _watchedArray :[NSString stringWithFormat:@"%@",_watchedArray]);
}


- (NSNumber *)noChangeOrder
{
    return _noChangeOrder == nil ? @0 :([_noChangeOrder isKindOfClass:[NSNumber class]] ? _noChangeOrder :@0);
    
}

@end
