//
//  QNPictureViewController.m
//  ExhibitionShortVideo
//
//  Created by hxiongan on 2019/5/7.
//  Copyright © 2019年 ahx. All rights reserved.
//

#import "QNPictureViewController.h"

@interface QNPictureViewController ()

@property (nonatomic, strong) UIView *bgView;

@end

@implementation QNPictureViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    CGFloat ratio = 500.0/350.0;
    
    UIView *bgView = [[UIView alloc] init];
    bgView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:bgView];
    self.bgView = bgView;
    
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.image = self.originPicture;
    UIImageView *qrCodeView = [[UIImageView alloc] init];
    qrCodeView.image = [self qrImage];
    UIImageView *logoView = [[UIImageView alloc] init];
    logoView.image = [UIImage imageNamed:@"qiniu_logo"];

    UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont systemFontOfSize:16];
    label.text = @"- 七牛云短视频";
    label.textColor = [UIColor blackColor];
    label.textAlignment = NSTextAlignmentRight;
    
    UILabel *detailLabel = [[UILabel alloc] init];
    detailLabel.font = [UIFont systemFontOfSize:10];
    detailLabel.text = @"可能是全世界包体最小、性能最优、功能覆盖最全的短视频 SDK，帮您快速上线短视频应用";
    detailLabel.numberOfLines = 0;
    detailLabel.textColor = [UIColor blackColor];
    detailLabel.textAlignment = NSTextAlignmentLeft;
    
    UIButton *printButton = [[UIButton alloc] init];
    [printButton setBackgroundColor:[UIColor colorWithRed:.8 green:.2 blue:.2 alpha:1]];
    [printButton setTitle:@"打印" forState:(UIControlStateNormal)];
    [printButton setTitleColor:[UIColor whiteColor] forState:(UIControlStateNormal)];
    [printButton addTarget:self action:@selector(clickPrintButton) forControlEvents:(UIControlEventTouchUpInside)];
    printButton.titleLabel.font = [UIFont systemFontOfSize:14];
    printButton.layer.cornerRadius = 5;
    
    [self.view addSubview:printButton];
    
    UIButton *reselectButton = [UIButton buttonWithType:(UIButtonTypeSystem)];
    [reselectButton setTintColor:[UIColor colorWithRed:.8 green:.2 blue:.2 alpha:1]];
    [reselectButton setTitle:@"重新选取封面" forState:(UIControlStateNormal)];
    [reselectButton addTarget:self action:@selector(clickReselectButton) forControlEvents:(UIControlEventTouchUpInside)];
    [self.view addSubview:reselectButton];
    
    [reselectButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.mas_bottomLayoutGuide).offset(-20);
        make.centerX.equalTo(self.view);
        make.height.equalTo(30);
    }];
    
    [printButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.width.equalTo(self.view).offset(-100);
        make.height.equalTo(44);
        make.bottom.equalTo(reselectButton.mas_top).offset(-10);
    }];
    
    [bgView addSubview:imageView];
    [bgView addSubview:qrCodeView];
    [bgView addSubview:label];
    [bgView addSubview:detailLabel];
    [imageView addSubview:logoView];
    
    CGFloat edge = 30 * self.view.bounds.size.width / 412.0;
    edge = round(edge);
    [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.equalTo(bgView).offset(edge);
        make.right.equalTo(bgView).offset(-edge);
        make.height.equalTo(imageView.mas_width).multipliedBy(PICTURE_RATIO);
    }];
    
    [qrCodeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(imageView.mas_bottom).offset(10);
        make.right.equalTo(imageView).offset(-10);
        make.bottom.equalTo(bgView).offset(-edge);
        make.width.equalTo(qrCodeView.mas_height);
    }];
    
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(qrCodeView);
        make.right.equalTo(qrCodeView.mas_left).offset(-edge);
    }];
    
    [detailLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(imageView).offset(10);
        make.right.equalTo(qrCodeView.mas_left).offset(-edge);
        make.top.equalTo(qrCodeView);
    }];
    
    [logoView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.equalTo(imageView).offset(15);
        make.size.equalTo(logoView.image.size);
    }];
    
    [bgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(printButton.mas_top).offset(-30);
        make.centerX.equalTo(self.view);
        make.width.equalTo(self.view).multipliedBy(.9);
        make.height.equalTo(bgView.mas_width).multipliedBy(ratio);
    }];
}

- (UIImage *)qrImage {
    @autoreleasepool {
        NSData *stringData = [self.videoURLString dataUsingEncoding: NSUTF8StringEncoding];
        
        CIFilter *qrFilter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
        [qrFilter setValue:stringData forKey:@"inputMessage"];
        [qrFilter setValue:@"H" forKey:@"inputCorrectionLevel"];
        
        CIImage *qrImage = qrFilter.outputImage;
        
        CGRect extent = CGRectIntegral(qrImage.extent);
        CGFloat scale = MIN(200.0 / CGRectGetWidth(extent), 200.0 / CGRectGetHeight(extent));
        
        size_t width = CGRectGetWidth(extent) * scale;
        size_t height = CGRectGetHeight(extent) * scale;
        CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
        CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
        CIContext *context = [CIContext contextWithOptions:nil];
        CGImageRef bitmapImage = [context createCGImage:qrImage fromRect:extent];
        CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
        CGContextScaleCTM(bitmapRef, scale, scale);
        CGContextDrawImage(bitmapRef, extent, bitmapImage);
        // 保存bitmap到图片
        CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
        CGContextRelease(bitmapRef);
        CGImageRelease(bitmapImage);
        
        UIImage *image = [UIImage imageWithCGImage:scaledImage];
        return image;
    }
}

- (void)clickPrintButton {

    @autoreleasepool {
        UIGraphicsBeginImageContextWithOptions(self.bgView.bounds.size, YES, [UIScreen mainScreen].scale);
        [self.bgView drawViewHierarchyInRect:self.bgView.bounds afterScreenUpdates:YES];
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
        
        NSData *data = UIImageJPEGRepresentation(image, 1);
        UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:@[data] applicationActivities:nil];

        __weak typeof(self) weakself = self;
        [controller setCompletionWithItemsHandler:^(UIActivityType  _Nullable activityType, BOOL completed, NSArray * _Nullable returnedItems, NSError * _Nullable activityError) {
            if (UIActivityTypePrint == activityType && completed) {
                [weakself.view showTip:@"已提交打印"];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:FINISH_PRINT_NOTIFY object:nil];
                });
            }
        }];
        [self presentViewController:controller animated:YES completion:^{}];
    }
}

- (void)clickReselectButton {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
