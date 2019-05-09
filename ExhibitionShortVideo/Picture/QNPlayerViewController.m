//
//  QNPlayerViewController.m
//  ExhibitionShortVideo
//
//  Created by hxiongan on 2019/5/7.
//  Copyright © 2019年 ahx. All rights reserved.
//

#import "QNPlayerViewController.h"
#import "QNPlayerView.h"
#import "QNPanImageView.h"
#import "QNGradientView.h"
#import "QNPictureViewController.h"
#import <PLShortVideoKit/PLShortVideoKit.h>

static NSString *const kUploadToken = @"QxZugR8TAhI38AiJ_cptTl3RbzLyca3t-AAiH-Hh:3hK7jJJQKwmemseSwQ1duO5AXOw=:eyJzY29wZSI6InNhdmUtc2hvcnQtdmlkZW8tZnJvbS1kZW1vIiwiZGVhZGxpbmUiOjM1NTk2OTU4NzYsInVwaG9zdHMiOlsiaHR0cDovL3VwLXoyLnFpbml1LmNvbSIsImh0dHA6Ly91cGxvYWQtejIucWluaXUuY29tIiwiLUggdXAtejIucWluaXUuY29tIGh0dHA6Ly8xNC4xNTIuMzcuNCJdfQ==";
static NSString *const kURLPrefix = @"http://panm32w98.bkt.clouddn.com";

@interface QNPlayerViewController ()
<
UICollectionViewDelegate,
UICollectionViewDataSource,
PLShortVideoUploaderDelegate
>

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) QNPlayerView *playerView;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) QNPanImageView *panImageView;
@property (nonatomic, strong) NSMutableArray *thumbArray;
@property (nonatomic, strong) QNGradientView *gradientBar;
@property (nonatomic, strong) UIView *scopeBackgroundView;;
@property (nonatomic, strong) UIView *scopeView;
@property (nonatomic, strong) UIImage *picture;

@property (strong, nonatomic) PLShortVideoUploader *shortVideoUploader;
@property (strong, nonatomic) NSString *remoteVideoURL;

@end

@implementation QNPlayerViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.gradientBar = [[QNGradientView alloc] init];
    self.gradientBar.gradienLayer.colors = @[(__bridge id)[[UIColor colorWithWhite:0 alpha:.8] CGColor], (__bridge id)[[UIColor clearColor] CGColor]];
    [self.view addSubview:self.gradientBar];
    [self.gradientBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.equalTo(self.view);
        make.bottom.equalTo(self.mas_topLayoutGuide).offset(50);
    }];
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.textColor = [UIColor lightTextColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.text = @"滑动红框选择照片范围";
    titleLabel.font = [UIFont systemFontOfSize:14];
    [self.gradientBar addSubview:titleLabel];
    
    UILabel *label = [[UILabel alloc] init];
    label.textColor = [UIColor lightTextColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = @"滑动滑块选择照片";
    label.font = [UIFont systemFontOfSize:14];
    
    UIButton *backButton = [UIButton buttonWithType:(UIButtonTypeSystem)];
    [backButton setTintColor:UIColor.whiteColor];
    [backButton setImage:[UIImage imageNamed:@"qn_icon_close"] forState:(UIControlStateNormal)];
    [backButton addTarget:self action:@selector(clickBackButton) forControlEvents:(UIControlEventTouchUpInside)];
    [self.gradientBar addSubview:backButton];
    [backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.equalTo(CGSizeMake(44, 44));
        make.left.bottom.equalTo(self.gradientBar);
    }];
    
    UIButton *nextButton = [[UIButton alloc] init];
    [nextButton setImage:[UIImage imageNamed:@"qn_next_button"] forState:(UIControlStateNormal)];
    [nextButton addTarget:self action:@selector(clickNextButton:) forControlEvents:(UIControlEventTouchUpInside)];
    [nextButton sizeToFit];
    [self.gradientBar addSubview:nextButton];
    [nextButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(backButton);
        make.size.equalTo(nextButton.bounds.size);
        make.right.equalTo(self.view).offset(-20);
    }];
    
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(backButton.mas_right);
        make.right.equalTo(nextButton.mas_left);
        make.centerY.equalTo(nextButton);
    }];
    
    CGFloat width = self.view.bounds.size.width - 60;
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(width / 10, 50);
    layout.minimumLineSpacing = 0;
    layout.minimumInteritemSpacing = 0;
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    
    CGRect rc = CGRectMake(0, 0, width, 50);
    self.collectionView = [[UICollectionView alloc] initWithFrame:rc collectionViewLayout:layout];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.backgroundColor = [UIColor clearColor];
    [self.collectionView registerClass:UICollectionViewCell.class forCellWithReuseIdentifier:@"cell"];
    [self.view addSubview:self.collectionView];
    
    self.panImageView = [[QNPanImageView alloc] init];
    self.panImageView.image = [UIImage imageNamed:@"qn_video_pan"];
    self.panImageView.backgroundColor = [UIColor whiteColor];
    self.panImageView.clipsToBounds  = YES;
    self.panImageView.userInteractionEnabled = YES;
    UIPanGestureRecognizer* panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureAction:)];
    [self.panImageView addGestureRecognizer:panGesture];
    
    [self.view addSubview:self.panImageView];
    [self.panImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.collectionView);
        make.centerX.equalTo(self.collectionView.mas_left);
        make.height.equalTo(self.collectionView).offset(10);
        make.width.equalTo(12);
    }];
    
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(30);
        make.right.equalTo(self.view).offset(-30);
        make.bottom.equalTo(self.mas_bottomLayoutGuide).offset(-30);
        make.height.equalTo(50);
    }];
    
    [self.view addSubview:label];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.collectionView.mas_bottom).offset(5);
    }];
    
    [self setupPlayer];
    [self getThumbImage];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (nil == self.scopeBackgroundView) {
        [self setupScopeView];
    }
}

