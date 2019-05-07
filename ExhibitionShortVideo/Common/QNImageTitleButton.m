//
//  QNImageTitleButton.m
//  ShortVideo
//
//  Created by hxiongan on 2019/4/8.
//  Copyright © 2019年 ahx. All rights reserved.
//

#import "QNImageTitleButton.h"

@implementation QNImageTitleButton

- (id)initWithFrame:(CGRect)frame image:(UIImage *)image title:(NSString *)title {
    
    self = [super initWithFrame:frame];
    if (self) {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        imageView.contentMode = UIViewContentModeCenter;
        [self addSubview:imageView];
        
        UILabel *label = [[UILabel alloc] init];
        label.font = [UIFont systemFontOfSize:14];
        label.textColor = [UIColor colorWithRed:.8 green:.8 blue:.8 alpha:1];
        label.textAlignment = NSTextAlignmentCenter;
        label.adjustsFontSizeToFitWidth = YES;
        label.text = title;
        [self addSubview:label];
        
        [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.top.right.equalTo(self);
            make.height.equalTo((int)(frame.size.height*3.0/4.0));
        }];
        
        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.bottom.equalTo(self);
            make.top.equalTo(imageView.mas_bottom);
        }];
    }
    return self;
}

@end
