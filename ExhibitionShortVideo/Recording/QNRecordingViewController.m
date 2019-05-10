//
//  QNRecordingViewController.m
//  ShortVideo
//
//  Created by hxiongan on 2019/4/8.
//  Copyright © 2019年 ahx. All rights reserved.
//

#import "QNRecordingViewController.h"
#import "QNRecordingProgress.h"
#import "QNEditorViewController.h"
#import "QNFilterGroup.h"
#import <PLShortVideoKit/PLShortVideoKit.h>
#import "QNVerticalButton.h"
#import <MediaPlayer/MediaPlayer.h>
#import "QNMusicPickerView.h"
#import "QNFilterPickerView.h"
#import "QNFaceUnityView.h"

@interface QNRecordingViewController ()
<
UIGestureRecognizerDelegate,
PLShortVideoRecorderDelegate,
MPMediaPickerControllerDelegate,
QNMusicPickerViewDelegate,
QNFilterPickerViewDelegate,
QNFaceUnityViewDelegate
>

// 用来放顶部和右侧的 button，便于做隐藏动画
@property (nonatomic, strong) UIView *topBarView;
@property (nonatomic, strong) UIView *rightBarView;

@property (nonatomic, strong) PLShortVideoRecorder *recorder;

@property (nonatomic, strong) QNFilterPickerView *filterPickerView;
@property (nonatomic, weak)   QNFilterGroup *filterGroup;

@property (nonatomic, strong) QNRecordingProgress *recordingProgress;
@property (nonatomic, strong) UIButton *recordingButton;
@property (nonatomic, strong) UIButton *deleteLastButton;
@property (nonatomic, strong) UIButton *nextButton;
@property (nonatomic, strong) UISegmentedControl *rateControl;
@property (nonatomic, strong) UIView *rateIndicatorView;
@property (nonatomic, strong) UILabel *durationLabel;
@property (nonatomic, strong) UILabel *filterNameLabel;
@property (nonatomic, strong) UILabel *filterDetailLabel;
@property (nonatomic, strong) QNVerticalButton *cameraButton;
@property (nonatomic, strong) QNVerticalButton *beautyButton;
@property (nonatomic, strong) QNVerticalButton *musicButton;
@property (nonatomic, strong) QNVerticalButton *filterButton;
@property (nonatomic, strong) QNVerticalButton *flashButton;
@property (nonatomic, strong) QNVerticalButton *snapshotButton;
@property (nonatomic, strong) UIButton *faceUnityButton;
@property (nonatomic, strong) UIButton *forbidFaceUnityButton;

@property (nonatomic, strong) NSURL *musicMixVideoURL;
@property (nonatomic, strong) NSURL *musicURL;

// 切换滤镜的时候，为了更好的用户体验，添加以下属性来做切换动画
@property (nonatomic, assign) BOOL isPanning;
@property (nonatomic, assign) BOOL isLeftToRight;
@property (nonatomic, assign) BOOL isNeedChangeFilter;
@property (nonatomic, weak) PLSFilter *leftFilter;
@property (nonatomic, weak) PLSFilter *rightFilter;
@property (nonatomic, assign) float leftPercent;

@property (nonatomic, strong) QNMusicPickerView *musicPickerView;

// 辅助隐藏音乐选取和滤镜选取 view 的 buttom
@property (nonatomic, strong) UIButton *dismissButton;

// FaceUnity mark
@property (nonatomic, strong) QNFaceUnityView *faceUnityView;
@property (nonatomic, strong) UILabel *faceUnityTipLabel;
@property (nonatomic, assign) BOOL forbidFaceUnity;

@end

@implementation QNRecordingViewController