- (void)getThumbImage {
    
    self.thumbArray = [[NSMutableArray alloc] init];
    
    CGFloat duration = CMTimeGetSeconds(self.player.currentItem.duration);
    NSUInteger count = duration;
    count = 10;
    
    NSMutableArray *timeArray = [[NSMutableArray alloc] init];
    CGFloat delta = duration / count;
    for (int i = 0; i < count; i ++) {
        CMTime time = CMTimeMake(i * delta * 1000, 1000);
        NSValue *value = [NSValue valueWithCMTime:time];
        [timeArray addObject:value];
    }
    
    AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:self.player.currentItem.asset];
    generator.requestedTimeToleranceAfter = CMTimeMake(200, 1000);
    generator.requestedTimeToleranceBefore = CMTimeMake(200, 1000);
    generator.appliesPreferredTrackTransform = YES;
    generator.maximumSize = CGSizeMake(100, 100);
    
    __block int finishCount = 0;
    [generator generateCGImagesAsynchronouslyForTimes:timeArray completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
        finishCount ++;
        if (image) {
            [self.thumbArray addObject:[UIImage imageWithCGImage:image]];
        }
        if (finishCount == count) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.collectionView reloadData];
            });
        }
    }];
}

- (void)setupPlayer {
    
    AVAsset *asset = [AVAsset assetWithURL:self.url];
    AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:asset];
    self.player = [AVPlayer playerWithPlayerItem:item];
    self.playerView = [[QNPlayerView alloc] init];
    self.playerView.player = self.player;
    
    [self.view insertSubview:self.playerView atIndex:0];
    [self.playerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.collectionView.mas_top).offset(-30);
        make.top.equalTo(self.gradientBar.mas_bottom).offset(20);
    }];
}

