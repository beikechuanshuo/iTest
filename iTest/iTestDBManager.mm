//
//  iTestDBManager.m
//  iTest
//
//  Created by liyanjun on 2018/1/4.
//  Copyright © 2018年 liyanjun. All rights reserved.
//

#import "iTestDBManager.h"
#import <WCDB/WCDB.h>
#include "sqlite3.h"
#include <iostream>
#include <string>
#include <sstream>
#include <time.h>

@interface iTestDBManager()

@property (nonatomic, strong) WCTDatabase *database;

@property (nonatomic, strong) dispatch_queue_t readQueue;

@property (nonatomic, strong) dispatch_queue_t writeQueue;

@property (nonatomic, strong) dispatch_queue_t callbackQueue;

@end

@implementation iTestDBManager

+ (instancetype)sharedDBManager
{
    static iTestDBManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[iTestDBManager alloc] init];
        
//        [WCTStatistics SetGlobalSQLTrace:^(NSString *sql) {
//            NSLog(@"WCDB SQL : %@", sql);
//        }];
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentDirectory = [paths objectAtIndex:0];
        NSString *dbPath = [documentDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"liyanjun.db"]];
        WCTDatabase *database = [[WCTDatabase alloc] initWithPath:dbPath];
        manager.database = database;
        
        manager.readQueue = dispatch_queue_create("Hotchat_WCDB_Read_Queue", DISPATCH_QUEUE_CONCURRENT);
        
        manager.writeQueue = dispatch_queue_create("Hotchat_WCDB_Write_Queue", NULL);
        
        manager.callbackQueue = dispatch_get_main_queue();
        
        [manager creatTable];
    });
    
    return manager;
}

- (void)creatTable
{
    if ([self.database canOpen] && [self.database isOpened])
    {
        BOOL result = [self.database createTableAndIndexesOfName:@"AllMessage"
                                                       withClass:iTestModel.class];
        NSLog(@"%d",result);
    }
}

- (void)testWriteModel
{
    for (NSInteger j = 0; j < 250; j++)
    {
        NSMutableArray *array = [NSMutableArray array];
        
        NSMutableArray *commonArray = [NSMutableArray array];
        for (NSInteger i = 0; i<1000; i++)
        {
            iTestModel *model = [[iTestModel alloc] init];
            model.iType = @"txt";
            model.db_id = 2;
            model.time = @"2017-12-19 15:57:38:5060";
            model.ownerJIDStr = @"1297437964";
            model.roomJIDStr = [NSString stringWithFormat:@"8825%03ld",(long)j];
            model.body = @"网络抖动 如果老出现的话  可以找下IT";
            model.fromJIDStr = @"1238480378";
            model.groupID = @(i);
            model.messageID = [NSString stringWithFormat:@"49d1b5fa1606dc72f4a212d39b5a6ae5a189%04ld_%03ld",(long)i,(long)j];
            model.type = @"groupchat";
            model.needTimeStamp = @(1);
            model.isSend = @(1);
            model.isFromMe = @(0);
            model.isSync = @(0);
            model.isDelete = @(0);
            model.isRevoke = @(0);
            model.isRead = @(1);
            model.isHaveReceipt = @(0);
            model.isMute = @(0);
            model.videoFileSize = @(0);
            model.contentArray = @[];
            model.animation = @(0);
            
            [array addObject:model];
            
            HMessageCommonModel *commonModel = [[HMessageCommonModel alloc] init];
            commonModel.db_id = 2;
            commonModel.roomJIDStr = model.roomJIDStr;
            commonModel.messageID = model.messageID;
            commonModel.groupID = model.groupID;
            [commonArray addObject:commonModel];
        }
        
        if (![self.database isTableExists:[NSString stringWithFormat:@"CommonTable8825%03ld",j]])
        {
            [self.database createTableAndIndexesOfName:[NSString stringWithFormat:@"CommonTable8825%03ld",j] withClass:HMessageCommonModel.class];
        }
      
        [self.database insertObjects:commonArray into:[NSString stringWithFormat:@"CommonTable8825%03ld",j]];
        
        [self.database insertObjects:array into:@"AllMessage"];
    }
   
    NSLog(@"insertInto end");
}

