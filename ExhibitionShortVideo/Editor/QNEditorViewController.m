//
//  QNEditorViewController.m
//  ShortVideo
//
//  Created by hxiongan on 2019/4/9.
//  Copyright © 2019年 ahx. All rights reserved.
//

#import "QNEditorViewController.h"

#import <PLShortVideoKit/PLShortVideoKit.h>

#import "QNStickerOverlayView.h"
#import "QNStickerView.h"
#import "QNVerticalButton.h"
#import "QNGradientView.h"
#import "QNFilterPickerView.h"
#import "QNEditorMusicView.h"
#import "QNEditorStickerView.h"
#import "QNAudioVolumeView.h"
#import "QNPlayerViewController.h"

// TuSDK effect
#import <TuSDK/TuSDK.h>
#import <TuSDKVideo/TuSDKVideo.h>
#import "TuSDKConstants.h"
#import "EffectsView.h"
#import "FilterPanelView.h"

@interface QNEditorViewController ()
<
// 短视频
PLShortVideoEditorDelegate,
PLSAVAssetExportSessionDelegate,

// 上层 UI
QNStickerViewDelegate,
QNEditorMusicViewDelegate,
QNEditorStickerViewDelegate,
UIGestureRecognizerDelegate,
QNAudioVolumeViewDelegate,

// TuSDK mark
QNFilterPickerViewDelegate,
EffectsViewEventDelegate,
TuSDKFilterProcessorDelegate,
TuSDKFilterProcessorMediaEffectDelegate
>

@property (strong, nonatomic) NSURL *exportURL;
@property (strong, nonatomic) AVAsset *originAsset;

@property (nonatomic, strong) UIProgressView *playingProgressView;
@property (nonatomic, strong) UILabel *playingTimeLabel;
@property (strong, nonatomic) UIImageView *playImageView;

// 最终导出视频的宽高
@property (assign, nonatomic) CGSize outputSize;

// 顶部、底部
@property (strong, nonatomic) QNGradientView *bottomBarView;
@property (strong, nonatomic) UIScrollView *bottomScrollView;
@property (strong, nonatomic) QNGradientView *topBarView;

// 编辑预览
@property (strong, nonatomic) PLShortVideoEditor *shortVideoEditor;

// 编辑好之后，导出所用
@property (strong, nonatomic) NSMutableDictionary *outputSettings;
@property (strong, nonatomic) NSMutableDictionary *movieSettings;
@property (strong, nonatomic) NSMutableArray *audioSettingsArray;
@property (strong, nonatomic) NSMutableArray *watermarkSettingsArray;
@property (strong, nonatomic) NSMutableArray *stickerSettingsArray;

// 滤镜处理
@property (strong, nonatomic) QNFilterPickerView *filterView;
@property (strong, nonatomic) NSString *colorImagePath;

// MV 处理
@property (strong, nonatomic) NSMutableArray *mvArray;
@property (strong, nonatomic) NSURL *colorURL;
@property (strong, nonatomic) NSURL *alphaURL;

// 原视频编辑信息
@property (strong, nonatomic) NSMutableDictionary *originMovieSettings;

// GIF 动图处理
@property (strong, nonatomic) QNEditorStickerView *editorStickerView;
@property (strong, nonatomic) NSMutableArray *gifStickerModelArray;
@property (strong, nonatomic) QNStickerOverlayView *stickerOverlayView;
@property (strong, nonatomic) QNStickerView *currentStickerView;
@property (nonatomic, strong) UITapGestureRecognizer *tapGes;
@property (assign, nonatomic) CGPoint loc_in;
@property (nonatomic, nonatomic) CGPoint ori_center;
@property (nonatomic, nonatomic) CGFloat curScale;

// 音乐处理
@property (strong, nonatomic) QNEditorMusicView *musicView;
@property (assign, nonatomic) BOOL isNeedResumeEditing;

// 音量调节
@property (strong, nonatomic) QNAudioVolumeView *volumeView;
@property (assign, nonatomic) float musicVolume;


// 正在 seeking 的时候，不允许启动播放
@property (nonatomic, assign) BOOL isSeeking;

// 获取时间进度缩略图，多个编辑 view 公用，减小内存使用
@property (strong, nonatomic) NSMutableArray *thumbImageArray;

// ===============    特效   ============
#pragma mark - TuSDK
// TuSDK mark - 视频总时长，进入页面时，需设置改参数
@property (assign, nonatomic) CGFloat videoTotalTime;

//滤镜处理类
@property (nonatomic, strong) TuSDKFilterProcessor *filterProcessor;

// 场景特效视图
@property (nonatomic, strong) EffectsView *tuSDKEffectsView;
// 场景特效随机色数组
@property (nonatomic, strong) NSArray<UIColor *> *displayColors;

// 滤镜视图
@property (nonatomic, strong) FilterPanelView *tuSDKFilterView;

// 视频处理进度 0~1
@property (nonatomic, assign) CGFloat videoProgress;
// 当前使用的特效model  视频合成时使用
@property (nonatomic, assign) NSInteger effectsIndex;
// 正在切换滤镜 视频合成时使用
@property (nonatomic, assign) BOOL isSwitching;

// 当前正在编辑的特效
@property (nonatomic, strong) id<TuSDKMediaEffect> editingEffectData;
//当前获取的滤镜对象；
@property (nonatomic, strong) id<TuSDKMediaEffect> applyingEffectData;
// ===============    TuSDK   end ============
@end

@implementation QNEditorViewController


//类型识别:将 NSNull类型转化成 nil
- (id)checkNSNullType:(id)object {
    if([object isKindOfClass:[NSNull class]]) {
        return nil;
    }
    else {
        return object;
    }
}

- (void)getThumbImage {
    
    self.thumbImageArray = [[NSMutableArray alloc] init];
    
    CGFloat duration = CMTimeGetSeconds(self.originAsset.duration);
    NSUInteger count = duration;
    count = MIN(30, MAX(15, count));
    
    NSMutableArray *timeArray = [[NSMutableArray alloc] init];
    CGFloat delta = duration / count;
    for (int i = 0; i < count; i ++) {
        CMTime time = CMTimeMake(i * delta * 1000, 1000);
        NSValue *value = [NSValue valueWithCMTime:time];
        [timeArray addObject:value];
    }
    
    AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:self.originAsset];
    generator.requestedTimeToleranceAfter = CMTimeMake(200, 1000);
    generator.requestedTimeToleranceBefore = CMTimeMake(200, 1000);
    generator.appliesPreferredTrackTransform = YES;
    generator.maximumSize = CGSizeMake(100, 100);
    
    [generator generateCGImagesAsynchronouslyForTimes:timeArray completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
        if (image) {
            [self.thumbImageArray addObject:[UIImage imageWithCGImage:image]];
        }
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.isNeedResumeEditing = YES;
    
    // 用来演示如何获取视频的分辨率 videoSize
    NSDictionary *movieSettings = self.settings[PLSMovieSettingsKey];
    AVAsset *movieAsset = movieSettings[PLSAssetKey];
    if (!movieAsset) {
        NSURL *movieURL = movieSettings[PLSURLKey];
        movieAsset = [AVAsset assetWithURL:movieURL];
    }
    self.outputSize = movieAsset.pls_videoSize;
    self.originAsset = movieAsset;
    [self getThumbImage];

    [self setupTopBar];
    [self setupBottomBar];
    [self setupShortVideoEditor];
    [self setupGesture];

    // TuSDK mark 视频特效
    [self setupTuSDKFilter];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self observerUIApplicationStatusForShortVideoEditor];
    
    if (self.isNeedResumeEditing) {
        [self startEditing];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self removeObserverUIApplicationStatusForShortVideoEditor];
    
    self.isNeedResumeEditing = self.shortVideoEditor.isEditing;
    [self stopEditing];
    
}

