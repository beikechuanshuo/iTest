//
//  ViewController.m
//  iTest
//
//  Created by liyanjun on 2018/1/4.
//  Copyright © 2018年 liyanjun. All rights reserved.
//

#import "ViewController.h"
#import "iTestModel.h"
#import "iTestDBManager.h"
#import "AppDelegate.h"
#import "TestViewController.h"
#import "HNewRecordingViewController.h"

@interface ViewController ()<HNewRecordingViewControllerDelegate,CAAnimationDelegate>

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(50, 50, 100, 40)];
    [btn setTitle:@"数据库写入" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    btn.backgroundColor = [UIColor lightGrayColor];
    [btn addTarget:self action:@selector(writeDataTest:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    
    UIButton *btn1 = [[UIButton alloc] initWithFrame:CGRectMake(180, 50, 100, 40)];
    btn1.backgroundColor = [UIColor lightGrayColor];
    [btn1 setTitle:@"数据库读取" forState:UIControlStateNormal];
    [btn1 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn1 addTarget:self action:@selector(readDataTest:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn1];
    
    UIButton *btn2 = [[UIButton alloc] initWithFrame:CGRectMake(50, 100, 100, 40)];
    btn2.backgroundColor = [UIColor lightGrayColor];
    [btn2 setTitle:@"数据库操作" forState:UIControlStateNormal];
    [btn2 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn2 addTarget:self action:@selector(dbTest:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn2];
    
    UIButton *btn3 = [[UIButton alloc] initWithFrame:CGRectMake(180, 100, 100, 40)];
    btn3.backgroundColor = [UIColor lightGrayColor];
    [btn3 setTitle:@"测试" forState:UIControlStateNormal];
    [btn3 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn3 addTarget:self action:@selector(test:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn3];
    
    UIButton *btn4 = [[UIButton alloc] initWithFrame:CGRectMake(50, 150, 100, 40)];
    btn4.backgroundColor = [UIColor lightGrayColor];
    [btn4 setTitle:@"小视频录制" forState:UIControlStateNormal];
    [btn4 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn4 addTarget:self action:@selector(videoRecording:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn4];
    
    UITextView *textview = [[UITextView alloc] initWithFrame:CGRectMake(50, 210, 200, 45) textContainer:nil];
    textview.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:textview];
    
    NSString *totalString = @" 1  2     3 4 ";
    NSArray *array = [totalString componentsSeparatedByString:@" "];
    NSLog(@"%@",array);
    NSMutableArray *keysArray = [NSMutableArray array];
    for (NSString *temString in array)
    {
        if (temString.length > 0 && ![temString isEqualToString:@" "])
        {
            NSLog(@"111:%@\n",temString);
            [keysArray addObject:temString];
        }
    }
    
    //动画
    CABasicAnimation *boundsAnimation = [CABasicAnimation animationWithKeyPath:@"bounds"];
    boundsAnimation.fromValue = [NSValue valueWithCGRect: btn.bounds];
    boundsAnimation.toValue = [NSValue valueWithCGRect:CGRectMake(0, 0, 150, 60)];
    
    CABasicAnimation *animation  = [CABasicAnimation animationWithKeyPath:@"position"];
    animation.fromValue =  [NSValue valueWithCGPoint:CGPointMake(50+100/2, 50+40/2)];
    CGPoint toPoint = CGPointMake(85, 100);
    animation.toValue = [NSValue valueWithCGPoint:toPoint];
    
    CAAnimationGroup *animationGroup = [CAAnimationGroup animation];
    animationGroup.duration = 2.0f;
    animationGroup.autoreverses = NO;
    animationGroup.fillMode = kCAFillModeForwards;
    animationGroup.removedOnCompletion = NO;
    animationGroup.repeatCount = 1;
    [animationGroup setAnimations:[NSArray arrayWithObjects:boundsAnimation, animation, nil]];
    animationGroup.delegate = self;
    [btn.layer addAnimation:animationGroup forKey:@"animationGroup"];
    
    //多关键字搜索群名相同的群或邮件组
    NSMutableString *partString = [NSMutableString string];
    NSMutableString *allString = [NSMutableString string];
    for (NSString *string in keysArray)
    {
        NSInteger index = [keysArray indexOfObject:string];
        NSString *searchKey = [NSString stringWithFormat:@"%@",keysArray[index]];
        searchKey = [searchKey stringByReplacingOccurrencesOfString:@"_" withString:@"\\_"];
        searchKey = [searchKey stringByReplacingOccurrencesOfString:@"%" withString:@"\\%"];
        searchKey = [searchKey stringByReplacingOccurrencesOfString:@"," withString:@"\\"];
        
        [allString appendFormat:@"like '%@' ",searchKey];
        if (index != keysArray.count-1)
        {
            [allString appendFormat:@"and "];
        }
        
        [partString appendFormat:@"like '%%%@%%' ",searchKey];
        if (index != keysArray.count-1)
        {
            [partString appendFormat:@"and "];
        }
    }
    
    //完全匹配及模糊匹配
    NSString *sqlGroup = [NSString stringWithFormat:@"select * from (select *, case when jianpin %@ escape '\\' then 13 else 0 end + case when groupname %@ escape '\\' then 12 else 0 end + case when quanpin %@ escape '\\' then 11 else 0 end as cnt from AllGroupInfo) AllGroupInfo where cnt > 0 UNION select * from (select *, case when jianpin %@ escape '\\' then 3 else 0 end + case when groupname %@ escape '\\' then 2 else 0 end + case when quanpin %@ escape '\\' then 1 else 0 end as cnt from AllGroupInfo) AllGroupInfo where cnt > 0 order by cnt desc",allString,allString,allString,partString,partString,partString];

    NSLog(@"%@",sqlGroup);
    
    
    NSArray *colorArr = @[@"黑",@"红",@"梅",@"方"];
    
    NSArray *numArr   = @[@"2",@"A",@"K",@"Q",@"J",@"10",@"9",@"8",@"7",@"6",@"5",@"4",@"3"];
    
    
    
    //组合54张牌，先是大小王
    
    NSMutableArray *allPokerArr = [NSMutableArray arrayWithArray:@[@"大王",@"小王"]];
    
    for (NSString *numStr in numArr) {//组合不同花色不同数字的牌
        
        for (NSString *colorStr in colorArr) {
            
            NSString *newStr = [colorStr stringByAppendingString:numStr];
            
            [allPokerArr addObject:newStr];
            
        }
        
    }
    
    
    //随机打乱这54张牌
    NSArray *mixArr = [allPokerArr sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        
        int seed = arc4random_uniform(2);
        
        if (seed) {
            
            return [obj1 compare:obj2];
            
        } else {
            
            return [obj2 compare:obj1];
            
        }
        
    }];
    
    
    //随便构造一个范围，取出混合后的54张牌中的这个范围内的17张牌
    
    NSRange range = NSMakeRange(10, 17);
    
    NSArray *newArr = [mixArr subarrayWithRange:range];
    
    //排序这17张牌
    NSMutableArray *resultArr = [NSMutableArray arrayWithArray:allPokerArr];
    
    for (NSString *str in allPokerArr) {
        
        if (![newArr containsObject:str]) {
            
            [resultArr removeObject:str];
        }
    }
    
    NSLog(@"resultArray:%@",resultArr);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)writeDataTest:(id)sender
{
    [[iTestDBManager sharedDBManager] testWriteModel];
}

- (void)readDataTest:(id)sender
{
    [[iTestDBManager sharedDBManager] testReadModel];

//    [[iTestDBManager sharedDBManager] testDelete];
//
//    [[iTestDBManager sharedDBManager] testReadModel2];
//
//    [[iTestDBManager sharedDBManager] testReadModel3];
//
//    [[iTestDBManager sharedDBManager] testReadModel3];
//
    [[iTestDBManager sharedDBManager] testReadModel1];
//
//    [[iTestDBManager sharedDBManager] testReadModel2];
    
    NSLog(@"Read Finish !");
}

- (void)dbTest:(id)sender
{
    [[iTestDBManager sharedDBManager] testDelete];
}

- (void)test:(id)sender
{
    TestViewController *testVC = [[TestViewController alloc] init];
    [self presentViewController:testVC animated:YES completion:nil];
}

- (void)videoRecording:(id)sender
{
    HNewRecordingViewController *vc = [[HNewRecordingViewController alloc] init];
    vc.recordDelegate = self;

    [self presentViewController:vc animated:YES completion:nil];
}

#pragma mark - HNewRecordingViewControllerDelegate
- (void)recordingViewDidEndRecordWithInfo:(NSDictionary *)recordInfo
{
    NSLog(@"%@",recordInfo);
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    NSLog(@"1111");
}

@end