- (void)setupScopeView {
    
    self.scopeBackgroundView = [[UIView alloc] init];
    [self.playerView addSubview:self.scopeBackgroundView];
    self.scopeBackgroundView.frame = [PLShortVideoTranscoder videoDisplay:self.player.currentItem.asset bounds:self.playerView.bounds rotate:PLSPreviewOrientationPortrait];
    
    CGSize videoSize = self.player.currentItem.asset.pls_videoSize;
    self.scopeView = [[UIView alloc] init];
    self.scopeView.layer.borderWidth = 1.0;
    self.scopeView.layer.borderColor = [UIColor redColor].CGColor;
    UIView *coverView1 = [[UIView alloc] init];
    UIView *coverView2 = [[UIView alloc] init];
    coverView1.backgroundColor = [UIColor colorWithWhite:.2 alpha:.8];
    coverView2.backgroundColor = [UIColor colorWithWhite:.2 alpha:.8];
    
    [self.scopeBackgroundView addSubview:self.scopeView];
    [self.scopeBackgroundView addSubview:coverView2];
    [self.scopeBackgroundView addSubview:coverView1];
    
    if (videoSize.height / videoSize.width > PICTURE_RATIO) {
        
        CGRect rc = self.scopeBackgroundView.bounds;
        CGFloat width = rc.size.width;
        CGFloat height = rc.size.width * PICTURE_RATIO;
        self.scopeView.frame = CGRectMake(0, (rc.size.height - height) / 2 , width, height);

        [coverView1 mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.top.equalTo(self.scopeBackgroundView);
            make.bottom.equalTo(self.scopeView.mas_top);
        }];
        
        [coverView2 mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.bottom.equalTo(self.scopeBackgroundView);
            make.top.equalTo(self.scopeView.mas_bottom);
        }];
    } else {

        CGRect rc = self.scopeBackgroundView.bounds;
        CGFloat height = rc.size.height;
        CGFloat width = rc.size.height / PICTURE_RATIO;
        self.scopeView.frame = CGRectMake((rc.size.width - width) / 2, 0 , width, height);
        
        [coverView1 mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.bottom.top.equalTo(self.scopeBackgroundView);
            make.right.equalTo(self.scopeView.mas_left);
        }];
        
        [coverView2 mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.right.bottom.equalTo(self.scopeBackgroundView);
            make.left.equalTo(self.scopeView.mas_right);
        }];
    }
    
    UIPanGestureRecognizer *panGesrure = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(scopePanGestureHandle:)];
    self.scopeView.userInteractionEnabled = YES;
    [self.scopeView addGestureRecognizer:panGesrure];
}

- (void)clickBackButton {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    
    static NSInteger imageViewTag = 0x1234;
    
    UIImageView *imageView = [cell.contentView viewWithTag:imageViewTag];
    if (!imageView) {
        imageView = [[UIImageView alloc] initWithFrame:cell.bounds];
        imageView.tag = imageViewTag;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        [cell.contentView addSubview:imageView];
    }
    
    if (self.thumbArray.count > indexPath.row) {
        imageView.image = self.thumbArray[indexPath.row];
    }
    
    return cell;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.thumbArray.count;
}

-(void)panGestureAction:(UIPanGestureRecognizer*)gesture{
    
    CGPoint point = [gesture translationInView:gesture.view.superview];

    switch (gesture.state) {
            
        case UIGestureRecognizerStateBegan:{
        }
            break;
            
        case UIGestureRecognizerStateChanged:{
            CGPoint center = self.panImageView.center;
            center.x += point.x;
            if (center.x < self.collectionView.frame.origin.x) {
                center.x = self.collectionView.frame.origin.x;
            }
            if (center.x > self.collectionView.frame.origin.x + self.collectionView.frame.size.width) {
                center.x = self.collectionView.frame.origin.x + self.collectionView.frame.size.width;
            }
            self.panImageView.center = center;
        }
            break;
            
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:{}
            break;
            
        default:
            break;
    }
    
    [gesture setTranslation:CGPointMake(0, 0) inView:gesture.view.superview];
    
    CMTime duration = self.player.currentItem.duration;
    CGFloat perecnt = (self.panImageView.center.x - self.collectionView.frame.origin.x) / self.collectionView.frame.size.width;
    CMTime time = CMTimeMake(perecnt * duration.value, duration.timescale);
    [self.player seekToTime:time toleranceBefore:CMTimeMake(150, 1000) toleranceAfter:CMTimeMake(150, 1000)];
}

- (void)scopePanGestureHandle:(UIPanGestureRecognizer *)gesture {
    CGPoint point = [gesture translationInView:gesture.view.superview];
    
    switch (gesture.state) {
            
        case UIGestureRecognizerStateBegan:{
        }
            break;
            
        case UIGestureRecognizerStateChanged:{
            CGSize videoSize = self.player.currentItem.asset.pls_videoSize;
            CGPoint center = self.scopeView.center;
            if (videoSize.height / videoSize.width > PICTURE_RATIO) {
                center.y += point.y;
                center.y = MAX(self.scopeView.frame.size.height/2, center.y);
                center.y = MIN(self.scopeBackgroundView.bounds.size.height - self.scopeView.frame.size.height/2, center.y);
            } else {
                center.x += point.x;
                center.x = MAX(self.scopeView.frame.size.width/2, center.x);
                center.x = MIN(self.scopeBackgroundView.bounds.size.width - self.scopeView.frame.size.width/2, center.x);
            }
            
            self.scopeView.center = center;
        }
            break;
            
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:{}
            break;
            
        default:
            break;
    }
    
    [gesture setTranslation:CGPointMake(0, 0) inView:gesture.view.superview];
}