#pragma mark - 编辑类
- (void)setupShortVideoEditor {
    // 编辑
    /* outputSettings 中的字典元素为 movieSettings, audioSettings, watermarkSettings, stickerSettingsArray*/
    self.outputSettings = [[NSMutableDictionary alloc] init];
    self.movieSettings = [[NSMutableDictionary alloc] init];
    self.watermarkSettingsArray = [[NSMutableArray alloc] init];
    self.stickerSettingsArray = [[NSMutableArray alloc] init];
    self.audioSettingsArray = [[NSMutableArray alloc] init];
    
    self.outputSettings[PLSMovieSettingsKey] = self.movieSettings;
    self.outputSettings[PLSWatermarkSettingsKey] = self.watermarkSettingsArray;
    self.outputSettings[PLSStickerSettingsKey] = self.stickerSettingsArray;
    self.outputSettings[PLSAudioSettingsKey] = self.audioSettingsArray;
    
    // 原始视频
    [self.movieSettings addEntriesFromDictionary:self.settings[PLSMovieSettingsKey]];
    self.movieSettings[PLSVolumeKey] = [NSNumber numberWithFloat:1.0];
    
    // 备份原始视频的信息
    self.originMovieSettings = [[NSMutableDictionary alloc] init];
    [self.originMovieSettings addEntriesFromDictionary:self.movieSettings];
    
    self.musicVolume = 1.0;
    
    // 视频编辑类
    AVAsset *asset = self.movieSettings[PLSAssetKey];
    self.shortVideoEditor = [[PLShortVideoEditor alloc] initWithAsset:asset videoSize:CGSizeZero];
    self.shortVideoEditor.delegate = self;
    self.shortVideoEditor.loopEnabled = YES;
    
    if (!CGSizeEqualToSize(CGSizeZero, self.originAsset.pls_videoSize)) {
        CGFloat viewRatio = self.view.bounds.size.width / self.view.bounds.size.height;
        CGFloat videoRatio = self.originAsset.pls_videoSize.width / self.originAsset.pls_videoSize.height;
        if (fabs(viewRatio - videoRatio) < 0.15) {
            // 在视频的宽高比例和 view 的宽高比例很接近的时候，使用 Fill 模式，UI 上看起来漂亮些，类似抖音
            self.shortVideoEditor.fillMode = PLSVideoFillModePreserveAspectRatioAndFill;
        } else {
            self.shortVideoEditor.fillMode = PLSVideoFillModePreserveAspectRatio;
        }
    }
    
    
    // 要处理的视频的时间区域
    CMTime start = CMTimeMake([self.movieSettings[PLSStartTimeKey] floatValue] * 1000, 1000);
    CMTime duration = CMTimeMake([self.movieSettings[PLSDurationKey] floatValue] * 1000, 1000);
    self.shortVideoEditor.timeRange = CMTimeRangeMake(start, duration);
    self.shortVideoEditor.videoSize = self.outputSize;
    
    [self.view insertSubview:self.shortVideoEditor.previewView atIndex:0];
    [self.shortVideoEditor.previewView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    UIImage *playImg = [UIImage imageNamed:@"qn_play"];
    self.playImageView = [[UIImageView alloc] initWithImage:playImg];
    [self.shortVideoEditor.previewView addSubview:self.playImageView];
    [self.playImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.shortVideoEditor.previewView);
        make.size.equalTo(playImg.size);
    }];
}

- (void)setupTimelineView {
   
}

- (void)setupEditDisplayView {
    
}

#pragma mark - UIGestureRecognizerDelegate 手势代理
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    
    NSMutableArray *classArray = [[NSMutableArray alloc] init];
    UIView *view = touch.view;
    while (view) {
        [classArray addObject:NSStringFromClass(view.class)];
        view = view.superview;
    }
    if ([classArray containsObject:NSStringFromClass(QNFilterPickerView.class)]) return NO;
    if ([classArray containsObject:NSStringFromClass(QNGradientView.class)]) return NO;
    if ([classArray containsObject:NSStringFromClass(QNEditorMusicView.class)]) return NO;
    if ([classArray containsObject:NSStringFromClass(QNAudioVolumeView.class)]) return NO;
    if ([classArray containsObject:NSStringFromClass(QNEditorStickerView.class)]) return NO;
    if ([classArray containsObject:NSStringFromClass(EffectsView.class)])return NO;
    if ([classArray containsObject:NSStringFromClass(FilterPanelView.class)]) return NO;

    return YES;
}

- (void)setupGesture {
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapHandle:)];
    singleTap.delegate = self;
    [self.view addGestureRecognizer:singleTap];
}

- (void)setupTopBar {
    
    self.topBarView = [[QNGradientView alloc] init];
    self.topBarView.gradienLayer.colors = @[(__bridge id)[[UIColor colorWithWhite:0 alpha:.8] CGColor], (__bridge id)[[UIColor clearColor] CGColor]];
    [self.view addSubview:self.topBarView];
    [self.topBarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.equalTo(self.view);
        make.bottom.equalTo(self.mas_topLayoutGuide).offset(50);
    }];
    
    UIButton *backButton = [UIButton buttonWithType:(UIButtonTypeSystem)];
    [backButton setTintColor:UIColor.whiteColor];
    [backButton setImage:[UIImage imageNamed:@"qn_icon_close"] forState:(UIControlStateNormal)];
    [backButton addTarget:self action:@selector(clickBackButton) forControlEvents:(UIControlEventTouchUpInside)];
    [self.topBarView addSubview:backButton];
    [backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.equalTo(CGSizeMake(44, 44));
        make.left.bottom.equalTo(self.topBarView);
    }];
    
    UIButton *nextButton = [[UIButton alloc] init];
    [nextButton setImage:[UIImage imageNamed:@"qn_next_button"] forState:(UIControlStateNormal)];
    [nextButton addTarget:self action:@selector(clickNextButton) forControlEvents:(UIControlEventTouchUpInside)];
    [nextButton sizeToFit];
    [self.topBarView addSubview:nextButton];
    [nextButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(backButton);
        make.size.equalTo(nextButton.bounds.size);
        make.right.equalTo(self.view).offset(-20);
    }];
    
    self.playingTimeLabel = [[UILabel alloc] init];
    self.playingTimeLabel.textAlignment = NSTextAlignmentCenter;
    self.playingTimeLabel.font = [UIFont monospacedDigitSystemFontOfSize:14 weight:(UIFontWeightRegular)];
    self.playingTimeLabel.textColor = [UIColor lightTextColor];
    [self.topBarView addSubview:self.playingTimeLabel];
    
    self.playingProgressView = [[UIProgressView alloc] initWithProgressViewStyle:(UIProgressViewStyleDefault)];
    [self.playingProgressView setTrackTintColor:UIColor.clearColor];
    [self.playingProgressView setProgressTintColor:UIColor.redColor];
    [self.topBarView addSubview:self.playingProgressView];
    
    [self.playingProgressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.topBarView);
        make.height.equalTo(2);
    }];
    [self.playingTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.topBarView);
        make.centerY.equalTo(backButton);
    }];
}

- (void)setupBottomBar {
#if 0
    int width = 44;
    int height = 60;
    int space = 25;
    
    self.bottomBarView = [[QNGradientView alloc] init];
    self.bottomBarView.gradienLayer.colors = @[(__bridge id)[[UIColor clearColor] CGColor], (__bridge id)[[UIColor colorWithWhite:0 alpha:.8] CGColor]];
    [self.view addSubview:self.bottomBarView];
    [self.bottomBarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
        make.top.equalTo(self.mas_bottomLayoutGuide).offset(-height - 10);
    }];
    
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    self.bottomScrollView = scrollView;
    scrollView.showsHorizontalScrollIndicator = NO;
    [self.bottomBarView addSubview:scrollView];
    [scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.equalTo(self.bottomBarView);
        make.height.equalTo(height);
    }];
    
    UIView* containerView = [[UIView alloc]init];
    [scrollView addSubview:containerView];

    UIButton* buttons[5];
    NSString *titles[] = {
        @"特效",
        @"滤镜",
        @"音乐",
        @"音量",
        @"动图",
    };
    
    NSString *imageNames[] = {
        @"qn_music", @"qn_music", @"qn_music", @"qn_music", @"qn_music", @"qn_music", @"qn_music"
    };
    
    SEL selectors[] = {
        @selector(clickTuSDKEffectsButton:),
        @selector(clickTuSDKFilterButton:),
        @selector(clickMusicButton:),
        @selector(clickVolumeButton:),
        @selector(clickGIFButton:),
    };
    
    int count = sizeof(titles)/sizeof(titles[0]);
    for (int i = 0; i < count; i ++) {
        UIButton *button = [[QNVerticalButton alloc] init];
        [button setTitle:titles[i] forState:(UIControlStateNormal)];
        [button setImage:[UIImage imageNamed:imageNames[i]] forState:(UIControlStateNormal)];
        [[button titleLabel] setFont:[UIFont systemFontOfSize:14]];
        [button addTarget:self action:selectors[i] forControlEvents:(UIControlEventTouchUpInside)];
        buttons[i] = button;
        
        [containerView addSubview:button];
    }
    
    [containerView makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(scrollView);
        make.height.equalTo(height);
        make.width.equalTo(count * (width + space) + 2 * space);
    }];
    
    NSArray *array = [NSArray arrayWithObjects:buttons count:count];
    [array mas_distributeViewsAlongAxis:(MASAxisTypeHorizontal) withFixedSpacing:space leadSpacing:space tailSpacing:space];
    [array mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(containerView);
    }];
    
