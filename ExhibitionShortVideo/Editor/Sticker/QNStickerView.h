//
//  QNStickerView.h
//  PLVideoEditor
//
//  Created by suntongmian on 2018/5/24.
//  Copyright © 2018年 Pili Engineering, Qiniu Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QNStickerModel.h"
#import "QNPanImageView.h"

@class QNStickerView;
@protocol QNStickerViewDelegate <NSObject>

@optional
- (void)stickerViewClose:(QNStickerView *)stickerView;

@end

@interface QNStickerView : UIImageView

#pragma mark - UI
@property (nonatomic) UIButton *closeBtn;
@property (nonatomic) QNPanImageView *dragBtn;
@property (nonatomic, assign) id <QNStickerViewDelegate> delegate;
@property (nonatomic, strong, readonly) QNStickerModel *stickerModel;

// 选中后出现边框
@property (nonatomic, assign, getter=isSelected) BOOL select;

- (instancetype)initWithStickerModel:(QNStickerModel *)stickerModel;

- (void)close:(id)sender;

#pragma mark - Reserved
@property (nonatomic, assign) CGFloat oriScale;
@property (nonatomic, assign) CGAffineTransform oriTransform;

@end