- (void)testReadModel
{
        NSLog(@"Read beginTime:%@",[NSDate date]);
        [self.database runTransaction:^BOOL{
            NSArray *modelArray = [self.database getObjectsOfClass:[iTestModel class] fromTable:@"AllMessage" where:(iTestModel.groupID > @500 && iTestModel.roomJIDStr == "8825240") orderBy:iTestModel.messageID.order(WCTOrderedDescending) limit:16];
            
            NSLog(@"modelArray: %d",modelArray.count);
            NSLog(@"%@",modelArray);
            return YES;
        }];
        NSLog(@"Read Time:%@",[NSDate date]);
}

- (void)testReadModel1
{
    NSLog(@"Read beginTime:%@",[NSDate date]);
    [self.database runTransaction:^BOOL{
        
        //           NSArray *temArray = [self.database getAllObjectsOfClass:[iTestModel class] fromTable:@"AllMessage"];
        
        NSArray *modelArray = [self.database getObjectsOfClass:[HMessageCommonModel class] fromTable:[NSString stringWithFormat:@"CommonTable8825240"] where:(HMessageCommonModel.groupID > @500) orderBy:HMessageCommonModel.messageID.order(WCTOrderedDescending) limit:16];
        
        NSMutableArray *array = [NSMutableArray array];
        for (HMessageCommonModel *commonModel in modelArray)
        {
           iTestModel *model = [self.database getOneObjectOfClass:[iTestModel class] fromTable:@"AllMessage" where:iTestModel.messageID == commonModel.messageID];
            [array addObject:model];
        }
        
        NSLog(@"modelArray: %d",array.count);
        
        NSLog(@"%@",array);
        
        return YES;
    }];
    NSLog(@"Read Time:%@",[NSDate date]);
    
//    dispatch_async(self.readQueue, ^{
//        NSLog(@"Read1 beginTime:%@",[NSDate date]);
//
//        NSArray *modelArray = [self.database getObjectsOfClass:iTestModel.class fromTable:@"AllMessage" where:(iTestModel.roomJIDStr==("882503") && iTestModel.isDelete!=("1") && iTestModel.time<("2018-01-05 15:11:45:3830")) orderBy:{iTestModel.time.order(WCTOrderedDescending),iTestModel.groupID.order(WCTOrderedDescending)} limit:16];
//        NSLog(@"Read1 endTime:%@ modelCount:%ld",[NSDate date],modelArray.count);
//
//        NSLog(@"Read1 endTime:%@",modelArray);
//
//    });
}

- (void)testReadModel2
{
    dispatch_async(self.readQueue, ^{
        NSLog(@"Read2 beginTime:%@",[NSDate date]);
        
        NSArray *modelArray = [self.database getObjectsOfClass:iTestModel.class fromTable:@"AllMessage" where:iTestModel.messageID.operator==("49d1b5fa1606dc72f4a212d39b5a6ae5a189")];
        NSLog(@"Read2 endTime:%@ modelCount:%ld",[NSDate date],modelArray.count);
    });
}

- (void)testReadModel3
{
    dispatch_async(self.readQueue, ^{
        NSString *messageID = [self.database getOneValueOnResult:iTestModel.messageID fromTable:@"AllMessage" where:iTestModel.messageID.operator==("49d1b5fa1606dc72f4a212d39b5a6ae5a189")];
        NSLog(@"Read3 endTime:%@ modelCount:%ld",[NSDate date],messageID.integerValue);
    });
}

