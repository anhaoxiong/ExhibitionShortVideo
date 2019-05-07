//
//  QNStickerModel.h
//  ShortVideo
//
//  Created by hxiongan on 2019/4/28.
//  Copyright © 2019年 ahx. All rights reserved.
//

#import <Foundation/Foundation.h>


#import <CoreMedia/CoreMedia.h>

@class QNStickerView;
@interface QNStickerModel : NSObject

@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong, readonly) UIColor *randomColor;

@property (nonatomic, assign) CGSize size;
@property (nonatomic, assign) CGPoint point;
@property (nonatomic, assign) CGFloat rotation;
@property (nonatomic, assign) CMTime startPositionTime;
@property (nonatomic, assign) CMTime endPositiontime;

// gif 播放一边需要的时间
@property (nonatomic, assign) CMTime oneLoopDuration;

//
@property (nonatomic, weak) UIView *colorView;
@property (nonatomic, weak) QNStickerView *stickerView;

@end