//============================== UI Action ==============================

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[FUManager shareManager] destoryItems];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    UIView *superView = self.view;
    self.topBarView = [[UIView alloc] init];
    [superView addSubview:self.topBarView];
    [self.topBarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.mas_topLayoutGuide);
        make.height.equalTo(80);
    }];
    
    self.rightBarView = [[UIView alloc] init];
    [superView addSubview:self.rightBarView];
    [self.rightBarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.view).offset(-20);
        make.top.equalTo(self.topBarView.mas_bottom).offset(10);
        make.width.equalTo(44);
        make.height.equalTo(3 * 70);
    }];
    
    self.recordingProgress = [[QNRecordingProgress alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width - 10, 5)];
    self.recordingProgress.layer.cornerRadius = 2.5;
    self.recordingProgress.clipsToBounds = YES;
    
    UIButton *backButton = [UIButton buttonWithType:(UIButtonTypeSystem)];
    [backButton setTintColor:UIColor.whiteColor];
    [backButton setImage:[UIImage imageNamed:@"qn_icon_close"] forState:(UIControlStateNormal)];
    [backButton addTarget:self action:@selector(clickBackButton) forControlEvents:(UIControlEventTouchUpInside)];
    
    self.faceUnityButton = [[UIButton alloc] init];
    [self.faceUnityButton setImage:[UIImage imageNamed:@"qn_sticker"] forState:(UIControlStateNormal)];
    [self.faceUnityButton sizeToFit];
    [self.faceUnityButton addTarget:self action:@selector(clickFaceUnityButton:) forControlEvents:(UIControlEventTouchUpInside)];
    
    self.recordingButton = [[UIButton alloc] init];
    self.recordingButton.titleLabel.font = [UIFont systemFontOfSize:14];
    [self.recordingButton setBackgroundImage:[UIImage imageNamed:@"qn_recording"] forState:(UIControlStateNormal)];
    [self.recordingButton setTitle:@"点击拍摄" forState:(UIControlStateNormal)];
    [self.recordingButton setTitle:@"停止拍摄" forState:(UIControlStateSelected)];
    [self.recordingButton addTarget:self action:@selector(clickRecordingButton:) forControlEvents:(UIControlEventTouchUpInside)];

    self.deleteLastButton = [[UIButton alloc] init];
    [self.deleteLastButton setImage:[UIImage imageNamed:@"qn_btn_del_a"] forState:(UIControlStateNormal)];
    [self.deleteLastButton setImage:[UIImage imageNamed:@"qn_btn_del_active_a"] forState:(UIControlStateSelected)];
    [self.deleteLastButton addTarget:self action:@selector(clickDeleteButton:) forControlEvents:(UIControlEventTouchUpInside)];
    
    self.rateControl = [[UISegmentedControl alloc] initWithItems:@[@"极慢", @"慢", @"正常", @"快", @"极快"]];
    [self.rateControl sizeToFit];
    self.rateControl.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    self.rateControl.layer.cornerRadius = 5;
    self.rateControl.selectedSegmentIndex = 2;
    self.rateControl.clipsToBounds = YES;
    [self.rateControl addTarget:self action:@selector(rateSegmentChange:) forControlEvents:(UIControlEventValueChanged)];
    [self.rateControl setTintColor:[UIColor clearColor]];
    self.rateIndicatorView = [[UIView alloc] init];
    self.rateIndicatorView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:.8];
    [self.rateControl addSubview:self.rateIndicatorView];
    
    self.durationLabel = [[UILabel alloc] init];
    self.durationLabel.textAlignment = NSTextAlignmentCenter;
    self.durationLabel.font = [UIFont monospacedDigitSystemFontOfSize:14 weight:(UIFontWeightRegular)];
    self.durationLabel.textColor = [UIColor whiteColor];
    
    self.nextButton = [[UIButton alloc] init];
    [self.nextButton setImage:[UIImage imageNamed:@"qn_next_button"] forState:(UIControlStateNormal)];
    [self.nextButton addTarget:self action:@selector(clickNextButton:) forControlEvents:(UIControlEventTouchUpInside)];
    [self.nextButton sizeToFit];
    
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName, [UIFont systemFontOfSize:14],NSFontAttributeName,nil];
    [self.rateControl setTitleTextAttributes:dic forState:UIControlStateNormal];
    NSDictionary *dicS = [NSDictionary dictionaryWithObjectsAndKeys:[UIColor colorWithRed:.8 green:.2 blue:.2 alpha:1], NSForegroundColorAttributeName, [UIFont systemFontOfSize:14],NSFontAttributeName ,nil];
    [self.rateControl setTitleTextAttributes:dicS forState:UIControlStateSelected];
    
    self.flashButton = [[QNVerticalButton alloc] init];
    self.flashButton.titleLabel.font = [UIFont systemFontOfSize:14];
    [self.flashButton setImage:[UIImage imageNamed:@"qn_flash_off"] forState:(UIControlStateNormal)];
    [self.flashButton setImage:[UIImage imageNamed:@"qn_flash_on"] forState:(UIControlStateSelected)];
    [self.flashButton setTitle:@"补光" forState:(UIControlStateNormal)];
    [self.flashButton addTarget:self action:@selector(clickFlashButton:) forControlEvents:(UIControlEventTouchUpInside)];
    
    self.beautyButton = [[QNVerticalButton alloc] init];
    self.beautyButton.titleLabel.font = [UIFont systemFontOfSize:14];
    [self.beautyButton setImage:[UIImage imageNamed:@"qn_record_beauty"] forState:(UIControlStateNormal)];
    [self.beautyButton setImage:[UIImage imageNamed:@"qn_record_beauty_on"] forState:(UIControlStateSelected)];
    [self.beautyButton setTitle:@"美颜" forState:(UIControlStateNormal)];
    [self.beautyButton addTarget:self action:@selector(clickBeautyButton:) forControlEvents:(UIControlEventTouchUpInside)];
    self.beautyButton.selected = YES;
    
    self.cameraButton = [[QNVerticalButton alloc] init];
    self.cameraButton.titleLabel.font = [UIFont systemFontOfSize:14];
    [self.cameraButton setImage:[UIImage imageNamed:@"qn_switch_camera"] forState:(UIControlStateNormal)];
    [self.cameraButton setTitle:@"切换" forState:(UIControlStateNormal)];
    [self.cameraButton addTarget:self action:@selector(clickCameraButton:) forControlEvents:(UIControlEventTouchUpInside)];
    
    self.musicButton = [[QNVerticalButton alloc] init];
    self.musicButton.titleLabel.font = [UIFont systemFontOfSize:14];
    [self.musicButton setImage:[UIImage imageNamed:@"qn_music"] forState:(UIControlStateNormal)];
    [self.musicButton setTitle:@"音乐" forState:(UIControlStateNormal)];
    [self.musicButton addTarget:self action:@selector(clickMusicButton:) forControlEvents:(UIControlEventTouchUpInside)];
    
    self.filterButton = [[QNVerticalButton alloc] init];
    self.filterButton.titleLabel.font = [UIFont systemFontOfSize:14];
    [self.filterButton setImage:[UIImage imageNamed:@"qn_filter"] forState:(UIControlStateNormal)];
    [self.filterButton setTitle:@"滤镜" forState:(UIControlStateNormal)];
    [self.filterButton addTarget:self action:@selector(clickFilterButton:) forControlEvents:(UIControlEventTouchUpInside)];
    
    self.snapshotButton = [[QNVerticalButton alloc] init];
    self.snapshotButton.titleLabel.font = [UIFont systemFontOfSize:14];
    [self.snapshotButton setImage:[UIImage imageNamed:@"qn_snapshot"] forState:(UIControlStateNormal)];
    [self.snapshotButton setTitle:@"拍照" forState:(UIControlStateNormal)];
    [self.snapshotButton addTarget:self action:@selector(clickSnapshotButton:) forControlEvents:(UIControlEventTouchUpInside)];
    
    
    superView = self.topBarView;
    
    [superView addSubview:backButton];
    [superView addSubview:self.cameraButton];
    [superView addSubview:self.flashButton];
    [superView addSubview:self.beautyButton];
    [superView addSubview:self.nextButton];
    
    [backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.equalTo(CGSizeMake(44, 44));
        make.left.equalTo(superView).offset(10);
        make.centerY.equalTo(self.cameraButton);
    }];
    
    [self.cameraButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(backButton.mas_right).offset(20);
        make.bottom.equalTo(superView);
        make.size.equalTo(CGSizeMake(44, 60));
    }];
    
    [self.flashButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.cameraButton.mas_right).offset(10);
        make.top.equalTo(self.cameraButton);
        make.size.equalTo(self.cameraButton);
    }];
    
    [self.beautyButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.flashButton.mas_right).offset(10);
        make.top.equalTo(self.cameraButton.mas_top);
        make.size.equalTo(self.cameraButton);
    }];

    [self.nextButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.cameraButton);
        make.size.equalTo(self.nextButton.bounds.size);
        make.right.equalTo(superView).offset(-20);
    }];
    
    superView = self.rightBarView;
    [superView addSubview:self.musicButton];
    [superView addSubview:self.filterButton];
    [superView addSubview:self.snapshotButton];
    
    [self.musicButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.right.equalTo(superView);
        make.size.equalTo(self.cameraButton);
    }];
    
    [self.filterButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.musicButton);
        make.size.equalTo(self.musicButton);
        make.top.equalTo(self.musicButton.mas_bottom).offset(10);
    }];
    
    [self.snapshotButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.musicButton);
        make.size.equalTo(self.musicButton);
        make.top.equalTo(self.filterButton.mas_bottom).offset(10);
    }];
    
    
    superView = self.view;
    [superView addSubview:self.faceUnityButton];
    [superView addSubview:self.rateControl];
    [superView addSubview:self.deleteLastButton];
    [superView addSubview:self.recordingButton];
    [superView addSubview:self.durationLabel];
    [superView addSubview:self.recordingProgress];

    [self.recordingProgress mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(self.topBarView).offset(-10);
        make.centerX.equalTo(self.topBarView);
        make.top.equalTo(self.mas_topLayoutGuide).offset(5);
        make.height.equalTo(5);
    }];
    
    [self.recordingButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(superView);
        make.size.equalTo(CGSizeMake(80, 80));
        make.bottom.equalTo(self.mas_bottomLayoutGuide).offset(-40);
    }];
    
    [self.faceUnityButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.recordingButton);
        make.right.equalTo(self.recordingButton.mas_left).offset(-50);
        make.size.equalTo(CGSizeMake(44, 44));
    }];
    
    [self.deleteLastButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.recordingButton);
        make.size.equalTo(CGSizeMake(44, 44));
        make.left.equalTo(self.recordingButton.mas_right).offset(50);
    }];
    
    [self.rateControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.recordingButton);
        make.bottom.equalTo(self.recordingButton.mas_top).offset(-30);
        make.size.equalTo(CGSizeMake(300, 35));
    }];
    
    [self.durationLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.recordingButton.centerX);
        make.bottom.equalTo(self.recordingButton.mas_top).offset(-5);
    }];
    
    self.rateIndicatorView.frame = CGRectMake(300.0 / 5 * 2, 0, 300.0 / 5, 36);
    
    [self setupRecorder];
    [self setupFilter];
    
    // 初始化 FaceUnity 美颜等参数
    [self setupFaceUnity];
    