#else
    int height = 60;
    self.bottomBarView = [[QNGradientView alloc] init];
    self.bottomBarView.gradienLayer.colors = @[(__bridge id)[[UIColor clearColor] CGColor], (__bridge id)[[UIColor colorWithWhite:0 alpha:.8] CGColor]];
    [self.view addSubview:self.bottomBarView];
    [self.bottomBarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
        make.top.equalTo(self.mas_bottomLayoutGuide).offset(-height - 10);
    }];

    UIButton* buttons[5];
    NSString *titles[] = {
        @"特效",
        @"滤镜",
        @"音乐",
        @"音量",
        @"动图",
    };
    
    NSString *imageNames[] = {
        @"qn_effect", @"qn_filter", @"qn_music", @"qn_volume", @"qn_gif"
    };

    
    SEL selectors[] = {
        @selector(clickTuSDKEffectsButton:),
        @selector(clickTuSDKFilterButton:),
        @selector(clickMusicButton:),
        @selector(clickVolumeButton:),
        @selector(clickGIFButton:),
    };
    
    int count = sizeof(titles)/sizeof(titles[0]);
    for (int i = 0; i < count; i ++) {
        UIButton *button = [[QNVerticalButton alloc] init];
        [button setTitle:titles[i] forState:(UIControlStateNormal)];
        [button setImage:[UIImage imageNamed:imageNames[i]] forState:(UIControlStateNormal)];
        [[button titleLabel] setFont:[UIFont systemFontOfSize:14]];
        [button addTarget:self action:selectors[i] forControlEvents:(UIControlEventTouchUpInside)];
        buttons[i] = button;
        
        [self.bottomBarView addSubview:button];
    }
    
    NSArray *array = [NSArray arrayWithObjects:buttons count:count];
    [array mas_distributeViewsAlongAxis:(MASAxisTypeHorizontal) withFixedSpacing:0 leadSpacing:20 tailSpacing:20];
    [array mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.bottomBarView);
        make.height.equalTo(height);
    }];
#endif
}

- (void)singleTapHandle:(UIGestureRecognizer *)gesture {
    
    if (self.isSeeking) return;
    
    if (self.musicView && [self viewIsShow:self.musicView]) {
        if ([self.musicView musicPickerViewIsShow]) {
            [self.musicView hideMusicPickerView];
            return;
        }
    }
    
    if (self.volumeView && [self viewIsShow:self.volumeView]) {
        [self hideView:self.volumeView update:YES];
        [self exitEditingMode];
        return;
    }
    
    if (self.filterView && [self viewIsShow:self.filterView]) {
        [self hideView:self.filterView update:YES];
        [self exitEditingMode];
        return;
    }
    
    if (self.tuSDKFilterView && [self viewIsShow:self.tuSDKFilterView]) {
        [self hideView:self.tuSDKFilterView update:YES];
        [self exitEditingMode];
        return;
    }

    if ([self.shortVideoEditor isEditing]) {
        [self stopEditing];
    } else {
        [self startEditing];
        
        self.currentStickerView.select = NO;
        [self.editorStickerView endStickerEditing:self.currentStickerView.stickerModel];
        self.currentStickerView = nil;
    }
}

- (BOOL)viewIsShow:(UIView *)view {
    return view.frame.origin.y < self.view.bounds.size.height;
}

- (void)showView:(UIView *)view update:(BOOL)update {
    if (view.frame.origin.y >= self.view.bounds.size.height) {
        [view autoLayoutBottomShow:update];
    }
}

- (void)hideView:(UIView *)view update:(BOOL)update {
    if (view.frame.origin.y < self.view.bounds.size.height) {
        [view autoLayoutBottomHide:update];
    }
}

- (void)entryEditingMode {
    [self.topBarView alphaHideAnimation];
    [self.bottomBarView alphaHideAnimation];
}

- (void)exitEditingMode {
    [self.topBarView alphaShowAnimation];
    [self.bottomBarView alphaShowAnimation];
}

- (void)clickFilterButton:(UIButton *)button {
    
    if (!self.filterView) {
        
        self.filterView = [[QNFilterPickerView alloc] init];
        self.filterView.delegate = self;
        self.filterView.hidden = YES;
        [self.view addSubview:self.filterView];
        
        [self.filterView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.left.right.equalTo(self.view);
            make.top.equalTo(self.mas_bottomLayoutGuide).offset(-self.filterView.minViewHeight);
        }];
        [self.view layoutIfNeeded];
        [self.filterView autoLayoutBottomHide:NO];
        [self.view layoutIfNeeded];
        self.filterView.hidden = NO;
    }
    
    [self showView:self.filterView update:YES];
    [self entryEditingMode];
}

- (void)clickMusicButton:(UIButton *)button {
    if (!self.musicView) {
        self.musicView = [[QNEditorMusicView alloc] initWithThumbImage:self.thumbImageArray videoDuration:self.originAsset.duration];
        self.musicView.delegate = self;
        self.musicView.hidden = YES;
        [self.view addSubview:self.musicView];
        
        [self.musicView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.left.right.equalTo(self.view);
            make.top.equalTo(self.mas_bottomLayoutGuide).offset(-self.musicView.minViewHeight);
        }];
        [self.view layoutIfNeeded];
        [self.musicView autoLayoutBottomHide:NO];
        [self.view layoutIfNeeded];
        self.musicView.hidden = NO;
    }
    
    [self showView:self.musicView update:YES];
    [self entryEditingMode];
    [self stopEditing];
    [self.shortVideoEditor seekToTime:kCMTimeZero completionHandler:nil];
    [self.musicView setPlayingTime:kCMTimeZero];
}

- (void)clickVolumeButton:(UIButton *)button {
    if (!self.volumeView) {
        self.volumeView = [[QNAudioVolumeView alloc] init];
        self.volumeView.delegate = self;
        self.volumeView.hidden = YES;
        [self.view addSubview:self.volumeView];
        
        [self.volumeView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.left.right.equalTo(self.view);
            make.top.equalTo(self.mas_bottomLayoutGuide).offset(-self.volumeView.minViewHeight);
        }];
        [self.view layoutIfNeeded];
        [self.volumeView autoLayoutBottomHide:NO];
        [self.view layoutIfNeeded];
        self.volumeView.hidden = NO;
    }
    
    [self.volumeView setMusicSliderEnable:self.audioSettingsArray.count > 0];
    [self showView:self.volumeView update:YES];
    [self entryEditingMode];
}

