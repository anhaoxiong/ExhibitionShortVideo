//
//  QNFilterPickerView.m
//  ShortVideo
//
//  Created by hxiongan on 2019/4/19.
//  Copyright © 2019年 ahx. All rights reserved.
//

#import "QNFilterPickerView.h"
#import "QNFilterGroup.h"

@interface QNFilterPickerView ()
<
UICollectionViewDelegate,
UICollectionViewDataSource
>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong, readwrite) QNFilterGroup *filterGroup;

@end

@implementation QNFilterPickerView

- (CGFloat)minViewHeight {
    return 130;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = COMMON_BACKGROUND_COLOR;

        self.filterGroup = [[QNFilterGroup alloc] init];
        
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.itemSize = CGSizeMake(80, 100);
        layout.minimumLineSpacing = 0;
        layout.minimumInteritemSpacing = 0;
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
        self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        self.collectionView.delegate = self;
        self.collectionView.dataSource = self;
        self.collectionView.allowsSelection = YES;
        self.collectionView.allowsMultipleSelection = NO;
        self.collectionView.backgroundColor = [UIColor clearColor];
        self.collectionView.showsHorizontalScrollIndicator = NO;
        [self.collectionView registerClass:UICollectionViewCell.class forCellWithReuseIdentifier:@"cell"];
        
        [self addSubview:self.collectionView];
        
        [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self);
            make.top.equalTo(self).offset(15);
            make.height.equalTo(100);
        }];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self addRoundedCorners:(UIRectCornerTopLeft | UIRectCornerTopRight) withRadii:CGSizeMake(10, 10) viewRect:self.bounds];
}

- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    
    static NSInteger imageViewTag = 0x1234;
    static NSInteger labelTag = 0x1235;
    
    if (nil == cell.selectedBackgroundView) {
        cell.selectedBackgroundView = [[UIView alloc] init];
    }
    
    UIImageView *imageView = [cell.contentView viewWithTag:imageViewTag];
    if (!imageView) {
        CGRect rc = CGRectMake((cell.bounds.size.width - 60)/2, 10, 60, 60);
        imageView = [[UIImageView alloc] initWithFrame:rc];
        imageView.tag = imageViewTag;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        imageView.layer.cornerRadius = 60/2;
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
        label.textColor = [UIColor lightTextColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.tag = labelTag;
        label.frame = CGRectMake(0, 75, cell.bounds.size.width, 25);
        [cell.contentView addSubview:label];
    }
    NSDictionary *dic = self.filterGroup.filtersInfo[indexPath.item];
    
    label.text = [dic objectForKey:@"name"];
    imageView.image = [UIImage imageWithContentsOfFile:[dic objectForKey:@"coverImagePath"]];
    
    return cell;
}

- (void)updateSelectFilterIndex {
    [self.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:self.filterGroup.filterIndex inSection:0] animated:YES scrollPosition:(UICollectionViewScrollPositionCenteredHorizontally)];
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.filterGroup.filtersInfo.count;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *dic = self.filterGroup.filtersInfo[indexPath.item];
    self.filterGroup.filterIndex = indexPath.item;
    [self.delegate filterView:self didSelectedFilter:[dic objectForKey:@"colorImagePath"]];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)dealloc {
    self.collectionView.delegate = nil;
    self.collectionView.dataSource = nil;
}

@end
