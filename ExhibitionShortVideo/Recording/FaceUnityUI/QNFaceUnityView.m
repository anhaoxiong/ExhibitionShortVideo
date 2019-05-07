//
//  QNFaceUnityView.m
//  ShortVideo
//
//  Created by hxiongan on 2019/4/29.
//  Copyright © 2019年 ahx. All rights reserved.
//

#import "QNFaceUnityView.h"
#import "QNFaceUnityBeautyView.h"
#import "QNFaceUnityMakeUpView.h"
#import "FULiveModel.h"

@interface QNFaceUnityView ()
<
UICollectionViewDelegate,
UICollectionViewDataSource
>

@property (nonatomic, strong) UIButton *noneButton;
@property (nonatomic, strong) UIScrollView *barScrollView;
@property (nonatomic, strong) UICollectionView *collectionView;

@property (nonatomic, strong) QNFaceUnityBeautyView *beautyView;// 美颜
@property (nonatomic, strong) QNFaceUnityMakeUpView *makeupView;// 美装

@property (nonatomic, strong) FULiveModel *currentModel;
@property (nonatomic, strong) UIView *highlightedLine;
@end

@implementation QNFaceUnityView

+ (void)setDefaultBeautyParams {
    // 重置默认参数
    [[FUManager shareManager] setBeautyDefaultParameters];
    
    // 这里的滤镜设置为原始,即就是不做滤镜处理。否则画面太美不敢看
    [FUManager shareManager].selectedFilter = @"origin";
    
    // 七牛短视频 SDK 中自带的美颜已经打开，这里关掉相芯科技的美白、红润等参数
    [FUManager shareManager].skinDetectEnable = NO;
    [FUManager shareManager].whiteLevel = 0.1;
    [FUManager shareManager].blurShape = 0;
    [FUManager shareManager].redLevel = 0.1;
    [FUManager shareManager].blurLevel = 0.1;
}

+ (void)setDefaultMakeupParams {
    
}

- (CGFloat)minViewHeight {
    return 220;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        NSArray *dataSource = [[FUManager shareManager] dataSource];
        self.currentModel = [dataSource objectAtIndex:0];
        
        self.backgroundColor = COMMON_BACKGROUND_COLOR;
        UIView *barView = [[UIView alloc] init];
        barView.backgroundColor = [UIColor colorWithWhite:0.2 alpha:.2];
        [self addSubview:barView];
        [barView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.top.equalTo(self);
            make.height.equalTo(44);
        }];
        
        self.highlightedLine = [[UIView alloc] init];
        self.highlightedLine.backgroundColor = [UIColor whiteColor];
        
        self.noneButton = [[UIButton alloc] init];
        [self.noneButton setImage:[UIImage imageNamed:@"qn_none_filter"] forState:(UIControlStateNormal)];
        [self.noneButton addTarget:self action:@selector(clickNoneButton:) forControlEvents:(UIControlEventTouchUpInside)];
        [self addSubview:self.noneButton];
        
        self.barScrollView = [[UIScrollView alloc] init];
        self.barScrollView.showsHorizontalScrollIndicator = NO;
        [self.barScrollView addSubview:self.highlightedLine];
        
        NSInteger originX = 20;
        for (int i = 0; i < dataSource.count; i ++) {
            FULiveModel *model = [dataSource objectAtIndex:i];
            UIButton *button = [UIButton buttonWithType:(UIButtonTypeCustom)];
            [button setTitle:model.title forState:(UIControlStateNormal)];
            [button setTitleColor:[UIColor colorWithWhite:1.0 alpha:1.0] forState:(UIControlStateSelected)];
            [button setTitleColor:[UIColor colorWithWhite:1.0 alpha:.5] forState:(UIControlStateNormal)];
            [button addTarget:self action:@selector(clickModelTypeButton:) forControlEvents:(UIControlEventTouchUpInside)];
            button.titleLabel.font = [UIFont systemFontOfSize:16];
            [button sizeToFit];
            button.tag = model.type;
            
            CGFloat width = MAX(44, button.bounds.size.width);
            CGRect rc = CGRectMake(originX, 0, width, 44);
            originX += rc.size.width + 20;
            button.frame = rc;
            [self.barScrollView addSubview:button];
            
            if (model.type == self.currentModel.type) {
                button.selected = YES;
                self.highlightedLine.frame = CGRectMake(rc.origin.x, rc.origin.y + rc.size.height - 2, rc.size.width, 2);
            }
        }
        [self addSubview:self.barScrollView];
        [self.barScrollView setContentSize:CGSizeMake(originX, 44)];
        
        UIView *spaceLine = [[UIView alloc] init];
        spaceLine.backgroundColor = [UIColor colorWithWhite:1.0 alpha:.5];
        [self.noneButton addSubview:spaceLine];
        [spaceLine mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.noneButton);
            make.centerY.equalTo(self.noneButton);
            make.width.equalTo(1);
            make.height.equalTo(self.noneButton).offset(-10);
        }];
        
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.itemSize = CGSizeMake(60, 60);
        layout.minimumLineSpacing = 10;
        layout.minimumInteritemSpacing = 10;
        layout.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10);
        
        CGRect rc = CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, 60);
        self.collectionView = [[UICollectionView alloc] initWithFrame:rc collectionViewLayout:layout];
        self.collectionView.delegate = self;
        self.collectionView.dataSource = self;
        self.collectionView.backgroundColor = [UIColor clearColor];
        self.collectionView.showsHorizontalScrollIndicator = NO;
        self.collectionView.alwaysBounceVertical = YES;
        [self.collectionView registerClass:UICollectionViewCell.class forCellWithReuseIdentifier:@"Cell"];
        [self addSubview:self.collectionView];
        
        [self.noneButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.top.equalTo(self);
            make.size.equalTo(CGSizeMake(60, 44));
        }];
        
        [self.barScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.noneButton.mas_right);
            make.top.right.equalTo(self);
            make.height.equalTo(self.noneButton);
        }];
        
        [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.bottom.equalTo(self);
            make.top.equalTo(self.barScrollView.mas_bottom);
        }];
        
        self.beautyView = [[QNFaceUnityBeautyView alloc] init];
        self.makeupView = [[QNFaceUnityMakeUpView alloc] init];
        [self addSubview:self.makeupView];
        [self addSubview:self.beautyView];
        self.makeupView.hidden = YES;
        [self.beautyView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.collectionView);
        }];
        [self.makeupView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.collectionView);
        }];
        self.collectionView.hidden = YES;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self addRoundedCorners:(UIRectCornerTopLeft | UIRectCornerTopRight) withRadii:CGSizeMake(10, 10) viewRect:self.bounds];
}