- (void)clickGIFButton:(UIButton *)button {
    if (!self.editorStickerView) {
        
        self.editorStickerView = [[QNEditorStickerView alloc] initWithThumbImage:self.thumbImageArray videoDuration:self.originAsset.duration];
        self.editorStickerView.delegate = self;
        self.editorStickerView.hidden = YES;
        [self.view addSubview:self.editorStickerView];
        
        self.stickerOverlayView = [[QNStickerOverlayView alloc] init];
        [self.shortVideoEditor.previewView insertSubview:self.stickerOverlayView atIndex:0];
        
        self.gifStickerModelArray = [[NSMutableArray alloc] init];
        
        [self.editorStickerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.left.right.equalTo(self.view);
            make.top.equalTo(self.mas_bottomLayoutGuide).offset(-self.editorStickerView.minViewHeight);
        }];
        
        [self.stickerOverlayView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.shortVideoEditor.previewView);
        }];
        
        [self.view layoutIfNeeded];
        [self.editorStickerView autoLayoutBottomHide:NO];
        [self.view layoutIfNeeded];
        self.editorStickerView.hidden = NO;
    }
    
    [self.shortVideoEditor stopEditing];
    [self.shortVideoEditor seekToTime:kCMTimeZero completionHandler:nil];
    [self.editorStickerView setPlayingTime:kCMTimeZero];
    
    [self showView:self.editorStickerView update:YES];
    [self entryEditingMode];
    [self.playImageView scaleShowAnimation];
    
    // 启动加在贴纸上的手势
    for (UIView *stickerView in self.stickerOverlayView.subviews) {
        if (![stickerView isKindOfClass:QNStickerView.class]) continue;
        for (UIGestureRecognizer *gesture in stickerView.gestureRecognizers) {
            gesture.enabled = YES;
        }
    }
}

- (void)startEditing {
    if (!self.shortVideoEditor.isEditing) {
        [self.shortVideoEditor startEditing];
    }
    [self.playImageView scaleHideAnimation];
}

- (void)stopEditing {
    if (self.shortVideoEditor.isEditing) {
        [self.shortVideoEditor stopEditing];
    }
    [self.playImageView scaleShowAnimation];
}

#pragma mark - 视频倍速资源
- (NSMutableArray *)videoSpeedArray {
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    NSArray *nameArray = @[@"极慢", @"慢", @"正常", @"快", @"极快", @"多段变速"];
    NSArray *dirArray = @[@"jiman", @"man", @"zhengchang", @"kuai", @"jikuai", @"mulitRate"];
    
    for (int i = 0; i < nameArray.count; i++) {
        NSString *name = nameArray[i];
        NSString *coverDir = [[NSBundle mainBundle] pathForResource:dirArray[i] ofType:@"png"];
        
        NSDictionary *dic = @{
                              @"name"     : name,
                              @"coverDir" : coverDir,
                              };
        [array addObject:dic];
    }
    
    return array;
}

#pragma mark - 获取音乐文件的封面
- (UIImage *)musicImageWithMusicURL:(NSURL *)url {
    NSData *data = nil;
    // 初始化媒体文件
    AVURLAsset *mp3Asset = [AVURLAsset URLAssetWithURL:url options:nil];
    // 读取文件中的数据
    for (NSString *format in [mp3Asset availableMetadataFormats]) {
        for (AVMetadataItem *metadataItem in [mp3Asset metadataForFormat:format]) {
            //artwork这个key对应的value里面存的就是封面缩略图，其它key可以取出其它摘要信息，例如title - 标题
            if ([metadataItem.commonKey isEqualToString:@"artwork"]) {
                data = (NSData *)metadataItem.value;
                
                break;
            }
        }
    }
    if (!data) {
        // 如果音乐没有图片，就返回默认图片
        return [UIImage imageNamed:@"music"];
    }
    return [UIImage imageWithData:data];
}


#pragma mark - 添加/更新 MV 特效、滤镜、背景音乐 等效果
- (void)addMVLayerWithColor:(NSURL *)colorURL alpha:(NSURL *)alphaURL {
    // 添加／移除 MV 特效
    self.colorURL = colorURL;
    self.alphaURL = alphaURL;
    
    // 添加了 MV 特效，就需要让原视频和 MV 特效视频的分辨率相同
    if (self.colorURL && self.alphaURL) {
        AVAsset *asset = [AVAsset assetWithURL:self.colorURL];
        NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
        if (videoTracks.count > 0) {
            AVAssetTrack *videoTrack = videoTracks[0];
            CGSize naturalSize = videoTrack.naturalSize;
            self.outputSize = CGSizeMake(naturalSize.width, naturalSize.height);
            self.shortVideoEditor.videoSize = self.outputSize;
//            [self updateQNStickerOverlayView:asset];
        }
    } else {
        self.outputSize = [self.movieSettings[PLSAssetKey] pls_videoSize];
        self.shortVideoEditor.videoSize = self.outputSize;
//        [self updateQNStickerOverlayView:self.movieSettings[PLSAssetKey]];
    }
    
    [self.shortVideoEditor addMVLayerWithColor:self.colorURL alpha:self.alphaURL timeRange:kCMTimeRangeZero loopEnable:YES];
//    if (![self.shortVideoEditor isEditing]) {
//        [self.shortVideoEditor startEditing];
//    }
    [self startEditing];
}

- (void)addFilter:(NSString *)colorImagePath {
    // 添加／移除 滤镜
    self.colorImagePath = colorImagePath;
    
    [self.shortVideoEditor addFilter:self.colorImagePath];
}

// QNFilterPickerViewDelegate
- (void)filterView:(QNFilterPickerView *)filterView didSelectedFilter:(NSString *)colorImagePath {
    [self addFilter:colorImagePath];
}

// QNAudioVolumeViewDelegate
- (void)audioVolumeView:(QNAudioVolumeView *)audioVolumeView videoVolumeChange:(float)videoVolume {
    self.movieSettings[PLSVolumeKey] = [NSNumber numberWithFloat:videoVolume];
    self.shortVideoEditor.volume = videoVolume;
}

- (void)audioVolumeView:(QNAudioVolumeView *)audioVolumeView musicVolumeChange:(float)musicVolume {
    
    if (fabs(self.musicVolume - musicVolume) < FLT_EPSILON) return;
    
    if (self.audioSettingsArray.count) {
        self.musicVolume = musicVolume;
        for (NSMutableDictionary *dic in self.audioSettingsArray) {
            dic[PLSVolumeKey] = [NSNumber numberWithFloat:musicVolume];
        }
        [self.shortVideoEditor updateMultiMusics:self.audioSettingsArray keepMoviePlayerStatus:YES];
    }
}

// ============= QNEditorMusicViewDelegate
- (void)editorMusicViewWillBeginDragging:(QNEditorMusicView *)musicView {
    self.isSeeking = YES;
    [self stopEditing];
}

- (void)editorMusicViewWillEndDragging:(QNEditorMusicView *)musicView {
    self.isSeeking = NO;
    if (![self viewIsShow:self.musicView]) {
        [self startEditing];
    }
}

- (void)editorMusicViewWillShowPickerMusicView:(QNEditorMusicView *)musicView {
    [self stopEditing];
}

- (void)editorMusicViewWillHidePickerMusicView:(QNEditorMusicView *)musicView {

}

- (void)editorMusicViewDoneButtonClick:(QNEditorMusicView *)musicView {
    [self exitEditingMode];
    [self hideView:musicView update:YES];
    if (!self.isSeeking) {
        [self startEditing];
    }
}

- (void)editorMusicView:(QNEditorMusicView *)musciView wantSeekPlayerTo:(CMTime)time {
    [self.shortVideoEditor seekToTime:time completionHandler:^(BOOL finished) {}];
}

- (void)editorMusicView:(QNEditorMusicView *)musciView updateMusicInfo:(NSArray<QNMusicModel *> *)musicModelArray {
    
    [self.audioSettingsArray removeAllObjects];
    
    for (int i = 0; i < musicModelArray.count; i ++) {
        QNMusicModel *model = [musicModelArray objectAtIndex:i];
        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
        dic[PLSURLKey] = model.musicURL;
        dic[PLSVolumeKey] = [NSNumber numberWithFloat:self.musicVolume];
        dic[PLSNameKey] = model.musicName;
        // 音乐的剪裁
        dic[PLSStartTimeKey] = [NSNumber numberWithFloat:CMTimeGetSeconds(model.startTime)];
        dic[PLSDurationKey] = [NSNumber numberWithFloat:CMTimeGetSeconds(CMTimeSubtract(model.endTime, model.startTime))];
        
        // 音乐插入到视频中的时间点
        dic[PLSLocationStartTimeKey] = [NSNumber numberWithFloat:CMTimeGetSeconds(model.startPositionTime)];
        // 这个值可以大于 PLSDurationKey，这样的话，音乐会被循环添加
        dic[PLSLocationDurationKey] = [NSNumber numberWithFloat:CMTimeGetSeconds(CMTimeSubtract(model.endPositiontime, model.startPositionTime))];
        
        [self.audioSettingsArray addObject:dic];
    }
    
    // keepMoviePlayerStatus = YES 的话，不会改变播放状态，否则会自动开始播放
    [self.shortVideoEditor updateMultiMusics:self.audioSettingsArray keepMoviePlayerStatus:YES];
}