#ifdef DEBUG
    // 这个 debug 版本对比效果添加的 button
//    self.forbidFaceUnityButton = [UIButton buttonWithType:(UIButtonTypeSystem)];
//    [self.forbidFaceUnityButton setTitle:@"禁用相芯" forState:(UIControlStateNormal)];
//    [self.forbidFaceUnityButton addTarget:self action:@selector(clickForbidFaceUnityButton:) forControlEvents:(UIControlEventTouchUpInside)];
//    [self.forbidFaceUnityButton sizeToFit];
//    [self.view addSubview:self.forbidFaceUnityButton];
//    [self.forbidFaceUnityButton mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.top.equalTo(self.filterButton.mas_bottom).offset(10);
//        make.right.equalTo(self.filterButton);
//        make.size.equalTo(self.forbidFaceUnityButton.bounds.size);
//    }];
#endif
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishPrintNotify:) name:FINISH_PRINT_NOTIFY object:nil];
}

- (void)finishPrintNotify:(NSNotification *)info {
    [self.recorder deleteAllFiles];
    [self.recordingProgress deleteAllProgress];
    self.durationLabel.text = @"0s";
    
    //  及时删除
    if (self.musicMixVideoURL && [[NSFileManager defaultManager] fileExistsAtPath:self.musicMixVideoURL.path]) {
        [[NSFileManager defaultManager] removeItemAtURL:self.musicMixVideoURL error:nil];
        self.musicMixVideoURL = nil;
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.filterPickerView.frame.origin.y < self.view.bounds.size.height) {
        [self.filterPickerView autoLayoutBottomHide:YES];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.recorder startCaptureSession];
    [self showFilterNameLabel];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.recorder stopRecording];
    [self.recorder stopCaptureSession];
    [super viewWillDisappear:animated];
}

- (BOOL)prefersStatusBarHidden {
    return !iPhoneX_SERIES;
}

- (void)hideRecordingControl {
    [self.recordingButton alphaHideAnimation];
    [self.deleteLastButton alphaHideAnimation];
    [self.faceUnityButton alphaHideAnimation];
    [self.rateControl alphaHideAnimation];
    [self.durationLabel alphaHideAnimation];
}

