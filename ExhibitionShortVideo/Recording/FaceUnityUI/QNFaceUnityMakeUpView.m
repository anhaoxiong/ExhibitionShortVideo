//
//  QNFaceUnityMakeUpView.m
//  ShortVideo
//
//  Created by hxiongan on 2019/5/4.
//  Copyright © 2019年 ahx. All rights reserved.
//

#import "QNFaceUnityMakeUpView.h"
#import "FUManager.h"
#import "FUMakeupModel.h"
#import "FUMakeupSupModel.h"


@interface QNFaceUnityMakeUpView()
<
UICollectionViewDelegate,
UICollectionViewDataSource
>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UISlider *slider;
@property (nonatomic, strong) UILabel *currentValueLabel;
@property (nonatomic, strong) NSArray *itemArray;

@end

@implementation QNFaceUnityMakeUpView

- (void)dealloc {
    [self modelChange:self.itemArray[0]];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
        [self loadData];
        
        self.slider = [[UISlider alloc] init];
        [self.slider addTarget:self action:@selector(sliderValueChange:) forControlEvents:(UIControlEventValueChanged)];
        self.slider.continuous = YES;
        self.slider.maximumValue = 1;
        self.slider.minimumValue = 0;
        self.slider.hidden = YES;
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
            }
        });
    }
    return self;
}

- (void)sliderValueChange:(UISlider *)slider {
    
    NSArray *paths = [self.collectionView indexPathsForSelectedItems];
    if (paths.count) {
        NSIndexPath *indexPath = paths.firstObject;
        FUMakeupSupModel *model = self.itemArray[indexPath.row];
        model.value = slider.value;
        [self modelChange:model];
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
        imageView.layer.cornerRadius = 5;
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
    
    FUMakeupSupModel *model = [self.itemArray objectAtIndex:indexPath.row];
    label.text = model.name;
    imageView.image = [UIImage imageNamed:model.imageStr] ;
    
    return cell;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.itemArray.count;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    FUMakeupSupModel *model = self.itemArray[indexPath.row];
    [self.slider setValue:model.value animated:YES];
    [self modelChange:model];
    self.slider.hidden = 0 == indexPath.row;
    self.currentValueLabel.hidden = 0 == indexPath.row;
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

- (void)modelChange:(FUMakeupSupModel *)model {
    
    for (int i = 0; i < model.makeups.count; i ++) {
        FUSingleMakeupModel *singleModel = model.makeups[i];
        
        if (0 == i) {
            // 口红
            NSArray *rgba = [self jsonToLipRgbaArrayResName:singleModel.namaImgStr];
            double lip[4] = {[rgba[0] doubleValue],[rgba[1] doubleValue],[rgba[2] doubleValue],[rgba[3] doubleValue]};
            [[FUManager shareManager] setMakeupItemLipstick:lip];
        } else {
            [[FUManager shareManager] setMakeupItemParamImage:[UIImage imageNamed:singleModel.namaImgStr]  param:singleModel.namaTypeStr];
        }
        [[FUManager shareManager] setMakeupItemIntensity:singleModel.value * model.value param:singleModel.namaValueStr];
    }
    
    [FUManager shareManager].selectedFilter = model.selectedFilter;
    [FUManager shareManager].selectedFilterLevel = model.selectedFilterLevel;
    
    [self updateLabel];
}

- (void)reset {
    [self.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:YES scrollPosition:(UICollectionViewScrollPositionCenteredHorizontally)];
    [self modelChange:self.itemArray[0]];
    self.slider.hidden = YES;
    self.currentValueLabel.hidden = YES;
}

-(NSArray *)jsonToLipRgbaArrayResName:(NSString *)resName{
    NSString *path=[[NSBundle mainBundle] pathForResource:resName ofType:@"json"];
    NSData *data=[[NSData alloc] initWithContentsOfFile:path];
    
    //解析成字典
    NSDictionary *dic=[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    NSArray *rgba = [dic objectForKey:@"rgba"];
    
    return rgba;
}

- (void)loadData {
    
    // 加载美装
    [[FUManager shareManager] loadMakeupBundleWithName:@"face_makeup"];
    
    NSString *wholePath=[[NSBundle mainBundle] pathForResource:@"makeup_whole" ofType:@"json"];
    NSData *wholeData=[[NSData alloc] initWithContentsOfFile:wholePath];
    NSDictionary *wholeDic =[NSJSONSerialization JSONObjectWithData:wholeData options:NSJSONReadingMutableContainers error:nil];
    NSArray *array = [wholeDic objectForKey:@"data"];
    
    NSMutableArray *modelArrays = [[NSMutableArray alloc] init];
    for (NSDictionary *dic in array) {
        FUMakeupSupModel *model = [[FUMakeupSupModel alloc] init];
        model.name = dic[@"name"];
        model.value = [dic[@"value"] floatValue];
        model.selectedFilter = dic[@"selectedFilter"];
        model.isSel = [dic[@"isSel"] boolValue];
        model.imageStr = dic[@"imageStr"];
        
        NSMutableArray *makeupModelArray = [[NSMutableArray alloc] init];
        NSArray *makeupsDicArray = dic[@"makeups"];
        for (NSDictionary *makeupDic in makeupsDicArray) {

            FUSingleMakeupModel *makeupModel = [[FUSingleMakeupModel alloc] init];
            makeupModel.namaImgStr = makeupDic[@"namaImgStr"];
            makeupModel.namaTypeStr = makeupDic[@"namaTypeStr"];
            makeupModel.namaValueStr = makeupDic[@"namaValueStr"];
            makeupModel.value = [makeupDic[@"value"] floatValue];
            
            [makeupModelArray addObject:makeupModel];
        }
        
        model.makeups = makeupModelArray;
        
        [modelArrays addObject:model];
    }
    
    self.itemArray = modelArrays;
}
@end
