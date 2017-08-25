//
//  ViewController.m
//  SWBQRCodeScanDemo
//
//  Created by 工作 on 17/8/17.
//  Copyright © 2017年 万恶的小彬彬. All rights reserved.
//

#import "ViewController.h"

#import "SWBQRCodeScanView.h"
#import <Masonry/Masonry.h>

@interface ViewController ()

@property (strong, nonatomic) SWBQRCodeScanView *scanView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.scanView = [[SWBQRCodeScanView alloc]init];
    self.scanView.delegateSubject = [RACSubject subject];
    [self.scanView.delegateSubject subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
    [self.view addSubview:self.scanView];
    [self.scanView mas_makeConstraints:^(MASConstraintMaker *make) {
        //self->weakSelf
        make.edges.equalTo(self.view);
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
