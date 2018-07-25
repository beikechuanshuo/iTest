//
//  TestViewController.m
//  iTest
//
//  Created by liyanjun on 2018/3/14.
//  Copyright © 2018年 liyanjun. All rights reserved.
//

#import "TestViewController.h"

@interface TestViewController ()

@end

@implementation TestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor redColor];

    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(50, 50, 100, 40)];
    [btn setTitle:@"返回" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    btn.backgroundColor = [UIColor lightGrayColor];
    [btn addTarget:self action:@selector(backTest:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)backTest:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

@end