- (void)showRecordingControl {
    [self.recordingButton alphaShowAnimation];
    [self.deleteLastButton alphaShowAnimation];
    [self.faceUnityButton alphaShowAnimation];
    [self.rateControl alphaShowAnimation];
    [self.durationLabel alphaShowAnimation];
}

- (UIButton *)dismissButton {
    if (!_dismissButton) {
        _dismissButton = [UIButton buttonWithType:(UIButtonTypeSystem)];
        [_dismissButton addTarget:self action:@selector(clickDismissPickerViewButton:) forControlEvents:(UIControlEventTouchUpInside)];
    }
    return _dismissButton;
}

- (void)clickBackButton {
    
    if ([self.recorder getFilesCount] > 0 || [self.recorder isRecording]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"确定退出?" message:@"退出之后会丢失所有已经录制的视频" preferredStyle:(UIAlertControllerStyleAlert)];
        UIAlertAction *sureAction = [UIAlertAction actionWithTitle:@"退出" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
            [self.recorder cancelRecording];
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        [alert addAction:sureAction];
        [alert addAction:cancelAction];
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        [self.recorder cancelRecording];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)clickDeleteButton:(UIButton *)button {
    if (0 == self.recorder.getFilesCount) return;
    if (0 == [self.recorder getFilesCount]) return;
    
    if (button.selected) {
        [self.recordingProgress deleteLastProgress];
        [self.recorder deleteLastFile];
    } else {
        [self.recordingProgress setLastProgressToStyle:(enumProgressStyleDelete)];
    }
    
    button.selected = !button.isSelected;
}

- (void)clickRecordingButton:(UIButton *)button {
    if (self.recorder.isRecording) {
        self.recordingButton.selected = NO;
        [self.recorder stopRecording];
    } else {
        self.recordingButton.selected = YES;
        [self.recorder startRecording];
    }
}

- (void)rateSegmentChange:(UISegmentedControl *)control {
    if (self.recorder.isRecording) return;
    
    static int rates[] = {
        PLSVideoRecoderRateTopSlow,
        PLSVideoRecoderRateSlow,
        PLSVideoRecoderRateNormal,
        PLSVideoRecoderRateFast,
        PLSVideoRecoderRateTopFast
    };
    
    self.recorder.recoderRate = rates[(int)control.selectedSegmentIndex];
    
    [control sendSubviewToBack:self.rateIndicatorView];
    [UIView animateWithDuration:.3 animations:^{
        CGRect rc = self.rateIndicatorView.bounds;
        rc.origin.x = control.bounds.size.width * control.selectedSegmentIndex / control.numberOfSegments;
        self.rateIndicatorView.frame = rc;
    }];
}

- (void)clickFlashButton:(UIButton *)button {
    if (AVCaptureDevicePositionFront == self.recorder.captureDevicePosition) return;
    
    button.selected = !button.isSelected;
    [self.recorder setTorchOn:button.isSelected];
}

- (void)clickCameraButton:(UIButton *)button {
    if (self.recorder.isRecording) return;
    
    self.flashButton.selected = NO;
    button.enabled = NO;
    [self.recorder toggleCamera:^(BOOL isFinish) {
        dispatch_async(dispatch_get_main_queue(), ^{
            button.enabled = YES;
        });
    }];
}

- (void)clickBeautyButton:(UIButton *)button {
    button.selected = !button.selected;
    [self.recorder setBeautifyModeOn:button.isSelected];
}

- (void)clickDismissPickerViewButton:(UIButton *)button {
    [button removeFromSuperview];
    if (self.filterPickerView.frame.origin.y < self.view.bounds.size.height) {
        [self.filterPickerView autoLayoutBottomHide:YES];
    }
    if (self.musicPickerView.frame.origin.y < self.view.bounds.size.height) {
        [self.musicPickerView autoLayoutBottomHide:YES];
        [self.musicPickerView stopAudioPlay];
    }
    if (self.faceUnityView.frame.origin.y < self.view.bounds.size.height) {
        [self.faceUnityView autoLayoutBottomHide:YES];
    }
    [self showRecordingControl];
}

- (void)clickMusicButton:(UIButton *)button {
    
    if (self.recorder.isRecording) return;
    if ([self.recorder getFilesCount] > 0) {
        [self.view showTip:@"需要删除已经录制的视频才可以操作音乐"];
        return;
    }
    
    void(^block)(void) = ^{
        if (!self.musicPickerView) {
            QNMusicPickerView *musicView = [[QNMusicPickerView alloc] initWithFrame:CGRectZero needNullModel:YES];
            musicView.delegate = self;
            [self.view addSubview:musicView];
            self.musicPickerView = musicView;
            
            [musicView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.right.equalTo(self.view);
                make.top.equalTo(self.mas_bottomLayoutGuide).offset(-musicView.minViewHeight);
                make.bottom.equalTo(self.view);
            }];
            // 先计算出 musicView 的搞定
            [self.view layoutIfNeeded];
            
            // 将 musicView 隐藏
            [musicView autoLayoutBottomHide:NO];
            [self.view layoutIfNeeded];
            
            if (MPMediaLibraryAuthorizationStatusDenied == [MPMediaLibrary authorizationStatus]) {
                musicView.titleLabel.text = @"到系统设置中允许七牛短视频访问音乐资源，可以添加自己的音乐作为背景音乐";
            }
        }
        
        if (self.musicPickerView.frame.origin.y >= self.view.bounds.size.height) {
            [self.view addSubview:self.dismissButton];
            [self.dismissButton mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.left.right.top.equalTo(self.view);
                make.bottom.equalTo(self.musicPickerView.mas_top);
            }];
            [self.musicPickerView autoLayoutBottomShow:YES];
            [self hideRecordingControl];
            [self.musicPickerView startAudioPlay];
        }
    };
    
    if (MPMediaLibraryAuthorizationStatusNotDetermined == [MPMediaLibrary authorizationStatus]) {
        [self requestMPMediaLibraryAuth:^(BOOL succeed) {
            block();
        }];
    } else {
        block();
    }
}