// ===== StickerViewDelegate
- (void)stickerViewClose:(QNStickerView *)stickerView {
    [stickerView removeFromSuperview];
    [self.editorStickerView endStickerEditing:stickerView.stickerModel];
    [self.editorStickerView  deleteSticker:stickerView.stickerModel];
}

// ===== QNEditorStickerViewDelegate
- (void)editorStickerViewWillBeginDragging:(QNEditorStickerView *)editorStickerView {
    self.isSeeking = YES;
    [self stopEditing];
}

- (void)editorStickerViewWillEndDragging:(QNEditorStickerView *)editorStickerView {
    self.isSeeking = NO;
    if (![self viewIsShow:self.editorStickerView]) {
        [self startEditing];
    }
}

- (void)editorStickerViewDoneButtonClick:(QNEditorStickerView *)editorStickerView {
    [self exitEditingMode];
    [self hideView:editorStickerView update:YES];
    if (!self.isSeeking) {
        [self startEditing];
    }
    
    [self.editorStickerView endStickerEditing:self.currentStickerView.stickerModel];
    self.currentStickerView.select = NO;
    self.currentStickerView = nil;

    //  禁用加在贴纸上的手势
    for (UIView *stickerView in self.stickerOverlayView.subviews) {
        if (![stickerView isKindOfClass:QNStickerView.class]) continue;
        for (UIGestureRecognizer *gesture in stickerView.gestureRecognizers) {
            gesture.enabled = NO;
        }
    }
}

- (void)editorStickerView:(QNEditorStickerView *)editorStickerView wantSeekPlayerTo:(CMTime)time {
    [self.shortVideoEditor seekToTime:time completionHandler:^(BOOL finished) {}];
}

- (void)editorStickerView:(QNEditorStickerView *)editorStickerView wantEntryEditing:(QNStickerModel *)model {
    
    if (model.stickerView != _currentStickerView) {
        [self stopEditing];
        
        [self.editorStickerView endStickerEditing:_currentStickerView.stickerModel];
        
        _currentStickerView.select = NO;
        model.stickerView.select = YES;
        _currentStickerView = model.stickerView;
        if (_currentStickerView.hidden) {
            [self.shortVideoEditor seekToTime:model.startPositionTime completionHandler:^(BOOL finished) {
            }];
        }
        
        [self.editorStickerView startStickerEditing:_currentStickerView.stickerModel];
    }
}

- (void)editorStickerView:(QNEditorStickerView *)editorStickerView addGifSticker:(QNStickerModel *)model {
    
    [self stopEditing];
    
    // 1. 创建贴纸
    QNStickerView *stickerView = [[QNStickerView alloc] initWithStickerModel:model];
    stickerView.delegate = self;
    
    _currentStickerView.select = NO;
    stickerView.select = YES;
    _currentStickerView = stickerView;
    model.stickerView = stickerView;
    // 2. 添加至stickerOverlayView上
    [self.stickerOverlayView addSubview:stickerView];
    
    UIImage *image = [UIImage imageWithContentsOfFile:model.path];
    stickerView.frame = CGRectMake((self.stickerOverlayView.frame.size.width - image.size.width * 0.5) * 0.5,
                                   (self.stickerOverlayView.frame.size.height - image.size.height * 0.5) * 0.5,
                                   image.size.width * 0.5,
                                   image.size.height * 0.5);
    
    UIPanGestureRecognizer *panGes = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveGestureRecognizerEvent:)];
    [stickerView addGestureRecognizer:panGes];
    UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognizerEvent:)];
    [stickerView addGestureRecognizer:tapGes];
    UIPinchGestureRecognizer *pinGes = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGestureRecognizerEvent:)];
    [stickerView addGestureRecognizer:pinGes];
    [stickerView.dragBtn addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(scaleAndRotateGestureRecognizerEvent:)]];
    
    [self.editorStickerView startStickerEditing:_currentStickerView.stickerModel];
}

- (void)moveGestureRecognizerEvent:(UIPanGestureRecognizer *)panGes {
    
    if ([[panGes view] isKindOfClass:[QNStickerView class]]){
        CGPoint loc = [panGes locationInView:self.view];
        QNStickerView *view = (QNStickerView *)[panGes view];
        if (_currentStickerView.select) {
            if ([_currentStickerView pointInside:[_currentStickerView convertPoint:loc fromView:self.view] withEvent:nil]){
                view = _currentStickerView;
            }
        }
        if (!view.select) return;
        
        if (panGes.state == UIGestureRecognizerStateBegan) {
            _loc_in = [panGes locationInView:self.view];
            _ori_center = view.center;
        }
        
        CGFloat x;
        CGFloat y;
        x = _ori_center.x + (loc.x - _loc_in.x);
        
        y = _ori_center.y + (loc.y - _loc_in.y);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0 animations:^{
                view.center = CGPointMake(x, y);
            }];
        });
    }
}

- (void)tapGestureRecognizerEvent:(UITapGestureRecognizer *)tapGes {
    
    if ([[tapGes view] isKindOfClass:[QNStickerView class]]){
        if ([self viewIsShow:self.editorStickerView]) {
            [self clickGIFButton:nil];
        }
        
        QNStickerView *view = (QNStickerView *)[tapGes view];

        if (view != _currentStickerView) {
            [self.editorStickerView endStickerEditing:_currentStickerView.stickerModel];
            
            _currentStickerView.select = NO;
            view.select = YES;
            _currentStickerView = view;
            
            [self.editorStickerView startStickerEditing:_currentStickerView.stickerModel];
        } else {
            view.select = !view.select;
            if (view.select) {
                _currentStickerView = view;
                [self.editorStickerView startStickerEditing:_currentStickerView.stickerModel];
            }else {
                [self.editorStickerView endStickerEditing:_currentStickerView.stickerModel];
                _currentStickerView = nil;
            }
        }
    }
}

- (void)pinchGestureRecognizerEvent:(UIPinchGestureRecognizer *)pinGes {
    
    if ([[pinGes view] isKindOfClass:[QNStickerView class]]){
        QNStickerView *view = (QNStickerView *)[pinGes view];
        
        if (!view.select) return;
        
        if (pinGes.state ==UIGestureRecognizerStateBegan) {
            view.oriTransform = view.transform;
        }
        
        if (pinGes.state ==UIGestureRecognizerStateChanged) {
            _curScale = pinGes.scale;
            CGAffineTransform tr = CGAffineTransformScale(view.oriTransform, pinGes.scale, pinGes.scale);
            
            view.transform = tr;
        }
        
        // 当手指离开屏幕时,将lastscale设置为1.0
        if ((pinGes.state == UIGestureRecognizerStateEnded) || (pinGes.state == UIGestureRecognizerStateCancelled)) {
            view.oriScale = view.oriScale * _curScale;
            pinGes.scale = 1;
        }
    }
}

- (void)scaleAndRotateGestureRecognizerEvent:(UIPanGestureRecognizer *)gesture {
    if (_currentStickerView.isSelected) {
        CGPoint curPoint = [gesture locationInView:self.view];
        if (gesture.state == UIGestureRecognizerStateBegan) {
            _loc_in = [gesture locationInView:self.view];
        }
        
        if (gesture.state == UIGestureRecognizerStateBegan) {
            _currentStickerView.oriTransform = _currentStickerView.transform;
        }
        
        // 计算缩放
        CGFloat preDistance = [self getDistance:_loc_in withPointB:_currentStickerView.center];
        CGFloat curDistance = [self getDistance:curPoint withPointB:_currentStickerView.center];
        CGFloat scale = curDistance / preDistance;
        // 计算弧度
        CGFloat preRadius = [self getRadius:_currentStickerView.center withPointB:_loc_in];
        CGFloat curRadius = [self getRadius:_currentStickerView.center withPointB:curPoint];
        CGFloat radius = curRadius - preRadius;
        radius = - radius;
        CGAffineTransform transform = CGAffineTransformScale(_currentStickerView.oriTransform, scale, scale);
        _currentStickerView.transform = CGAffineTransformRotate(transform, radius);
        
        if (gesture.state == UIGestureRecognizerStateEnded ||
            gesture.state == UIGestureRecognizerStateCancelled) {
            _currentStickerView.oriScale = scale * _currentStickerView.oriScale;
        }
    }
}

