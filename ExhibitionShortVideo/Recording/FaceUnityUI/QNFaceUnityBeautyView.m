//
//  QNFaceUnityBeautyView.m
//  ShortVideo
//
//  Created by hxiongan on 2019/4/30.
//  Copyright © 2019年 ahx. All rights reserved.
//

#import "QNFaceUnityBeautyView.h"
#import "FUManager.h"

@interface QNFaceUnityBeautyView ()
<
UICollectionViewDelegate,
UICollectionViewDataSource
>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UISlider *slider;
@property (nonatomic, strong) UILabel *currentValueLabel;
@property (nonatomic, strong) NSArray *itemArray;
@end

@implementation QNFaceUnityBeautyView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {

        self.itemArray = @[@"大眼", @"瘦脸", @"下巴", @"额头", @"瘦鼻", @"嘴型", @"磨皮", @"美白", @"红润", @"亮眼", @"美牙"];
        
        self.slider = [[UISlider alloc] init];
        [self.slider addTarget:self action:@selector(sliderValueChange:) forControlEvents:(UIControlEventValueChanged)];
        self.slider.continuous = YES;
        self.slider.maximumValue = 1;
        self.slider.minimumValue = 0;
        self.slider.minimumTrackTintColor = UIColor.whiteColor;
        self.slider.maximumTrackTintColor = UIColor.grayColor;
        [self addSubview:self.slider];
        
        self.currentValueLabel = [[UILabel alloc] init];
        self.currentValueLabel.font = [UIFont monospacedDigitSystemFontOfSize:12 weight:(UIFontWeightRegular)];
        self.currentValueLabel.textColor = [UIColor whiteColor];
        self.currentValueLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:self.currentValueLabel];
        
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.itemSize = CGSizeMake(60, 100);
        layout.minimumLineSpacing = 10;
        layout.minimumInteritemSpacing = 0;
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
        CGRect rc = CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, 60);
        self.collectionView = [[UICollectionView alloc] initWithFrame:rc collectionViewLayout:layout];
        self.collectionView.delegate = self;
        self.collectionView.backgroundColor = [UIColor clearColor];
        self.collectionView.dataSource = self;
        self.collectionView.showsHorizontalScrollIndicator = NO;
        [self.collectionView registerClass:UICollectionViewCell.class forCellWithReuseIdentifier:@"Cell"];
        [self addSubview:self.collectionView];
        
        [self.slider mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).offset(40);
            make.right.equalTo(self).offset(-40);
            make.top.equalTo(self).offset(30);
        }];

        [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.left.equalTo(self);
            make.top.equalTo(self.slider.mas_bottom).offset(20);
            make.height.equalTo(100);
        }];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.collectionView.numberOfSections > 0 && [self.collectionView numberOfItemsInSection:0] > 0) {
                [self.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] animated:YES scrollPosition:(UICollectionViewScrollPositionCenteredHorizontally)];
                self.slider.value = [FUManager shareManager].enlargingLevel;
                [self updateLabel];
            }
        });
    }
    return self;
}

- (void)sliderValueChange:(UISlider *)slider {

    NSArray *paths = [self.collectionView indexPathsForSelectedItems];
    if (paths.count) {
        [self updateLabel];
        NSIndexPath *indexPath = paths.firstObject;
        switch (indexPath.row) {
            case 0:
                [FUManager shareManager].enlargingLevel_new = slider.value;
                return;
            case 1:
                [FUManager shareManager].thinningLevel_new = slider.value;
                return;
            case 2:
                [FUManager shareManager].jewLevel = slider.value;
                return;
            case 3:
                [FUManager shareManager].foreheadLevel = slider.value;
                return;
            case 4:
                [FUManager shareManager].noseLevel = slider.value;
                return;
            case 5:
                [FUManager shareManager].mouthLevel = slider.value;
                return;
            case 6:
                [FUManager shareManager].blurLevel = slider.value;
                return;
            case 7:
                [FUManager shareManager].whiteLevel = slider.value;
                return;
            case 8:
                [FUManager shareManager].redLevel = slider.value;
                return;
            case 9:
                [FUManager shareManager].eyelightingLevel = slider.value;
                return;
            case 10:
                [FUManager shareManager].beautyToothLevel = slider.value;
                return;
            default:
                break;
        }
    }
}

- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    
    static NSInteger imageViewTag = 0x1234;
    static NSInteger labelTag = 0x1235;
    
    if (nil == cell.selectedBackgroundView) {
        cell.selectedBackgroundView = [[UIView alloc] init];
    }
    
    UIImageView *imageView = [cell.contentView viewWithTag:imageViewTag];
    if (!imageView) {
        CGRect rc = CGRectMake((cell.bounds.size.width - 50)/2, 10, 50, 50);
        imageView = [[UIImageView alloc] initWithFrame:rc];
        imageView.tag = imageViewTag;
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.clipsToBounds = YES;
        imageView.layer.cornerRadius = 50/2;
        [cell.contentView addSubview:imageView];
        int boardWidth = 3;
        rc =  CGRectMake(rc.origin.x - boardWidth, rc.origin.y - boardWidth, rc.size.width + 2 * boardWidth, rc.size.height + 2 * boardWidth);
        cell.selectedBackgroundView.frame = rc;
        cell.selectedBackgroundView.layer.borderWidth = boardWidth;
        cell.selectedBackgroundView.layer.borderColor = [UIColor colorWithRed:.8 green:.1 blue:.1 alpha:1].CGColor;
        cell.selectedBackgroundView.layer.cornerRadius = 5;
    }
    UILabel *label = [cell.contentView viewWithTag:labelTag];
    if (!label) {
        label = [[UILabel alloc] init];
        label.font = [UIFont systemFontOfSize:14];
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.tag = labelTag;
        label.frame = CGRectMake(0, 65, cell.bounds.size.width, 25);
        [cell.contentView addSubview:label];
    }
    
    label.text = self.itemArray[indexPath.row];
    imageView.image = [UIImage imageNamed:self.itemArray[indexPath.row]];
    
    return cell;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.itemArray.count;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {

    switch (indexPath.row) {
        case 0:
            self.slider.value = [FUManager shareManager].enlargingLevel_new;
            break;
        case 1:
            self.slider.value = [FUManager shareManager].thinningLevel_new;
            break;
        case 2:
            self.slider.value = [FUManager shareManager].jewLevel;
            break;
        case 3:
            self.slider.value = [FUManager shareManager].foreheadLevel;
            break;
        case 4:
            self.slider.value = [FUManager shareManager].noseLevel;
            break;
        case 5:
            self.slider.value = [FUManager shareManager].mouthLevel;
            break;
        case 6:
            self.slider.value = [FUManager shareManager].blurLevel;
            break;
        case 7:
            self.slider.value = [FUManager shareManager].whiteLevel;
            break;
        case 8:
            self.slider.value = [FUManager shareManager].redLevel;
            break;
        case 9:
            self.slider.value = [FUManager shareManager].eyelightingLevel;
            break;
        case 10:
            self.slider.value = [FUManager shareManager].beautyToothLevel;
            break;
        default:
            break;
    }
    
    [self updateLabel];
    [collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:(UICollectionViewScrollPositionCenteredHorizontally) animated:YES];
}

- (void)updateLabel {
    
    CGRect trackRect = [self.slider trackRectForBounds:self.slider.bounds];
    CGRect thumbRect = [self.slider thumbRectForBounds:self.slider.bounds
                                             trackRect:trackRect
                                                 value:self.slider.value];
    NSInteger value = self.slider.value * 100;
    self.currentValueLabel.text = [NSString stringWithFormat:@"%ld", (long)value];
    [self.currentValueLabel sizeToFit];
    
    CGRect rc = thumbRect;
    rc.origin.x += self.slider.frame.origin.x;
    rc.origin.y = self.slider.frame.origin.y - self.currentValueLabel.bounds.size.height - 10;
    rc.size.width = self.currentValueLabel.bounds.size.width;
    rc.origin.x += (thumbRect.size.width - rc.size.width) / 2;
    self.currentValueLabel.frame = rc;
}

- (void)reset {
    NSArray *paths = [self.collectionView indexPathsForSelectedItems];
    if (paths.count) {
        NSIndexPath *indexPath = paths.firstObject;
        [self collectionView:self.collectionView didSelectItemAtIndexPath:indexPath];
    }
}

@end