- (void)clickFilterButton:(UIButton *)button {
    
    self.filterPickerView.hidden = NO;
    
    if (self.filterPickerView.frame.origin.y >= self.view.bounds.size.height) {
        [self.view addSubview:self.dismissButton];
        [self.dismissButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.right.top.equalTo(self.view);
            make.bottom.equalTo(self.filterPickerView.mas_top);
        }];
        [self.view bringSubviewToFront:self.filterPickerView];
        [self.filterPickerView autoLayoutBottomShow:YES];
        [self hideRecordingControl];
    }
}

- (void)clickSnapshotButton:(UIButton *)button {
    button.enabled = NO;
    __weak typeof(self) weakself = self;
    [self.recorder getScreenShotWithCompletionHandler:^(UIImage * _Nullable image) {
        button.enabled = YES;
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
        [weakself.view showTip:@"照片已保存到相册"];
    }];
}

- (void)clickNextButton:(UIButton *)button {
    
    if ([self.recorder getTotalDuration] < self.recorder.minDuration) {
        NSString *str = [NSString stringWithFormat:@"请至少拍摄 %d 秒的视频", (int)self.recorder.minDuration];
        [self.view showTip:str];
        return;
    }
    
    AVAsset *asset = self.recorder.assetRepresentingAllFiles;
    [self playEvent:asset];
}

// UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    
    NSMutableArray *classArray = [[NSMutableArray alloc] init];
    UIView *view = touch.view;
    while (view) {
        [classArray addObject:NSStringFromClass(view.class)];
        view = view.superview;
    }
    if ([classArray containsObject:NSStringFromClass(QNFaceUnityView.class)]) return NO;
    if ([classArray containsObject:NSStringFromClass(QNFilterPickerView.class)]) return NO;
    if ([classArray containsObject:NSStringFromClass(QNMusicPickerView.class)]) return NO;
    
    return YES;
}

// 添加手势的响应事件
- (void)handleFilterPan:(UIPanGestureRecognizer *)gestureRecognizer {

    CGPoint transPoint = [gestureRecognizer translationInView:gestureRecognizer.view];
    CGPoint speed = [gestureRecognizer velocityInView:gestureRecognizer.view];

    switch (gestureRecognizer.state) {
            
        case UIGestureRecognizerStateBegan: {
            NSInteger index = 0;
            if (speed.x > 0) {
                self.isLeftToRight = YES;
                index = self.filterGroup.filterIndex - 1;
            } else {
                index = self.filterGroup.filterIndex + 1;
                self.isLeftToRight = NO;
            }
            
            if (index < 0) {
                index = self.filterGroup.filtersInfo.count - 1;
            } else if (index >= self.filterGroup.filtersInfo.count) {
                index = index - self.filterGroup.filtersInfo.count;
            }
            self.filterGroup.nextFilterIndex = index;
            
            if (self.isLeftToRight) {
                self.leftFilter = self.filterGroup.nextFilter;
                self.rightFilter = self.filterGroup.currentFilter;
                self.leftPercent = 0.0;
            } else {
                self.leftFilter = self.filterGroup.currentFilter;
                self.rightFilter = self.filterGroup.nextFilter;
                self.leftPercent = 1.0;
            }
            self.isPanning = YES;
            
            break;
        }
        case UIGestureRecognizerStateChanged: {
            if (self.isLeftToRight) {
                if (transPoint.x <= 0) {
                    transPoint.x = 0;
                }
                self.leftPercent = transPoint.x / gestureRecognizer.view.bounds.size.width;
                self.isNeedChangeFilter = (self.leftPercent >= 0.5) || (speed.x > 500 );
            } else {
                if (transPoint.x >= 0) {
                    transPoint.x = 0;
                }
                self.leftPercent = 1 - fabs(transPoint.x) / gestureRecognizer.view.bounds.size.width;
                self.isNeedChangeFilter = (self.leftPercent <= 0.5) || (speed.x < -500);
            }
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed: {
            gestureRecognizer.enabled = NO;
            
            // 做一个滤镜过渡动画，优化用户体验
            dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
            dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC, 0.005 * NSEC_PER_SEC);
            dispatch_source_set_event_handler(timer, ^{
                if (!self.isPanning) return;
                
                float delta = 0.03;
                if (self.isNeedChangeFilter) {
                    // apply filter change
                    if (self.isLeftToRight) {
                        self.leftPercent = MIN(1, self.leftPercent + delta);
                    } else {
                        self.leftPercent = MAX(0, self.leftPercent - delta);
                    }
                } else {
                    // cancel filter change
                    if (self.isLeftToRight) {
                        self.leftPercent = MAX(0, self.leftPercent - delta);
                    } else {
                        self.leftPercent = MIN(1, self.leftPercent + delta);
                    }
                }
                
                if (self.leftPercent < FLT_EPSILON || fabs(1.0 - self.leftPercent) < FLT_EPSILON) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        dispatch_source_cancel(timer);
                        if (self.isNeedChangeFilter) {
                            self.filterGroup.filterIndex = self.filterGroup.nextFilterIndex;
                            self.filterNameLabel.text = [self.filterGroup.filtersInfo[self.filterGroup.filterIndex] objectForKey:@"name"];
                            [self showFilterNameLabel];
                            [self.filterPickerView updateSelectFilterIndex];
                        }
                        self.isPanning = NO;
                        self.isNeedChangeFilter = NO;
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            gestureRecognizer.enabled = YES;
                        });
                    });
                }
            });
            dispatch_resume(timer);
            break;
        }
            
        case UIGestureRecognizerStatePossible: {
            NSLog(@"UIGestureRecognizerStatePossible");
        } break;
        
        default:
            break;
    }
}

