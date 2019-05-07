//
//  QNAudioVolumeView.h
//  ExhibitionShortVideo
//
//  Created by hxiongan on 2019/5/7.
//  Copyright © 2019年 ahx. All rights reserved.
//

#import <UIKit/UIKit.h>

@class QNAudioVolumeView;
@protocol QNAudioVolumeViewDelegate <NSObject>

- (void)audioVolumeView:(QNAudioVolumeView *)audioVolumeView videoVolumeChange:(float)videoVolume;
- (void)audioVolumeView:(QNAudioVolumeView *)audioVolumeView musicVolumeChange:(float)musicVolume;


@end

@interface QNAudioVolumeView : UIView

@property (nonatomic, readonly) CGFloat minViewHeight;
@property (nonatomic, weak) id<QNAudioVolumeViewDelegate> delegate;

- (void)setMusicSliderEnable:(BOOL)enable;

@end