- (CGRect)cropRectWithOriginSize:(CGSize)originPictureSize {
    CGFloat x = self.scopeView.frame.origin.x / self.scopeBackgroundView.bounds.size.width * originPictureSize.width;
    CGFloat y = self.scopeView.frame.origin.y / self.scopeBackgroundView.bounds.size.height * originPictureSize.height;
    CGFloat width = self.scopeView.frame.size.width / self.scopeBackgroundView.bounds.size.width * originPictureSize.width;
    CGFloat height = self.scopeView.frame.size.height / self.scopeBackgroundView.bounds.size.height * originPictureSize.height;
    
    return CGRectMake(x, y, width, height);
}

- (void)clickNextButton:(UIButton *)button {

    // get picture for print
    AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:self.player.currentItem.asset];
    imageGenerator.appliesPreferredTrackTransform = YES;// must set no in this environment
    CMTime time = self.player.currentItem.currentTime;
    
    NSError *error = nil;
    CGImageRef originImage = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:&error];
    if (!originImage) {
        [self showAlertMessage:@"提示" message:@"获取照片发生错误了，重新选择照片试试"];
        return;
    }
    CGSize originPictureSize = CGSizeMake(CGImageGetWidth(originImage), CGImageGetHeight(originImage));
    CGRect cropRect = [self cropRectWithOriginSize:originPictureSize];
    CGImageRef cropImage = CGImageCreateWithImageInRect(originImage, cropRect);
    self.picture = [UIImage imageWithCGImage:cropImage];
    CGImageRelease(cropImage);
    CGImageRelease(originImage);
    
    UIImageWriteToSavedPhotosAlbum(self.picture, nil, nil, nil);
    
    // upload
    if (!self.remoteVideoURL) {
        [self doUpload];
    } else {
        [self gotoNextController];
    }
}

- (void)gotoNextController {
    QNPictureViewController *pictureController = [[QNPictureViewController alloc] init];
    pictureController.videoURLString = self.remoteVideoURL;
    pictureController.originPicture = self.picture;
    
    [self presentViewController:pictureController animated:YES completion:nil];
}

- (void)doUpload {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyyMMddHHmmss";
    NSString *key = [NSString stringWithFormat:@"short_video_%@.mp4", [formatter stringFromDate:[NSDate date]]];
    PLSUploaderConfiguration * uploadConfig = [[PLSUploaderConfiguration alloc] initWithToken:kUploadToken videoKey:key https:YES recorder:nil];
    self.shortVideoUploader = [[PLShortVideoUploader alloc] initWithConfiguration:uploadConfig];
    self.shortVideoUploader.delegate = self;
    
    [self.shortVideoUploader uploadVideoFile:self.url.path];
    
    [self showWating];
}

#pragma mark - PLShortVideoUploaderDelegate 视频上传
- (void)shortVideoUploader:(PLShortVideoUploader *)uploader completeInfo:(PLSUploaderResponseInfo *)info uploadKey:(NSString *)uploadKey resp:(NSDictionary *)resp {
    [self hideWating];
    if(info.error){
        [self showAlertMessage:@"上传错误" message:info.error.description];
        return ;
    }
    
    NSString *urlString = [NSString stringWithFormat:@"%@/%@", kURLPrefix, uploadKey];
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = urlString;
    
    self.remoteVideoURL = urlString;
    
    [self gotoNextController];
}

- (void)shortVideoUploader:(PLShortVideoUploader *)uploader uploadKey:(NSString *)uploadKey uploadPercent:(float)uploadPercent {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.progress = uploadPercent;
    });
    NSLog(@"uploadKey: %@",uploadKey);
    NSLog(@"uploadPercent: %.2f",uploadPercent);
}

@end