- (void)showFilterNameLabel {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideFilterNameLabel) object:nil];
    self.filterNameLabel.hidden = NO;
    self.filterDetailLabel.hidden = NO;
    [UIView animateWithDuration:.3 animations:^{
        self.filterDetailLabel.alpha = 1;
        self.filterNameLabel.alpha = 1;
    }];
    [self performSelector:@selector(hideFilterNameLabel) withObject:nil afterDelay:2];
}

- (void)hideFilterNameLabel {
    [UIView animateWithDuration:.3 animations:^{
        self.filterNameLabel.alpha = 0;
        self.filterDetailLabel.alpha = 0;
    } completion:^(BOOL finished) {
        self.filterNameLabel.hidden = YES;
        self.filterDetailLabel.hidden = YES;
    }];
}

// ============ QNMusicPickerViewDelegate 选择背景音乐回调
- (void)musicPickerView:(QNMusicPickerView *)musicPickerView didEndPickerWithMusic:(QNMusicModel *)model {
    if (model.musicURL) {
        [self.recorder mixAudio:model.musicURL startTime:CMTimeGetSeconds(model.startTime) volume:1.0 playEnable:NO];
    } else {
        [self.recorder mixAudio:nil];
    }
    self.musicURL = model.musicURL;
    [self clickDismissPickerViewButton:self.dismissButton];
}

// ============ QNFilterPickerViewDelegate 通过 collectionView 选择滤镜回调
- (void)filterView:(QNFilterPickerView *)filterView didSelectedFilter:(NSString *)colorImagePath {
    self.filterNameLabel.text = [self.filterGroup.filtersInfo[self.filterGroup.filterIndex] objectForKey:@"name"];
    [self showFilterNameLabel];
}

//============================== recording Action ==============================
- (void)setupRecorder {
    
    // 视频参数设置
    PLSVideoConfiguration *videoConfiguration = [PLSVideoConfiguration defaultConfiguration];
    videoConfiguration.videoSize = CGSizeMake(720, 1280);
    videoConfiguration.sessionPreset = AVCaptureSessionPreset1280x720;
    videoConfiguration.videoOrientation = AVCaptureVideoOrientationPortrait;// 竖屏采集
    videoConfiguration.position = AVCaptureDevicePositionFront;// 摄像头选取
    videoConfiguration.videoFrameRate = 30.0;// 帧率，如果相机支持，最大支持 60 帧
    videoConfiguration.averageVideoBitRate = [QNBaseViewController suitableVideoBitrateWithSize:videoConfiguration.videoSize];
    videoConfiguration.videoMaxKeyframeInterval = 3 * videoConfiguration.videoFrameRate;// 关键帧间隔
    videoConfiguration.previewMirrorFrontFacing = YES;// 前置摄像头预览的时候，做镜像处理
    videoConfiguration.streamMirrorFrontFacing = NO;// 前置摄像头采集的数据生成文件的时候，不做镜像处理
    videoConfiguration.previewMirrorRearFacing = NO;// 后置摄像头预览的时候，不做镜像处理
    videoConfiguration.streamMirrorRearFacing = NO;// 后置摄像头采集的数据生成文件的时候，不做镜像处理
    
    // 音频参数设置
    PLSAudioConfiguration *audioConfiguration = [PLSAudioConfiguration defaultConfiguration];
    audioConfiguration.numberOfChannels = 1;
    audioConfiguration.bitRate = PLSAudioBitRate_64Kbps;
    audioConfiguration.sampleRate = PLSAudioSampleRate_44100Hz;
    
    self.recorder = [[PLShortVideoRecorder alloc] initWithVideoConfiguration:videoConfiguration audioConfiguration:audioConfiguration];
    self.recorder.delegate = self;
    self.recorder.maxDuration = 10;
    
    // 如果设置为 YES，在录制的状态下进入后台，回到前台的时候，自动开始录制
    self.recorder.backgroundMonitorEnable = NO;
    
    // 如果设置为 YES，会根据手机方向，自动确定录制的视频是横屏还是竖屏，类似系统自带相机
    self.recorder.adaptationRecording = NO;
    
    // SDK 自带美颜设置
    [self.recorder setBeautifyModeOn:YES];
    [self.recorder setBeautify:.5];
    [self.recorder setWhiten:.5];
    [self.recorder setRedden:.5];
    
    [self.view insertSubview:self.recorder.previewView atIndex:0];
    [self.recorder.previewView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}

- (void)setupFilter {
    
    if (!self.filterPickerView) {
        
        self.filterPickerView = [[QNFilterPickerView alloc] init];
        self.filterPickerView.delegate = self;
        self.filterPickerView.hidden = YES;
        [self.view addSubview:self.filterPickerView];
        
        [self.filterPickerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.left.right.equalTo(self.view);
            make.top.equalTo(self.mas_bottomLayoutGuide).offset(-self.filterPickerView.minViewHeight);
        }];
        self.filterGroup = self.filterPickerView.filterGroup;
    }

    UIPanGestureRecognizer * panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleFilterPan:)];
    panGesture.delegate = self;
    [self.view addGestureRecognizer:panGesture];
    
    self.filterNameLabel = [[UILabel alloc] init];
    self.filterNameLabel.textColor = [UIColor colorWithWhite:1 alpha:1];
    self.filterNameLabel.font = [UIFont systemFontOfSize:30];
    self.filterNameLabel.text = [self.filterGroup.filtersInfo[0] objectForKey:@"name"];
    
    self.filterDetailLabel = [[UILabel alloc] init];
    self.filterDetailLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.8];
    self.filterDetailLabel.font = [UIFont systemFontOfSize:12];
    self.filterDetailLabel.text = @"<<左右滑动切换滤镜>>";
    
    [self.view addSubview:self.filterNameLabel];
    [self.view addSubview:self.filterDetailLabel];
    [self.filterNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(20);
        make.centerY.equalTo(self.view).offset(-50);
    }];
    [self.filterDetailLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.filterNameLabel);
        make.top.equalTo(self.filterNameLabel.mas_bottom).offset(2);
    }];
}

