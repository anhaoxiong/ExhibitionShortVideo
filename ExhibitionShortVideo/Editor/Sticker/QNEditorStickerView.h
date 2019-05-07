//
//  QNEditorStickerView.h
//  ShortVideo
//
//  Created by hxiongan on 2019/4/28.
//  Copyright © 2019年 ahx. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QNStickerModel.h"


@class QNEditorStickerView;
@protocol QNEditorStickerViewDelegate <NSObject>

- (void)editorStickerViewWillBeginDragging:(QNEditorStickerView *)editorStickerView;
- (void)editorStickerViewWillEndDragging:(QNEditorStickerView *)editorStickerView;
- (void)editorStickerViewDoneButtonClick:(QNEditorStickerView *)editorStickerView;
- (void)editorStickerView:(QNEditorStickerView *)editorStickerView wantEntryEditing:(QNStickerModel *)model;
- (void)editorStickerView:(QNEditorStickerView *)editorStickerView wantSeekPlayerTo:(CMTime)time;
- (void)editorStickerView:(QNEditorStickerView *)editorStickerView addGifSticker:(QNStickerModel *)model;

@end

// 添加 GIF 动图的 UI 操作全部都封装在 QNEditorMusicView 中了
@interface QNEditorStickerView : UIView

- (id)initWithThumbImage:(NSArray<UIImage *>*)thumbArray videoDuration:(CMTime)duration;

@property (nonatomic, readonly) CGFloat minViewHeight;

@property (nonatomic, weak) id<QNEditorStickerViewDelegate> delegate;

@property (nonatomic, strong, readonly) NSMutableArray <QNStickerModel *> *addedStickerModelArray;

- (void)setPlayingTime:(CMTime)currentTime;

- (void)startStickerEditing:(QNStickerModel *)stickerModel;

- (void)endStickerEditing:(QNStickerModel *)stickerModel;

- (void)deleteSticker:(QNStickerModel *)model;

@end


@interface StickerCell : UICollectionViewCell
@property (nonatomic, strong) UIImageView *imageView;
@end
