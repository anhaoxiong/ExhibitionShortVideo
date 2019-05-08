//
//  QNPictureViewController.h
//  ExhibitionShortVideo
//
//  Created by hxiongan on 2019/5/7.
//  Copyright © 2019年 ahx. All rights reserved.
//

#import "QNBaseViewController.h"

#define PICTURE_RATIO 1.2

NS_ASSUME_NONNULL_BEGIN

@interface QNPictureViewController : QNBaseViewController

@property (nonatomic, strong) UIImage *originPicture;
@property (nonatomic, strong) NSString *videoURLString;

@end

NS_ASSUME_NONNULL_END