- (NSURL *)exportAudioMixPath {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:path]) {
        [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyyMMddHHmmss";
    NSString *nowTimeStr = [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]];
    NSString *fileName = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_mix.mp4",nowTimeStr]];
    return [NSURL fileURLWithPath:fileName];
}

- (void)playEvent:(AVAsset *)asset {
    
    __block AVAsset *movieAsset = asset;
    __block NSArray *fileURLs = [self.recorder getAllFilesURL];
    if (self.musicURL) {
        __weak typeof(self) weakself = self;
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        [self.view showFullLoading];
        // MusicVolume：1.0，videoVolume:0.0 即完全丢弃掉拍摄时的所有声音，只保留背景音乐的声音
        [self.recorder mixWithMusicVolume:1.0 videoVolume:0.0 completionHandler:^(AVMutableComposition * _Nullable composition, AVAudioMix * _Nullable audioMix, NSError * _Nullable error) {
            AVAssetExportSession *exporter = [[AVAssetExportSession alloc]initWithAsset:composition presetName:AVAssetExportPresetHighestQuality];
            weakself.musicMixVideoURL = [weakself exportAudioMixPath];
            exporter.outputURL = weakself.musicMixVideoURL;
            exporter.outputFileType = AVFileTypeMPEG4;
            exporter.shouldOptimizeForNetworkUse= YES;
            exporter.audioMix = audioMix;
            [exporter exportAsynchronouslyWithCompletionHandler:^{
                switch ([exporter status]) {
                    case AVAssetExportSessionStatusFailed: {
                        [self showAlertMessage:nil message:[[exporter error] description]];
                    } break;
                    case AVAssetExportSessionStatusCancelled: {
                        [self showAlertMessage:nil message:@"取消了背景音乐"];
                    } break;
                    case AVAssetExportSessionStatusCompleted: {
                        fileURLs = @[weakself.musicMixVideoURL];
                        movieAsset = [AVAsset assetWithURL:weakself.musicMixVideoURL];
                    } break;
                    default: {
                        
                    } break;
                }
                dispatch_semaphore_signal(semaphore);
            }];
        }];
        [self.view hideFullLoading];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }
    
    // =========================== goto editer controller ==========================
    // 设置音视频、水印等编辑信息
    NSMutableDictionary *outputSettings = [[NSMutableDictionary alloc] init];
    // 待编辑的原始视频素材s
    NSMutableDictionary *plsMovieSettings = [[NSMutableDictionary alloc] init];
    plsMovieSettings[PLSAssetKey] = movieAsset;
    plsMovieSettings[PLSStartTimeKey] = [NSNumber numberWithFloat:0.f];
    plsMovieSettings[PLSDurationKey] = [NSNumber numberWithFloat:[self.recorder getTotalDuration]];
    plsMovieSettings[PLSVolumeKey] = [NSNumber numberWithFloat:1.0f];
    outputSettings[PLSMovieSettingsKey] = plsMovieSettings;
    
    QNEditorViewController *editorViewController = [[QNEditorViewController alloc] init];
    editorViewController.settings = outputSettings;
    editorViewController.fileURLs = fileURLs;
    [self presentViewController:editorViewController animated:YES completion:nil];
}

// ============================================ PLShortVideoRecorderDelegate ============================================
// 为了优化体验，建议开发者在使用七牛短视频 SDK 之前，都先将相机、麦克风和相册访问权限申请好
- (void)shortVideoRecorder:(PLShortVideoRecorder *__nonnull)recorder didGetCameraAuthorizationStatus:(PLSAuthorizationStatus)status {
    if (PLSAuthorizationStatusAuthorized == status) {
        [self.recorder startCaptureSession];
    }
}

- (void)shortVideoRecorder:(PLShortVideoRecorder *__nonnull)recorder didGetMicrophoneAuthorizationStatus:(PLSAuthorizationStatus)status {
    if (PLSAuthorizationStatusAuthorized == status) {
        [self.recorder startCaptureSession];
    }
}

- (void)shortVideoRecorder:(PLShortVideoRecorder *__nonnull)recorder didFocusAtPoint:(CGPoint)point {
    [self showFilterNameLabel];
}

- (CVPixelBufferRef)shortVideoRecorder:(PLShortVideoRecorder *)recorder cameraSourceDidGetPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    // 进行滤镜处理
    if (self.isPanning) {
        pixelBuffer = [self.filterGroup processPixelBuffer:pixelBuffer leftPercent:self.leftPercent leftFilter:self.leftFilter rightFilter:self.rightFilter];
    } else {
        pixelBuffer = [self.filterGroup.currentFilter process:pixelBuffer];
    }

    if (!self.forbidFaceUnity) {
        // FaceUnity 进行贴纸处理
        pixelBuffer = [[FUManager shareManager] renderItemsToPixelBuffer:pixelBuffer];
    }
    
    return pixelBuffer;
}

