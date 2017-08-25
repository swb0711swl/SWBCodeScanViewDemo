//
//  SWBQRCodeScanView.m
//  SWBQRCodeScanDemo
//
//  Created by 工作 on 17/8/17.
//  Copyright © 2017年 万恶的小彬彬. All rights reserved.
//

#import "SWBQRCodeScanView.h"
#import <AVFoundation/AVFoundation.h>
#import <Masonry/Masonry.h>
#import "AppDelegate.h"
#import "UIImage+QRCode.h"
#import "CodeViewController.h"

#pragma mark- 快速定义一个weakSelf和strongSelf
#define WeakObj(o) autoreleasepool{} __weak typeof(o) o##Weak = o;
#define StrongObj(o) autoreleasepool{} __strong typeof(o) o = o##Weak;

#pragma mark- 全局Delegate
#define appDelegate ((AppDelegate *)([UIApplication sharedApplication].delegate))

#define CodeScanWidth 270   //扫描区域的宽度
#define CodeScanHeight 270  //扫描区域的高度

#define SCREEN_WIDTH ([UIScreen mainScreen].bounds.size.width)      //屏幕宽
#define SCREEN_HEIGHT ([UIScreen mainScreen].bounds.size.height)    //屏幕高

@interface SWBQRCodeScanView()<AVCaptureMetadataOutputObjectsDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property (strong, nonatomic) AVCaptureDevice *myDevice;  //创建相机
@property (strong, nonatomic) AVCaptureDeviceInput *deviceInput;    //输入流
@property (strong, nonatomic) AVCaptureMetadataOutput *metadataOutput;  //媒体输出流
@property (strong, nonatomic) AVCaptureSession *session;    //捕捉会话
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *previewLayer; //预览层

@property (strong, nonatomic) UIImageView *lineImgView; //扫描线条
@property (strong, nonatomic) UIImageView *scanImgView; //扫描框

@property (assign, nonatomic) BOOL isScanStop;

@end

@implementation SWBQRCodeScanView

//代码创建
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.isScanStop = NO;
        [self initUI];
        [self captureDevice];
    }
    return self;
}

//从xib创建
- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.isScanStop = NO;
        [self initUI];
        [self captureDevice];
    }
    return self;
}

- (void)initUI
{
    //扫码框
    self.scanImgView = [[UIImageView alloc]init];
    self.scanImgView.userInteractionEnabled = YES;
    self.scanImgView.image = [UIImage imageNamed:@"code_frame"];
    [self addSubview:self.scanImgView];
    [self.scanImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(self.center);
        make.size.mas_equalTo(CGSizeMake(CodeScanWidth, CodeScanHeight));
    }];
    
    //扫描线条
    self.lineImgView = [[UIImageView alloc]init];
    self.lineImgView.image = [UIImage imageNamed:@"code_line"];
    [self addSubview:self.lineImgView];
    @WeakObj(self);
    [self.lineImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        @StrongObj(self);
        make.top.equalTo(self.scanImgView).offset(2);
        make.left.equalTo(self.scanImgView).offset(10);
        make.right.equalTo(self.scanImgView).offset(-2);
        make.height.equalTo(@2);
    }];
    
    //添加手势，点击扫描框打开手电筒
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]init];
    [tap.rac_gestureSignal subscribeNext:^(id x) {
        @StrongObj(self);
        [self openFlashLamp];
    }];
    [self.scanImgView addGestureRecognizer:tap];
    
    //提示文字
    UILabel *lb = [[UILabel alloc]init];
    lb.text = @"将二维码/条形码放入框内，即可自动扫描";
    lb.textAlignment = NSTextAlignmentCenter;
    lb.font = [UIFont systemFontOfSize:13];
    lb.textColor = [UIColor whiteColor];
    lb.backgroundColor = [UIColor clearColor];
    [self addSubview:lb];
    [lb mas_makeConstraints:^(MASConstraintMaker *make) {
        @StrongObj(self);
        make.top.equalTo(self.scanImgView.mas_bottom).offset(5);
        make.left.equalTo(self).offset(10);
        make.right.equalTo(self).offset(-10);
        make.height.equalTo(@15);
    }];
    
    UIButton *photoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [photoBtn setTitle:@"相册" forState:UIControlStateNormal];
    [photoBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self addSubview:photoBtn];
    [photoBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        @StrongObj(self);
        make.bottom.equalTo(self).offset(-10);
        make.left.equalTo(self).offset(10);
        make.size.mas_equalTo(CGSizeMake(100, 50));
    }];
    
    UIButton *codeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [codeBtn setTitle:@"我的二维码" forState:UIControlStateNormal];
    [codeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self addSubview:codeBtn];
    [codeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        @StrongObj(self);
        make.bottom.equalTo(photoBtn);
        make.right.equalTo(self).offset(-10);
        make.size.mas_equalTo(photoBtn);
    }];
    
    [[photoBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
        @StrongObj(self);
        //打开相册
        [self photo];
    }];
    [[codeBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
        @StrongObj(self);
        CodeViewController *vc = [[CodeViewController alloc]init];
        [[self getCurrentVC] presentViewController:vc animated:YES completion:nil];
    }];
}

