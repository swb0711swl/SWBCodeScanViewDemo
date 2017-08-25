//
//  SWBQRCodeScanView.h
//  SWBQRCodeScanDemo
//
//  Created by 工作 on 17/8/17.
//  Copyright © 2017年 万恶的小彬彬. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface SWBQRCodeScanView : UIView

@property (strong, nonatomic) RACSubject *delegateSubject;

@end
