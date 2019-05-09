//
//  MainViewController.m
//  ShortVideo
//
//  Created by hxiongan on 2019/4/8.
//  Copyright © 2019年 ahx. All rights reserved.
//

#import "MainViewController.h"
#import "QNRecordingViewController.h"
#import "QBImagePickerController.h"
#import "QNMixRecordingViewController.h"

@interface MainViewController ()
<
QBImagePickerControllerDelegate
>

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    UIImage *bgImg = [UIImage imageNamed:@"qn_main_background"];
    int width = bgImg.size.width;
    int height = width;
    UIButton *recordingButton = [[UIButton alloc] init];
    recordingButton.clipsToBounds = YES;
    recordingButton.layer.cornerRadius = width / 2;
    [recordingButton setImage:[UIImage imageNamed:@"qn_main_camera"] forState:(UIControlStateNormal)];
    [recordingButton setBackgroundImage:bgImg forState:(UIControlStateNormal)];
    [recordingButton addTarget:self action:@selector(clickRecordingButton:) forControlEvents:(UIControlEventTouchUpInside)];
    [self.view addSubview:recordingButton];
    
    
    UILabel *recordingLabel = [[UILabel alloc] init];
    recordingLabel.font = [UIFont systemFontOfSize:14];
    recordingLabel.textAlignment = NSTextAlignmentCenter;
    recordingLabel.textColor = [UIColor whiteColor];
    recordingLabel.text = @"视频录制";
    [self.view addSubview:recordingLabel];
    
    UIButton *mixRecordingButton = [[UIButton alloc] init];
    mixRecordingButton.clipsToBounds = YES;
    mixRecordingButton.layer.cornerRadius = width / 2;
    [mixRecordingButton setImage:[UIImage imageNamed:@"qn_main_merge"] forState:(UIControlStateNormal)];
    [mixRecordingButton setBackgroundImage:bgImg forState:(UIControlStateNormal)];
    [mixRecordingButton addTarget:self action:@selector(mixRecordingButton:) forControlEvents:(UIControlEventTouchUpInside)];
    [self.view addSubview:mixRecordingButton];
    
    UILabel *mixRecordingLabel = [[UILabel alloc] init];
    mixRecordingLabel.font = [UIFont systemFontOfSize:14];
    mixRecordingLabel.textAlignment = NSTextAlignmentCenter;
    mixRecordingLabel.textColor = [UIColor whiteColor];
    mixRecordingLabel.text = @"素材合拍";
    [self.view addSubview:mixRecordingLabel];
    
    CGSize size = CGSizeMake(width, height);
    [recordingButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.equalTo(size);
        make.centerX.equalTo(self.view.mas_centerX);
        make.bottom.equalTo(self.view.centerY).offset( -50);
    }];
    
    [recordingLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(recordingButton);
        make.top.equalTo(recordingButton.mas_bottom).offset(10);
    }];
    
    [mixRecordingButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.equalTo(size);
        make.centerX.equalTo(self.view.mas_centerX);
        make.top.equalTo(self.view.centerY).offset(20);
    }];
    
    [mixRecordingLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(mixRecordingButton);
        make.top.equalTo(mixRecordingButton.mas_bottom).offset(10);
    }];
}

- (void)clickRecordingButton:(UIButton *)button {
    QNRecordingViewController *recordingController = [[QNRecordingViewController alloc] init];
    [self presentViewController:recordingController animated:YES completion:nil];
}

- (void)mixRecordingButton:(UIButton *)button {
    [self showImagePickerWithMediaType:(QBImagePickerMediaTypeVideo) maxSelectedCount:1 minSelectedCount:1];
}

- (void)showImagePickerWithMediaType:(QBImagePickerMediaType)mediaType maxSelectedCount:(NSUInteger)maxCount minSelectedCount:(NSUInteger)minCount {
    QBImagePickerController *picker = [[QBImagePickerController alloc] init];
    picker.delegate = self;
    picker.mediaType = mediaType;
    picker.allowsMultipleSelection = maxCount > 1;
    picker.showsNumberOfSelectedAssets = YES;
    picker.maximumNumberOfSelection = maxCount;
    picker.minimumNumberOfSelection = minCount;

    [self presentViewController:picker animated:YES completion:nil];
}

// ======= QBImagePickerController
- (void)qb_imagePickerController:(QBImagePickerController *)imagePickerController didFinishPickingAssets:(NSArray *)assets {
    
    [self dismissViewControllerAnimated:YES completion:^{
        [self gotoMixRecorderController:assets.firstObject];
    }];
}

- (void)qb_imagePickerControllerDidCancel:(QBImagePickerController *)imagePickerController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)gotoMixRecorderController:(PHAsset *)phAsset {
    
    NSURL *url = [QNBaseViewController movieURL:phAsset];
    if (!url) {
        [self showAlertMessage:@"错误" message:@"获取视频地址失败"];
        return;
    }
    
    QNMixRecordingViewController *rc = [[QNMixRecordingViewController alloc] init];
    rc.mixURL = url;
    [self presentViewController:rc animated:YES completion:nil];
}

@end