#pragma mark    打开相册
- (void)photo
{
    UIImagePickerController *picker = [[UIImagePickerController alloc]init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.allowsEditing = YES;
    picker.delegate = self;
    [[self getCurrentVC] presentViewController:picker animated:YES completion:nil];
}

#pragma mark-   打开手电筒
- (void)openFlashLamp
{
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([device hasTorch]) {//判断设备是否有摄像头，模拟器没有
        //锁定系统摄像头
        [device lockForConfiguration:nil];
        if (device.torchMode == AVCaptureTorchModeOff) {
            [device setTorchMode:AVCaptureTorchModeOn];//   打开
        }else {
            [device setTorchMode:AVCaptureTorchModeOff];//关闭
        }
        //解除锁定
        [device unlockForConfiguration];
    }
}

#pragma mark-   初始化扫描设备
- (void)captureDevice
{
    //模拟器
    if (TARGET_IPHONE_SIMULATOR) {
        return;
    }
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied) {
        UIAlertController *alter = [UIAlertController alertControllerWithTitle:@"提示" message:@"当前设备相机不可用，请到设置中打开相机即可扫描" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancleAction = [UIAlertAction actionWithTitle:@"我知道了" style:UIAlertActionStyleCancel handler:nil];
        [alter addAction:cancleAction];
        [[self getCurrentVC]presentViewController:alter animated:YES completion:nil];
        return ;
    }
    
    self.myDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    self.deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.myDevice error:nil];
    self.metadataOutput = [[AVCaptureMetadataOutput alloc]init];
    [self.metadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    //设置扫描区域的大小 (这里要宽和高要颠倒一下，具体原因我特么也不清楚)  （0，0，1，1）
    self.metadataOutput.rectOfInterest = CGRectMake((SCREEN_HEIGHT/2-64-CodeScanHeight/2)/SCREEN_HEIGHT, (SCREEN_WIDTH/2-CodeScanWidth/2)/SCREEN_WIDTH, CodeScanHeight/SCREEN_HEIGHT, CodeScanWidth/SCREEN_WIDTH);
    
    self.session = [[AVCaptureSession alloc]init];
    self.session.sessionPreset = AVCaptureSessionPresetHigh;
    [self.session addInput:self.deviceInput];
    [self.session addOutput:self.metadataOutput];
    
    //扫码支持的编码格式（二维码、条形码）
    self.metadataOutput.metadataObjectTypes = @[
                                                AVMetadataObjectTypeQRCode,
                                                AVMetadataObjectTypeEAN13Code,
                                                AVMetadataObjectTypeEAN8Code,
                                                AVMetadataObjectTypeCode128Code,
                                                AVMetadataObjectTypeCode39Code,
                                                AVMetadataObjectTypeCode93Code,
                                                AVMetadataObjectTypeCode39Mod43Code,
                                                AVMetadataObjectTypePDF417Code,
                                                AVMetadataObjectTypeAztecCode,
                                                AVMetadataObjectTypeUPCECode,
                                                ];
    
    //预览图层
    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.previewLayer.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);//全屏预览
    [self.layer insertSublayer:self.previewLayer atIndex:0];
    
    [self startScan];
}

#pragma mark    线条开始扫描
- (void)startScan
{
    @WeakObj(self);
    [[[[RACSignal interval:1.5 onScheduler:[RACScheduler mainThreadScheduler]]takeUntilBlock:^BOOL(id x) {
        @StrongObj(self);
        return self.isScanStop == YES;
    }]takeUntil:self.rac_willDeallocSignal] subscribeNext:^(id x) {
        @StrongObj(self);
        [self lineAnimation];
    }];
    [self.session startRunning];
}
#pragma mark    停止扫描
- (void)stopScan
{
    [self.session stopRunning];
}