// 距离
- (CGFloat)getDistance:(CGPoint)pointA withPointB:(CGPoint)pointB {
    CGFloat x = pointA.x - pointB.x;
    CGFloat y = pointA.y - pointB.y;
    
    return sqrt(x*x + y*y);
}

// 角度
- (CGFloat)getRadius:(CGPoint)pointA withPointB:(CGPoint)pointB {
    CGFloat x = pointA.x - pointB.x;
    CGFloat y = pointA.y - pointB.y;
    return atan2(x, y);
}

/// 根据速率配置相应倍速后的视频时长
- (CGFloat)getRateNumberWithRateType:(PLSVideoRecoderRateType)rateType {
    CGFloat scaleFloat = 1.0;
    switch (rateType) {
        case PLSVideoRecoderRateNormal:
            scaleFloat = 1.0;
            break;
        case PLSVideoRecoderRateSlow:
            scaleFloat = 1.5;
            break;
        case PLSVideoRecoderRateTopSlow:
            scaleFloat = 2.0;
            break;
        case PLSVideoRecoderRateFast:
            scaleFloat = 0.666667;
            break;
        case PLSVideoRecoderRateTopFast:
            scaleFloat = 0.5;
            break;
        default:
            break;
    }
    return scaleFloat;
}

#pragma mark - 返回
- (void)clickBackButton {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)needExport {
    if (1 == self.fileURLs.count && // 只有一个视频文件
        0 == self.stickerOverlayView.subviews.count && // 无贴纸
        0 == self.audioSettingsArray.count && // 无音乐
        0 == [self.filterProcessor mediaEffects].count && // 无滤镜，特效
        fabs([self.movieSettings[PLSVolumeKey] doubleValue] - 1.0) < FLT_EPSILON // 原视频音量没有调整
        ) {
        return NO;
    }
    return YES;
}

#pragma mark - 下一步
- (void)clickNextButton {
    
    [self stopEditing];
    
    if (![self needExport]) {
        // 根本就没有做任何编辑，并且录制的时候，不是分段录制的，直接进入下一个页面
        NSURL *url = self.fileURLs.firstObject;
        UISaveVideoAtPathToSavedPhotosAlbum(url.path, nil, nil, nil);
        [self gotoNextController:self.fileURLs.firstObject];
        return;
    }
    
    if (self.exportURL) {
        // 删除上一次导出的视频
        [[NSFileManager defaultManager] removeItemAtURL:self.exportURL error:nil];
        self.exportURL = nil;
    }
    
    // 贴纸信息
    [self.stickerSettingsArray removeAllObjects];
    
    // TuSDK mark 导出带视频特效的视频时，先重置标记位
    [self resetExportVideoEffectsMark];
    // TuSDK end
    
    // 贴纸信息
    for (int i = 0; i < self.stickerOverlayView.subviews.count; i++) {
        QNStickerView *stickerView = self.stickerOverlayView.subviews[i];
        QNStickerModel *stickerModel = stickerView.stickerModel;
        
        NSMutableDictionary *stickerSettings = [[NSMutableDictionary alloc] init];
        
        CGAffineTransform transform = stickerView.transform;
        CGFloat widthScale = sqrt(transform.a * transform.a + transform.c * transform.c);
        CGFloat heightScale = sqrt(transform.b * transform.b + transform.d * transform.d);
        CGSize viewSize = CGSizeMake(stickerView.bounds.size.width * widthScale, stickerView.bounds.size.height * heightScale);
        CGPoint viewCenter =  CGPointMake(stickerView.frame.origin.x + stickerView.frame.size.width / 2, stickerView.frame.origin.y + stickerView.frame.size.height / 2);
        CGPoint viewPoint = CGPointMake(viewCenter.x - viewSize.width / 2, viewCenter.y - viewSize.height / 2);
        
        stickerSettings[PLSSizeKey] = [NSValue valueWithCGSize:viewSize];
        stickerSettings[PLSPointKey] = [NSValue valueWithCGPoint:viewPoint];
        
        CGFloat rotation = atan2f(transform.b, transform.a);
        rotation = rotation * (180 / M_PI);
        stickerSettings[PLSRotationKey] = [NSNumber numberWithFloat:rotation];
        
        stickerSettings[PLSStartTimeKey] = [NSNumber numberWithFloat:CMTimeGetSeconds(stickerModel.startPositionTime)];
        stickerSettings[PLSDurationKey] = [NSNumber numberWithFloat:CMTimeGetSeconds(CMTimeSubtract(stickerModel.endPositiontime, stickerModel.startPositionTime))];
        stickerSettings[PLSVideoPreviewSizeKey] = [NSValue valueWithCGSize:self.stickerOverlayView.frame.size];
        stickerSettings[PLSVideoOutputSizeKey] = [NSValue valueWithCGSize:self.outputSize];
        stickerSettings[PLSStickerKey] = stickerModel.path;
        
        stickerView.hidden = YES;
        
        [self.stickerSettingsArray addObject:stickerSettings];
    }
    
    AVAsset *asset = self.movieSettings[PLSAssetKey];
    PLSAVAssetExportSession *exportSession = [[PLSAVAssetExportSession alloc] initWithAsset:asset];
    exportSession.outputFileType = PLSFileTypeMPEG4;
    exportSession.shouldOptimizeForNetworkUse = YES;
    exportSession.outputSettings = self.outputSettings;
    exportSession.delegate = self;
    exportSession.isExportMovieToPhotosAlbum = YES;// 保存到相册
    exportSession.audioChannel = 2;
    exportSession.audioBitrate = [QNBaseViewController suitableAudioBitrateWithSampleRate:asset.pls_sampleRate channel:2];
    exportSession.outputVideoFrameRate = MIN(60, asset.pls_normalFrameRate);
    exportSession.outputVideoSize = self.outputSize;
    
    // 旋转视频
//    exportSession.videoLayerOrientation = self.videoLayerOrientation;
    if (self.colorImagePath) {
        [exportSession addFilter:self.colorImagePath];
    }
    if (self.colorURL && self.alphaURL) {
        [exportSession addMVLayerWithColor:self.colorURL alpha:self.alphaURL timeRange:kCMTimeRangeZero loopEnable:YES];
    }
    
    [self showWating];
    __weak typeof(self) weakSelf = self;
    [exportSession setCompletionBlock:^(NSURL *url) {
        NSLog(@"Asset Export Completed");
        // TuSDK mark 视频特效预览，先重置标记位
        [weakSelf resetPreviewVideoEffectsMark];
        // TuSDK end
        
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.exportURL = url;
            [weakSelf hideWating];
            [weakSelf gotoNextController:url];
        });
    }];
    
    [exportSession setFailureBlock:^(NSError *error) {
        NSLog(@"Asset Export Failed: %@", error);
        
        // TuSDK mark 视频特效预览，先重置标记位
        [weakSelf resetPreviewVideoEffectsMark];
        // TuSDK end
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf hideWating];
            [weakSelf showAlertMessage:@"错误" message:error.description];
        });
    }];
    
    [exportSession setProcessingBlock:^(float progress) {
        // 更新进度 UI
        NSLog(@"Asset Export Progress: %f", progress);
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf setProgress:progress];
        });
    }];
    
    [exportSession exportAsynchronously];
}

- (void)gotoNextController:(NSURL *)url {
    QNPlayerViewController *vc = [[QNPlayerViewController alloc] init];
    vc.url = url;
    [self presentViewController:vc animated:YES completion:nil];
}

#pragma mark - 程序的状态监听
- (void)observerUIApplicationStatusForShortVideoEditor {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shortVideoEditorWillResignActiveEvent:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shortVideoEditorDidBecomeActiveEvent:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)removeObserverUIApplicationStatusForShortVideoEditor {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)shortVideoEditorWillResignActiveEvent:(id)sender {
    NSLog(@"[self.shortVideoEditor UIApplicationWillResignActiveNotification]");
    [self stopEditing];
}

