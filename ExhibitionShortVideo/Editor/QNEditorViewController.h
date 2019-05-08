//
//  QNEditorViewController.h
//  ShortVideo
//
//  Created by hxiongan on 2019/4/9.
//  Copyright © 2019年 ahx. All rights reserved.
//

#import "QNBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface QNEditorViewController : QNBaseViewController

@property (strong, nonatomic) NSDictionary *settings;

@property (strong, nonatomic) NSArray <NSURL *>* fileURLs;
@end

NS_ASSUME_NONNULL_END
