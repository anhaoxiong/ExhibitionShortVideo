//
//  QNImageTitleButton.h
//  ShortVideo
//
//  Created by hxiongan on 2019/4/8.
//  Copyright © 2019年 ahx. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// MainViewController 中的几个按钮类
@interface QNImageTitleButton : UIButton

- (id)initWithFrame:(CGRect)frame
              image:(UIImage *)image
              title:(NSString *)title;

@end

NS_ASSUME_NONNULL_END