#pragma mark    线条扫描
- (void)lineAnimation
{
    @WeakObj(self);
    [UIView animateWithDuration:1.5 animations:^{
        @StrongObj(self);
        [self.lineImgView setFrame:CGRectMake(CGRectGetMinX(self.scanImgView.frame)+10, CGRectGetMaxY(self.scanImgView.frame)-2, self.scanImgView.frame.size.width-20, 2)];
    } completion:^(BOOL finished) {
        @StrongObj(self);
        [self.lineImgView setFrame:CGRectMake(CGRectGetMinX(self.scanImgView.frame)+10, CGRectGetMinY(self.scanImgView.frame)+2, self.scanImgView.frame.size.width-20, 2)];
    }];
    //----- 测试定时器是否关掉 代码-----
    static int i=0;
    NSLog(@"%i",i++);//递增输出
    // -----------------------------
}

#pragma mark    播放音效
- (void)playSound:(NSString *)soundName
{
    if (soundName == nil || soundName.length == 0) {
        //系统音效
        SystemSoundID soundId = 1007;
        AudioServicesPlaySystemSound(soundId);
        return;
    }
    //自定义音效
    NSString *soundPath = [[NSBundle mainBundle] pathForResource:soundName ofType:nil];
    NSURL *soundURL = [NSURL fileURLWithPath:soundPath];
    
    //获得系统声音ID
    SystemSoundID SOUND_ID = 0;
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)(soundURL), &SOUND_ID);
    //播放完之后执行某些操作，注册一个播放完成回调方法
    AudioServicesAddSystemSoundCompletion(SOUND_ID, NULL, NULL, soundPlayCompleteCallBack, NULL);
}
//播放完成回调方法
void soundPlayCompleteCallBack(SystemSoundID soundID, void *soundData)
{
    NSLog(@"播放完成。。。");
}

#pragma mark    AVCaptureMetadataOutputObjectsDelegate  扫描结果处理
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    //播放音效
    [self playSound:nil];
    if (metadataObjects.count > 0) {
        //停止扫描
        self.isScanStop = YES;
        [self stopScan];
        
        AVMetadataMachineReadableCodeObject *metadataObj = metadataObjects[0];
        if (self.delegateSubject) {
            [self.delegateSubject sendNext:metadataObj.stringValue];//发送扫描结果
        }
        
        /*
         -*************  如果需要连续扫描，打开下面这句，扫描完成后在VC中调用释放 ***********-
         */
        @WeakObj(self);
        [[RACScheduler mainThreadScheduler]afterDelay:2 schedule:^{
            //2秒后执行
            @StrongObj(self);
            self.isScanStop = NO;
            [self startScan];
        }];
    }
}

#pragma mark    UIImagePickerControllerDelegate
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [[self getCurrentVC] dismissViewControllerAnimated:YES completion:nil];
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    UIImage *img = info[UIImagePickerControllerEditedImage];
    if (!img) {
        img = info[UIImagePickerControllerOriginalImage];
    }
    @WeakObj(self);
    [[self getCurrentVC] dismissViewControllerAnimated:YES completion:^{
        @StrongObj(self);
        [self readQRcodeImg:img];
    }];
}

#pragma mark    识别相册二维码，读取二维码信息
- (void)readQRcodeImg:(UIImage *)img
{
    NSData *imgData = UIImageJPEGRepresentation(img, 1);
    CIContext *context = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer:@(true),kCIContextPriorityRequestLow:@(false)}];
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:context options:nil];
    CIImage *image = [CIImage imageWithData:imgData];
    NSArray *arr = [detector featuresInImage:image];
    if (arr.count >= 1) {
        CIQRCodeFeature *feature = [arr firstObject];
        //读取结果
        if (self.delegateSubject) {
            [self.delegateSubject sendNext:feature.messageString];
        }
    }else {
        UIAlertController *alter = [UIAlertController alertControllerWithTitle:@"扫描结果" message:@"不是二维码图片" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancleAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:nil];
        [alter addAction:cancleAction];
        [[self getCurrentVC]presentViewController:alter animated:YES completion:nil];
    }
}

//快速获取当前vc
- (UIViewController *)getCurrentVC
{
    return [self getVisibleVcFrom:(UIViewController *)appDelegate.window.rootViewController];
}

// 获取当前vc
- (UIViewController *)getVisibleVcFrom:(UIViewController*)vc {
    if ([vc isKindOfClass:[UINavigationController class]]) {
        return [self getVisibleVcFrom:[((UINavigationController*) vc) visibleViewController]];
    }else if ([vc isKindOfClass:[UITabBarController class]]){
        return [self getVisibleVcFrom:[((UITabBarController*) vc) selectedViewController]];
    } else {
        if (vc.presentedViewController) {
            return [self getVisibleVcFrom:vc.presentedViewController];
        } else {
            return vc;
        }
    }
}

- (void)dealloc
{
    NSLog(@"%@",[self class]);
}

@end
