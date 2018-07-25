//
//  iTestDBManager.h
//  iTest
//
//  Created by liyanjun on 2018/1/4.
//  Copyright © 2018年 liyanjun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "iTestModel.h"
#import "iTestModel+WCTTableCoding.h"
#import "HMessageCommonModel.h"
#import "HMessageCommonModel+WCTTableCoding.h"

@interface iTestDBManager : NSObject

+ (instancetype)sharedDBManager;

- (void)testWriteModel;

- (void)testReadModel;

- (void)testReadModel1;

- (void)testReadModel2;

- (void)testReadModel3;

- (void)testDelete;

@end