- (void)shortVideoEditorDidBecomeActiveEvent:(id)sender {
    NSLog(@"[self.shortVideoEditor UIApplicationDidBecomeActiveNotification]");
//    [self.shortVideoEditor startEditing];
//    [self.playImageView scaleHideAnimation];
}

#pragma mark - PLShortVideoEditorDelegate 编辑时处理视频数据，并将加了滤镜效果的视频数据返回
- (CVPixelBufferRef)shortVideoEditor:(PLShortVideoEditor *)editor didGetOriginPixelBuffer:(CVPixelBufferRef)pixelBuffer timestamp:(CMTime)timestamp {
    
    // TuSDK mark
    self.videoProgress = CMTimeGetSeconds(timestamp) / self.videoTotalTime;
    pixelBuffer = [self.filterProcessor syncProcessPixelBuffer:pixelBuffer frameTime:timestamp];
    [self.filterProcessor destroyFrameData];
    // TuSDK mark end
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        self.playingTimeLabel.text = [self formatTimeString:CMTimeGetSeconds(timestamp)];
        self.playingProgressView.progress = CMTimeGetSeconds(timestamp) / CMTimeGetSeconds(self.originAsset.duration);
        
        if ([self viewIsShow:self.musicView]) {
            [self.musicView setPlayingTime:timestamp];
        }
        if ([self viewIsShow:self.editorStickerView]) {
            [self.editorStickerView setPlayingTime:timestamp];
        }
        
        // 更新贴纸的时间线视图
        for (int i = 0; i < self.editorStickerView.addedStickerModelArray.count; i ++) {
            QNStickerModel *stickerModel = [self.editorStickerView.addedStickerModelArray objectAtIndex:i];
            if (CMTimeCompare(stickerModel.startPositionTime, timestamp) <= 0 &&
                CMTimeCompare(stickerModel.endPositiontime, timestamp) >= 0) {
                if (stickerModel.stickerView.isHidden) {
                    stickerModel.stickerView.hidden = NO;
                }
            } else {
                if (!stickerModel.stickerView.isHidden) {
                    stickerModel.stickerView.hidden = YES;
                }
            }
        }
        
        // TuSDK mark
        [self.tuSDKEffectsView.displayView updateLastSegmentViewProgress:self.videoProgress];
        self.tuSDKEffectsView.displayView.currentLocation = self.videoProgress;
        // TuSDK mark end
    });

    return pixelBuffer;
}

- (void)shortVideoEditor:(PLShortVideoEditor *)editor didReadyToPlayForAsset:(AVAsset *)asset timeRange:(CMTimeRange)timeRange {
    NSLog(@"%s, line:%d", __FUNCTION__, __LINE__);
    
    // TuSDK mark
    self.videoProgress = 0.0;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.playImageView scaleHideAnimation];
    });
}

- (void)shortVideoEditor:(PLShortVideoEditor *)editor didReachEndForAsset:(AVAsset *)asset timeRange:(CMTimeRange)timeRange {
    NSLog(@"%s, line:%d", __FUNCTION__, __LINE__);
    
    // =============    TuSDK mark
    self.videoProgress = 1.0;
    [self endCurrentEffect:self.originAsset.duration];
    // =============    TuSDK end
}

#pragma mark -  PLSAVAssetExportSessionDelegate 合成视频文件给视频数据加滤镜效果的回调
- (CVPixelBufferRef)assetExportSession:(PLSAVAssetExportSession *)assetExportSession didOutputPixelBuffer:(CVPixelBufferRef)pixelBuffer timestamp:(CMTime)timestamp {
    
    CVPixelBufferRef tempPixelBuffer = pixelBuffer;
    
    // TuSDK mark
    tempPixelBuffer = [self.filterProcessor syncProcessPixelBuffer:pixelBuffer frameTime:timestamp];
    [self.filterProcessor destroyFrameData];
    // TuSDK end
    
    return tempPixelBuffer;
}

#pragma mark - dealloc
- (void)dealloc {
    self.shortVideoEditor.delegate = nil;
    self.shortVideoEditor = nil;
    if (self.exportURL) {
        [[NSFileManager defaultManager] removeItemAtURL:self.exportURL error:nil];
        self.exportURL = nil;
    }
    NSLog(@"dealloc: %@", [[self class] description]);
}


//================================================== 涂图特效 start =================================================

// 图涂滤镜，七牛短视频 app UI 上没有显示，有需要的开发者可以作为参考
- (void)clickTuSDKFilterButton:(UIButton *)button {
    [self showTuSDKFiterView];
}

// 图涂特效
- (void)clickTuSDKEffectsButton:(UIButton *)button {
    [self showTuSDKEffectsView];
}

// 设置 TuSDK
- (void)setupTuSDKFilter {
    // 视频总时长
    self.videoTotalTime = CMTimeGetSeconds(self.originAsset.duration);
    
    // 传入图像的方向是否为原始朝向(相机采集的原始朝向)，SDK 将依据该属性来调整人脸检测时图片的角度。如果没有对图片进行旋转，则为 YES
    BOOL isOriginalOrientation = NO;
    
    self.filterProcessor = [[TuSDKFilterProcessor alloc] initWithFormatType:kCVPixelFormatType_32BGRA isOriginalOrientation:isOriginalOrientation];
    self.filterProcessor.mediaEffectDelegate = self;
    
    // 默认关闭动态贴纸功能，即关闭人脸识别功能, 这里只是用特效，不需要人脸识别
    self.filterProcessor.enableLiveSticker = NO;
}

// 初始化TuSDK滤镜选择栏
- (void)showTuSDKEffectsView {
    
    if (!self.tuSDKEffectsView) {
        // 场景特效视图
        self.displayColors = [self getRandomColorWithCount:kScenceCodes.count];

        // 场景特效视图
        CGFloat height = 200;
        CGRect rc = CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, height);
        self.tuSDKEffectsView = [[EffectsView alloc] initWithFrame:rc thumbImageArray:self.thumbImageArray];
        self.tuSDKEffectsView.backgroundColor = COMMON_BACKGROUND_COLOR;
        self.tuSDKEffectsView.effectEventDelegate = self;
        self.tuSDKEffectsView.effectsCode = kScenceCodes;
        self.tuSDKEffectsView.hidden = YES;
        [self.view addSubview:self.tuSDKEffectsView];
        
        // 撤销特效的按钮
        UIButton *revocationButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [revocationButton setImage:[UIImage imageNamed:@"qn_revocation"] forState:UIControlStateNormal];
        [revocationButton addTarget:self action:@selector(didTouchUpRemoveSceneMediaEffectButton:) forControlEvents:UIControlEventTouchUpInside];
        [self.tuSDKEffectsView addSubview:revocationButton];
        
        [revocationButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.tuSDKEffectsView).offset(-15);
            make.centerY.equalTo(self.tuSDKEffectsView.displayView);
            make.size.equalTo(CGSizeMake(44, 44));
        }];
        
        [self.tuSDKEffectsView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.bottom.equalTo(self.view);
            make.top.equalTo(self.mas_bottomLayoutGuide).offset(-height);
        }];
        
        [self.view layoutIfNeeded];
        [self hideView:self.tuSDKEffectsView update:NO];
        [self.view layoutIfNeeded];

        self.tuSDKEffectsView.hidden = NO;
    }
    
    // 添加特效的时候，为了让特效预览效果最佳，不让底部的特效按钮挡住预览 view
    [self.shortVideoEditor.previewView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerX.top.equalTo(self.view);
        make.bottom.equalTo(self.tuSDKEffectsView.mas_top);
        make.width.equalTo(self.shortVideoEditor.previewView.mas_height).multipliedBy(9.0/16);
    }];
    
    self.tuSDKEffectsView.progress = self.videoProgress;
    [self stopEditing];
    [self showView:self.tuSDKEffectsView update:YES];
    [self entryEditingMode];
    [self.shortVideoEditor seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {}];
}

