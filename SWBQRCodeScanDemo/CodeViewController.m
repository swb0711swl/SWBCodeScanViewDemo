//
//  CodeViewController.m
//  SWBQRCodeScanDemo
//
//  Created by 工作 on 17/8/24.
//  Copyright © 2017年 万恶的小彬彬. All rights reserved.
//

#import "CodeViewController.h"
#import <Masonry/Masonry.h>
#import "UIImage+QRCode.h"

@interface CodeViewController ()

@end

@implementation CodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setTitle:@"返回" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor brownColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    [btn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(20);
        make.left.equalTo(self.view).offset(0);
        make.size.mas_equalTo(CGSizeMake(60, 44));
    }];
    
    UIImageView *imgView = [[UIImageView alloc]init];
    [self.view addSubview:imgView];
    [imgView mas_makeConstraints:^(MASConstraintMaker *make) {
        //self->weakSelf
        make.center.mas_equalTo(self.view);
        make.size.mas_equalTo(CGSizeMake(240, 240));
    }];
    
    imgView.image = [UIImage qrImageByContent:@"万恶的小彬彬"];
}

- (void)backAction
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