- (void)testDelete
{
//    WCTRowSelect *select = [self.database prepareSelectRowsOnResults:{iTestModel.db_id} fromTable:@"AllMessage"];
//    NSArray *array = select.allValues;
//    NSLog(@"testDelete End Time:%@",array);
//
    
//    WCTSelect *select1 = [[self.database prepareSelectObjectsOnResults:iTestModel.db_id fromTable:@"AllMessage"] groupBy:{iTestModel.roomJIDStr}];
//    NSArray *array0 = select1.allObjects;
//    NSLog(@"testDelete End Time:%@",array0);
//    WCTSelect *select2 = [[self.database prepareSelectObjectsOnResults:iTestModel.db_id.max() fromTable:@"AllMessage"] groupBy:{iTestModel.roomJIDStr}];
//    NSArray *array2 = select2.allObjects;
//    BOOL flag = [self.database deleteObjectsFromTable:@"AllMessage" where:iTestModel.db_id.notIn({select2})];
//    NSLog(@"testDelete End Time:%@",array2);
    
//     [self.database updateRowsInTable:@"AllMessage" onProperties:{iTestModel.db_id,iTestModel.messageID,iTestModel.iType} withRow:@[@3,@"49d1b5fa1606dc72f4a212d39b5a6ae5a189",@"text"] where:iTestModel.messageID==("49d1b5fa1606dc72f4a212d39b5a6ae5a189")];
//    NSLog(@"testDelete End Time:%@",array2);
//
    [self.database updateRowsInTable:@"AllMessage" onProperties:{iTestModel.db_id,iTestModel.messageID,iTestModel.iType} withRow:@[@3,@"49d1b5fa1606dc72f4a212d39b5a6ae5a189",@"text"] where:iTestModel.messageID==("49d1b5fa1606dc72f4a212d39b5a6ae5a189")];
    
    
    NSNumber *count = [self.database getOneValueOnResult:iTestModel.messageID.count() fromTable:@"AllMessage" where:iTestModel.db_id > 0];
    
    WCTColumnsXRows *rows = [self.database getRowsOnResults:iTestModel.messageID.count() fromTable:@"AllMessage" where:iTestModel.db_id > @0];
    NSLog(@"%d",rows.count);
    
    NSNumber *tem = [self.database getOneValueOnResult:iTestModel.messageID.count() fromTable:@"AllMessage" where:iTestModel.db_id > @0];
    
    NSString *searchKey = @"ok";
    WCTResultList resultList = WCTResultList(iTestModel.AllProperties);
    
    NSString *string = [NSString stringWithFormat:@"AllMessage"];
    
    const char *cString = [string cStringUsingEncoding:NSUTF8StringEncoding];
    
//    WCDB::StatementSelect statementSelect = WCDB::StatementSelect().select(resultList).from([string cStringUsingEncoding:NSUTF8StringEncoding]);
//
//    WCTError *error;
//    WCTStatement *statement = [self.database prepare:statementSelect withError:&error];
//
//    while (statement.step)
//    {
//        NSLog(@"11111");
//    };
    
//    WCTSelect *select4 = [self.database prepareSelectObjectsOfClass:iTestModel.class fromTable:@"AllMessage"];
//
//    WCTExpr expr = WCTExpr(select4);
//
//    expr.Case(expr, {{iTestModel.messageID.like([NSString stringWithFormat:@"49d1b5fa1606dc72f4a212d39b5a6ae5a189"], "\\"),14},{iTestModel.messageID.like([NSString stringWithFormat:@"49d1b5fa1606dc72f4a212d"], "\\"),13}}, {0});
//
    
    
//    [NSString stringWithFormat:@"select * from (select *, case when jianpin like '%@' escape '\\' then 14 else 0 end + case when quanpin like '%@' escape '\\' then 13 else 0 end + case when enname like '%@' escape '\\' then 10 else 0 end + case when chname like '%@' escape '\\' then 12 else 0 end + case when remark like '%@' escape '\\' then 11 else 0 end as cnt from AllUserInfo) AllUserInfo where cnt > 0 and type = 'normal' and isleave != 1 UNION select * from (select *, case when jianpin like '%%%@%%' escape '\\' then 5 else 0 end + case when quanpin like '%%%@%%' escape '\\' then 4 else 0 end + case when enname like '%%%@%%' escape '\\' then 1 else 0 end + case when chname like '%%%@%%' escape '\\' then 3 else 0 end + case when remark like '%%%@%%' escape '\\' then 2 else 0 end as cnt from AllUserInfo) AllUserInfo where cnt > 0 and type = 'normal' and isleave != 1 order by cnt desc",searchKey,searchKey,searchKey,searchKey,searchKey,searchKey,searchKey,searchKey,searchKey,searchKey];
    
}
@end

