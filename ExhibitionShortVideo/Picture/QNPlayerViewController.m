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

@interface QNPlayerViewController ()
<
UICollectionViewDelegate,
UICollectionViewDataSource
>

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) QNPlayerView *playerView;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) QNPanImageView *panImageView;
@property (nonatomic, strong) NSMutableArray *thumbArray;
@property (nonatomic, strong) QNGradientView *gradientBar;

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
    
    UILabel *label = [[UILabel alloc] init];
    label.textColor = [UIColor lightTextColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = @"滑动选择封面";
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
        make.width.equalTo(20);
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

- (void)clickBackButton {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)clickNextButton:(UIButton *)button {
    
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

@end