- (void)clickNoneButton:(UIButton *)button {
    if (FULiveModelTypeBeautifyFace == self.currentModel.type) {
        [self.class setDefaultBeautyParams];
        [self.beautyView reset];
        [self.delegate faceUnityView:self showTipString:@"所有美颜效果恢复默认"];
    } else if (FULiveModelTypeMakeUp == self.currentModel.type) {
        [self.class setDefaultMakeupParams];
        [self.makeupView reset];
    } else {
        
        if (FULiveModelTypeHair == self.currentModel.type) {
            [[FUManager shareManager] setHairColor:0];
            [[FUManager shareManager] setHairStrength:0.0];
        } else if (FULiveModelTypeAnimoji == self.currentModel.type ) {
            [[FUManager shareManager] destoryAnimojiFaxxBundle];
        }
        [[FUManager shareManager] loadItem:nil];
        
        NSArray *arr = self.collectionView.indexPathsForSelectedItems;
        
        if (arr.count) {
            [self.collectionView deselectItemAtIndexPath:arr[0] animated:YES];
        }
    }
}

- (void)clickModelTypeButton:(UIButton *)button {
    if (button.tag == self.currentModel.type) return;
    
    for (UIView *subView in self.barScrollView.subviews) {
        if ([subView isKindOfClass:UIButton.class]) {
            UIButton *b = (UIButton *)subView;
            if (b.isSelected) {
                b.selected = NO;
                break;
            }
        }
    }

    button.selected = YES;

    if (FULiveModelTypeAnimoji == self.currentModel.type) {
        [[FUManager shareManager] destoryAnimojiFaxxBundle];
    }
    
    for (FULiveModel *model in [FUManager shareManager].dataSource) {
        if ((model.type == button.tag)) {
            self.currentModel = model;
            break;
        }
    }
    
    [FUManager shareManager].currentModel = self.currentModel;
    
    if (FULiveModelTypeBeautifyFace == self.currentModel.type) {
        self.beautyView.hidden = NO;
        self.collectionView.hidden = YES;
        self.makeupView.hidden = YES;
    } else if (FULiveModelTypeMakeUp == self.currentModel.type) {
        self.makeupView.hidden = NO;
        self.beautyView.hidden = YES;
        self.collectionView.hidden = YES;
    } else {
        self.collectionView.hidden = NO;
        self.beautyView.hidden = YES;
        self.makeupView.hidden = YES;
    }
    
    if (FULiveModelTypeAnimoji == self.currentModel.type) {
        [[FUManager shareManager] loadAnimojiFaxxBundle];
        [[FUManager shareManager] set3DFlipH];
    }
    
    if (FULiveModelTypeHair == self.currentModel.type) {
        [[FUManager shareManager] loadItem:@"hair_gradient"];
        [[FUManager shareManager] setHairColor:0];
        [[FUManager shareManager] setHairStrength:0.5];
    }
    
    [self reloadItem];
    
    CGRect rc = button.frame;
    CGFloat x = CGRectGetMidX(rc);
    x = x - self.barScrollView.frame.size.width / 2;
    x = MAX(0, x);
    x = MIN(self.barScrollView.contentSize.width - self.barScrollView.frame.size.width, x);
    CGPoint contentOffset = CGPointMake(x, 0);
    [UIView animateWithDuration:.3 animations:^{
        self.highlightedLine.frame = CGRectMake(rc.origin.x, rc.origin.y + rc.size.height - 2, rc.size.width, 2);
        [self.barScrollView setContentOffset:contentOffset];
    }];
}