// 开始录制一段视频时
- (void)shortVideoRecorder:(PLShortVideoRecorder *)recorder didStartRecordingToOutputFileAtURL:(NSURL *)fileURL {
    NSLog(@"start recording fileURL: %@", fileURL);
    
    [self.recordingProgress setLastProgressToStyle:(enumProgressStyleNormal)];
    [self.recordingProgress addProgressView];
    [self.recordingProgress startShining];
    
    self.deleteLastButton.selected = NO;
    
    [self.topBarView alphaHideAnimation];
    [self.rightBarView alphaHideAnimation];
    [self.rateControl alphaHideAnimation];
    [self.deleteLastButton alphaHideAnimation];
}

// 正在录制的过程中
- (void)shortVideoRecorder:(PLShortVideoRecorder *)recorder didRecordingToOutputFileAtURL:(NSURL *)fileURL fileDuration:(CGFloat)fileDuration totalDuration:(CGFloat)totalDuration {
    [self.recordingProgress setLastProgressToWidth:fileDuration / self.recorder.maxDuration * self.recordingProgress.frame.size.width];
    self.durationLabel.text = [NSString stringWithFormat:@"%0.1f s", MAX(0, totalDuration)];
}

// 删除了某一段视频
- (void)shortVideoRecorder:(PLShortVideoRecorder *)recorder didDeleteFileAtURL:(NSURL *)fileURL fileDuration:(CGFloat)fileDuration totalDuration:(CGFloat)totalDuration {
    
    self.nextButton.hidden = NO;
    self.durationLabel.text = [NSString stringWithFormat:@"%0.1f s", MAX(0, totalDuration)];
}

// 完成一段视频的录制时
- (void)shortVideoRecorder:(PLShortVideoRecorder *)recorder didFinishRecordingToOutputFileAtURL:(NSURL *)fileURL fileDuration:(CGFloat)fileDuration totalDuration:(CGFloat)totalDuration {
    
    [self.recordingProgress stopShining];
    
    self.recordingButton.selected = NO;
    
    [self.deleteLastButton alphaShowAnimation];
    [self.topBarView alphaShowAnimation];
    [self.rightBarView alphaShowAnimation];
    [self.rateControl alphaShowAnimation];
    
    self.durationLabel.text = [NSString stringWithFormat:@"%0.1f s", MAX(0, totalDuration)];
    
    if (totalDuration >= self.recorder.maxDuration) {
        [self clickNextButton:nil];
    }
}

// 在达到指定的视频录制时间 maxDuration 后，如果再调用 [PLShortVideoRecorder startRecording]，直接执行该回调
- (void)shortVideoRecorder:(PLShortVideoRecorder *)recorder didFinishRecordingMaxDuration:(CGFloat)maxDuration {
    
    AVAsset *asset = self.recorder.assetRepresentingAllFiles;
    [self playEvent:asset];
    self.recordingButton.selected = NO;
}


// ================================================= 相芯科技贴纸 start =================================================
- (void)setupFaceUnity {

    // 加载相信科技的美颜道具, 只有加载之后，大眼、瘦脸的参数调节才生效
    [[FUManager shareManager] loadFilter];
    
    // 加载轻美妆
    [[FUManager shareManager] loadMakeupBundleWithName:@"light_makeup"];
    
    // 设置默认的美颜擦数
    [QNFaceUnityView setDefaultBeautyParams];
}

- (void)setupFaceUnityUI {
    if (self.faceUnityView) return;
    
    self.faceUnityView = [[QNFaceUnityView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 200)];
    self.faceUnityView.delegate = self;
    
    [self.view addSubview:self.faceUnityView];
    [self.faceUnityView mas_makeConstraints:^(MASConstraintMaker *make) {
        NSInteger height = self.faceUnityView.minViewHeight;
        make.bottom.left.right.equalTo(self.view);
        make.top.equalTo(self.mas_bottomLayoutGuide).offset(-height);
    }];
    [self.view layoutIfNeeded];
    [self.faceUnityView autoLayoutBottomHide:NO];
    [self.view layoutIfNeeded];
    
    [[FUManager shareManager] loadMakeupBundleWithName:@"light_makeup"];
}

- (void)clickFaceUnityButton:(UIButton *)button {
    
    [self setupFaceUnityUI];
    [self.view addSubview:self.dismissButton];
    [self.dismissButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.cameraButton.mas_bottom);
        make.bottom.equalTo(self.faceUnityView.mas_top);
    }];
    [self.faceUnityView autoLayoutBottomShow:YES];
    [self hideRecordingControl];
}

- (void)clickForbidFaceUnityButton:(UIButton *)button {
    self.forbidFaceUnity = !self.forbidFaceUnity;
    if (self.forbidFaceUnity) {
        [button setTitle:@"启用相芯" forState:(UIControlStateNormal)];
    } else {
        [button setTitle:@"禁用相芯" forState:(UIControlStateNormal)];
    }
}

// QNFaceUnityViewDelegate
- (void)faceUnityView:(QNFaceUnityView *)faceUnityView showTipString:(NSString *)tipString {
    if (nil == self.faceUnityTipLabel) {
        self.faceUnityTipLabel = [[UILabel alloc] init];
        self.faceUnityTipLabel.textColor = [UIColor whiteColor];
        self.faceUnityTipLabel.textAlignment = NSTextAlignmentCenter;
        self.faceUnityTipLabel.font = [UIFont systemFontOfSize:24];
        [self.view addSubview:self.faceUnityTipLabel];
        [self.faceUnityTipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self.view);
        }];
    }
    self.faceUnityTipLabel.text = tipString;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideTipLabel) object:nil];
    [self.faceUnityTipLabel alphaShowAnimation];
    [self performSelector:@selector(hideTipLabel) withObject:nil afterDelay:3];
}

- (void)hideTipLabel {
    [self.faceUnityTipLabel alphaHideAnimation];
}

// ============================================== 相芯科技贴纸 end =============================================
@end
