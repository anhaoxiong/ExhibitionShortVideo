//
//  MainViewController.m
//  ShortVideo
//
//  Created by hxiongan on 2019/4/8.
//  Copyright © 2019年 ahx. All rights reserved.
//

#import "MainViewController.h"
#import "QNImageTitleButton.h"
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

    int width = 100;
    int height = 150;
    QNImageTitleButton *recordingButton = [[QNImageTitleButton alloc] initWithFrame:CGRectMake(0, 0, width, height) image:[UIImage imageNamed:@"qn_select_meterial"] title:@"视频拍摄"];
    [recordingButton addTarget:self action:@selector(clickRecordingButton:) forControlEvents:(UIControlEventTouchUpInside)];
    [self.view addSubview:recordingButton];
    
    QNImageTitleButton *mixRecordingButton = [[QNImageTitleButton alloc] initWithFrame:CGRectMake(0, 0, width, height) image:[UIImage imageNamed:@"qn_select_meterial"] title:@"素材合拍"];
    [mixRecordingButton addTarget:self action:@selector(mixRecordingButton:) forControlEvents:(UIControlEventTouchUpInside)];
    [self.view addSubview:mixRecordingButton];
    
    CGSize size = CGSizeMake(width, height);
    [recordingButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.equalTo(size);
        make.centerX.equalTo(self.view.mas_centerX);
        make.bottom.equalTo(self.view.centerY).offset( -20);
    }];
    
    [mixRecordingButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.equalTo(size);
        make.centerX.equalTo(self.view.mas_centerX);
        make.top.equalTo(self.view.centerY).offset(20);
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