- (void)reloadItem {
    [self.collectionView reloadData];
}

- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
        
    static NSInteger imageViewTag = 0x1234;
    
    UIImageView *imageView = [cell.contentView viewWithTag:imageViewTag];
    if (!imageView) {
        imageView = [[UIImageView alloc] initWithFrame:cell.bounds];
        imageView.tag = imageViewTag;
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.clipsToBounds = YES;
        imageView.layer.cornerRadius = 5;
        [cell.contentView addSubview:imageView];
        
        int boardWidth = 3;
        [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(cell.contentView).insets(UIEdgeInsetsMake(boardWidth, boardWidth, boardWidth, boardWidth));
        }];
        
        cell.selectedBackgroundView = [[UIView alloc] init];
        cell.selectedBackgroundView.frame = cell.bounds;
        cell.selectedBackgroundView.layer.borderWidth = boardWidth;
        cell.selectedBackgroundView.layer.borderColor = [UIColor colorWithRed:.9 green:.2 blue:.2 alpha:1].CGColor;
        cell.selectedBackgroundView.layer.cornerRadius = 5;
    }
    
    imageView.image = [UIImage imageNamed:self.currentModel.items[indexPath.row]];
    
    return cell;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.currentModel.items.count;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    int index = (int)indexPath.row;
    if (FULiveModelTypeHair == self.currentModel.type) {
        
        if(index < 5) {//渐变色
            [[FUManager shareManager] loadItem:@"hair_gradient"];
            [[FUManager shareManager] setHairColor:index];
            [[FUManager shareManager] setHairStrength:.5];
        } else {
            [[FUManager shareManager] loadItem:@"hair_color"];
            [[FUManager shareManager] setHairColor:index - 5];
            [[FUManager shareManager] setHairStrength:.5];
        }
        
    } else if (FULiveModelTypeAnimoji == self.currentModel.type) {
        
        // animoji 分普通和动漫模式，详细使用方式请查看相芯科技的官方 Demo：FULiveDemo
        NSString *item = [self.currentModel.items objectAtIndex:index];
        [[FUManager shareManager] loadItem:item];
        
    } else {
        //道具贴纸, AR 面具, 手势识别, 哈哈镜, 人像驱动, 背景分隔, 表情识别, 换脸
        NSString *item = [self.currentModel.items objectAtIndex:index];
        [[FUManager shareManager] loadItem:item];
        
        /* 普通道具中手势道具，触发位置根据j情况调节 */
        if (self.currentModel.type == FULiveModelTypeGestureRecognition) {
            [[FUManager shareManager] setLoc_xy_flip];
        }
        
        NSString *tipString = [[FUManager shareManager] hintForItem:item];
        if (tipString.length > 0) {
            [self.delegate faceUnityView:self showTipString:tipString];
        }
    }
}

@end