- (void)hideTuSDKEffectView {
    
    // 预览 view 重新恢复到全屏
    [self.shortVideoEditor.previewView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    [self hideView:self.tuSDKEffectsView update:YES];
    [self exitEditingMode];
    [self startEditing];
}

- (void) showTuSDKFiterView {
    
    if (!_tuSDKFilterView) {

        CGSize size = self.view.bounds.size;
        CGFloat filterPanelHeight = 276;

        // 滤镜视图
        _tuSDKFilterView = [[FilterPanelView alloc] initWithFrame:CGRectMake(0, 0, size.width, filterPanelHeight)];
        _tuSDKFilterView.delegate = (id<FilterPanelDelegate>)self;
        _tuSDKFilterView.dataSource = (id<CameraFilterPanelDataSource>)self;
        _tuSDKFilterView.codes = @[kVideoEditFilterCodes];
        
        [self.view addSubview:_tuSDKFilterView];
        
        [_tuSDKFilterView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.bottom.equalTo(self.view);
            make.top.equalTo(self.mas_bottomLayoutGuide).offset(-filterPanelHeight);
        }];
        
        [self.view layoutIfNeeded];
        [self hideView:_tuSDKFilterView update:NO];
        [self.view layoutIfNeeded];
    }
    
    [self showView:self.tuSDKFilterView update:YES];
    [self entryEditingMode];
}


- (NSArray<UIColor *> *)getRandomColorWithCount:(NSInteger)count {
    NSMutableArray *colorArr = [NSMutableArray new];
    for (int i = 0; i < count; i++) {
        UIColor *color = [UIColor colorWithRed:random()%255/255.0 green:random()%255/255.0 blue:random()%255/255.0 alpha:.9];
        [colorArr addObject:color];
    }
    return colorArr;
}

- (void)resetExportVideoEffectsMark {
    [self.filterProcessor addMediaEffect:nil];
}

// 重置标志位
- (void)resetPreviewVideoEffectsMark {
    [self.filterProcessor addMediaEffect:nil];
}

- (void)endCurrentEffect:(CMTime)endTime {
    
    if (self.editingEffectData) {
        // 停止视频预览
        [self stopEditing];
        
        // 结束视频特效处理
        self.editingEffectData.atTimeRange = [TuSDKTimeRange makeTimeRangeWithStart: self.editingEffectData.atTimeRange.start end:endTime];
        self.editingEffectData = nil;
        // 结束更新特效 UI
        [self.tuSDKEffectsView.displayView addSegmentViewEnd];
    }
}

/** 移除最后添加的场景特效 */
- (void)didTouchUpRemoveSceneMediaEffectButton:(UIButton *)button
{
    [self stopEditing];
    
    [self.tuSDKEffectsView.displayView removeLastSegment];
    
    // 移除最后一个指定类型的特效
    /** 1. 通过 mediaEffectsWithType: 获取指定类型的已有特效信息 */
    NSArray<id<TuSDKMediaEffect>> *mediaEffects = [_filterProcessor mediaEffectsWithType:TuSDKMediaEffectDataTypeScene];
    
    if (mediaEffects.count) {
        /** 2. 获取最后一次添加的特效 */
        id<TuSDKMediaEffect> lastMediaEffectData = [mediaEffects lastObject];
        /** 3. 通过 removeMediaEffect： 移除指定特效 */
        [_filterProcessor removeMediaEffect:lastMediaEffectData];
    }
}


#pragma mark - CameraFilterPanelDataSource

/**
 滤镜参数个数
 
 @return 滤镜参数数量
 */
- (NSInteger)numberOfParamter {
    
    TuSDKMediaFilterEffect *filterEffect = [_filterProcessor mediaEffectsWithType:TuSDKMediaEffectDataTypeFilter].firstObject;
    return filterEffect.filterArgs.count;
}

/**
 滤镜参数名称
 
 @param index 滤镜索引
 @return 滤镜索引
 */
- (NSString *)paramterNameAtIndex:(NSUInteger)index {
    TuSDKMediaFilterEffect *filterEffect = [_filterProcessor mediaEffectsWithType:TuSDKMediaEffectDataTypeFilter].firstObject;
    return filterEffect.filterArgs[index].key;
}

/**
 滤镜参数值
 
 @param index 滤镜参数索引
 @return 滤镜参数百分比
 */
- (double)percentValueAtIndex:(NSUInteger)index {
    TuSDKMediaFilterEffect *filterEffect = [_filterProcessor mediaEffectsWithType:TuSDKMediaEffectDataTypeFilter].firstObject;
    return filterEffect.filterArgs[index].precent;
}


#pragma mark - FilterPanelDelegate

/**
 滤镜选中回调
 
 @param filterPanel 相机滤镜协议
 @param code 滤镜的 fitlerCode
 */
- (void)filterPanel:(id<FilterPanelProtocol>)filterPanel didSelectedFilterCode:(NSString *)code {
    TuSDKMediaFilterEffect *filterEffect = [[TuSDKMediaFilterEffect alloc] initWithEffectCode:code];
    [_filterProcessor addMediaEffect:filterEffect];
    [_tuSDKFilterView reloadFilterParamters];
}

/**
 滤镜视图参数变更回调
 
 @param filterPanel 相机滤镜协议
 @param percentValue 滤镜参数变更数值
 @param index 滤镜参数索引
 */
- (void)filterPanel:(id<FilterPanelProtocol>)filterPanel didChangeValue:(double)percentValue paramterIndex:(NSUInteger)index {
    // 设置当前滤镜的参数，并 `-submitParameter` 提交参数让其生效
    
    TuSDKMediaFilterEffect *filterEffect = [_filterProcessor mediaEffectsWithType:TuSDKMediaEffectDataTypeFilter].firstObject;
    [filterEffect submitParameter:index argPrecent:percentValue];
}

/**
 特效被移除通知
 
 @param processor TuSDKFilterProcessor
 @param mediaEffects 被移除的特效列表
 @since      v2.2.0
 */
- (void)onVideoProcessor:(TuSDKFilterProcessor *)processor didRemoveMediaEffects:(NSArray<id<TuSDKMediaEffect>> *)mediaEffects;
{
    // 当特效数据被移除时触发该回调，以下情况将会触发：
    
    // 1. 当特效不支持添加多个时 SDK 内部会自动移除不可叠加的特效
    // 2. 当开发者调用 removeMediaEffect / removeMediaEffectsWithType: / removeAllMediaEffects 移除指定特效时
    
}

#pragma mark EffectsViewEventDelegate

/**
 按下了场景特效 触发编辑功能
 
 @param effectsView 特效视图
 @param effectCode 特效代号
 */
- (void)effectsView:(EffectsView *)effectsView didSelectMediaEffectCode:(NSString *)effectCode
{
    // 启动视频预览
    [self startEditing];
    
    if (self.videoProgress >= 1) {
        self.videoProgress = 0;
    }
    
    // 添加特效步骤
    
    // step 1: 构建指定类型的特效数据
    _editingEffectData = [[TuSDKMediaSceneEffect alloc] initWithEffectsCode:effectCode];
    
    // step 2: 设置特效触发时间
    //    提示： 由于开始编辑特殊特效时不知道结束时间，添加特效时可以将结束时间设置为一个特大值（实现全程预览），结束编辑时再置为正确结束时间。
    _editingEffectData.atTimeRange = [TuSDKTimeRange makeTimeRangeWithStart:[self.shortVideoEditor currentTime] end:CMTimeMake(INTMAX_MAX, 1)];
    
    // step 3: 使用 addMediaEffect： 添加特效
    [self.filterProcessor addMediaEffect:_editingEffectData];
    
    // 开始更新特效 UI
    [self.tuSDKEffectsView.displayView addSegmentViewBeginWithStartLocation:self.videoProgress WithColor:[self.displayColors objectAtIndex:[kScenceCodes indexOfObject:effectCode]]];
}

/**
 结束编辑场景特效
 
 @param effectsView 场景特效视图
 @param effectCode 场景特效代号
 */
- (void)effectsView:(EffectsView *)effectsView didDeSelectMediaEffectCode:(NSString *)effectCode;
{
    [self endCurrentEffect:self.shortVideoEditor.currentTime];
}

- (void)effectsViewEndEditing:(EffectsView *)effectsView {
    [self hideTuSDKEffectView];
}

//================================================== 涂图特效 end =================================================
@end

