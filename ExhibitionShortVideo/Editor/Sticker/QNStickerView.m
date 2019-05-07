//
//  QNStickerView.m
//  PLVideoEditor
//
//  Created by suntongmian on 2018/5/24.
//  Copyright © 2018年 Pili Engineering, Qiniu Inc. All rights reserved.
//

#import "QNStickerView.h"


@interface QNStickerView ()

@property (nonatomic, strong, readwrite) QNStickerModel *stickerModel;
@property (nonatomic, strong) NSMutableArray *allImage;
@end

@implementation QNStickerView


- (instancetype)initWithStickerModel:(QNStickerModel *)stickerModel {
    self = [super init];
    if (self) {
        self.userInteractionEnabled = YES;
        self.stickerModel = stickerModel;
        _oriScale = 1.0;
        [self setupUI];
        [self setupGIF];
    }
    return self;
}

- (void)setupUI{
    _dragBtn = [[QNPanImageView alloc] initWithImage:[UIImage imageNamed:@"qn_sticker_rotate"]];
    _dragBtn.userInteractionEnabled = YES;
    [self addSubview:_dragBtn];
    [_dragBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self).offset(10);
        make.right.equalTo(self).offset(10);
        make.size.equalTo(CGSizeMake(20, 20));
    }];
    
    _closeBtn = [[UIButton alloc] init];
    [_closeBtn setImage:[UIImage imageNamed:@"qn_sticker_delete"] forState:UIControlStateNormal];
    [_closeBtn addTarget:self action:@selector(close:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_closeBtn];
    
    [_closeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self).offset(-22);
        make.right.equalTo(self).offset(22);
        make.size.equalTo(CGSizeMake(44, 44));
    }];
}

- (void)close:(id)sender {
    if ([self.delegate respondsToSelector:@selector(stickerViewClose:)]) {
        [self.delegate stickerViewClose:self];
    }
    [self removeFromSuperview];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (self.alpha > 0.1 && !self.clipsToBounds) {
        for (UIView *subView in @[self.dragBtn, self.closeBtn]) {
            CGPoint subPoint = [self convertPoint:point toView:subView];
            UIView *resultView = [subView hitTest:subPoint withEvent:event];
            if (resultView) {
                return resultView;
            }
        }
    }
    
    return [super hitTest:point withEvent:event];
}

- (void)setSelect:(BOOL)select{
    _select = select;
    if (select) {
        self.layer.borderWidth = .5;
        self.layer.borderColor = [[UIColor colorWithWhite:1 alpha:.5] CGColor];
        self.closeBtn.hidden = NO;
        self.dragBtn.hidden = NO;
    }else{
        self.layer.borderWidth = 0;
        self.closeBtn.hidden = YES;
        self.dragBtn.hidden = YES;
    }
}

- (CGAffineTransform)currentTransform {
    return self.transform;
}

- (void)setHidden:(BOOL)hidden {
    [super setHidden:hidden];
    if (hidden) {
        [self stopAnimating];
    } else {
        [self startAnimating];
    }
}

- (void) setupGIF {
    
    NSURL *url = [NSURL fileURLWithPath:self.stickerModel.path];
    CGImageSourceRef imageSource = CGImageSourceCreateWithURL((CFURLRef)url, nil);
    CGFloat totalDuration = 0;
    size_t imageCount = CGImageSourceGetCount(imageSource);
    
    NSMutableArray *allImage = [[NSMutableArray alloc] init];
    for (int i = 0; i < imageCount; i ++) {
        
        CFDictionaryRef cfDic = CGImageSourceCopyPropertiesAtIndex(imageSource, i, nil);
        NSDictionary *properties = (__bridge NSDictionary *)cfDic;
        float frameDuration = [[[properties objectForKey:(__bridge NSString *)kCGImagePropertyGIFDictionary]
                                objectForKey:(__bridge NSString *) kCGImagePropertyGIFUnclampedDelayTime] doubleValue];
        if (frameDuration < (1e-6)) {
            frameDuration = [[[properties objectForKey:(__bridge NSString *)kCGImagePropertyGIFDictionary]
                              objectForKey:(__bridge NSString *) kCGImagePropertyGIFDelayTime] doubleValue];
        }
        if (frameDuration < (1e-6)) {
            frameDuration = 0.1;//如果获取不到，就默认 frameDuration = 0.1s
        }
        
        CGImageRef cgImage = CGImageSourceCreateImageAtIndex(imageSource, i, NULL);
        UIImage *image = [UIImage imageWithCGImage:cgImage scale:UIScreen.mainScreen.scale orientation:(UIImageOrientationUp)];
        [allImage addObject:image];
        
        CFRelease(cgImage);
        CFRelease(cfDic);
        totalDuration += frameDuration;
    }
    
    self.animationImages = allImage;
    self.animationDuration = totalDuration;
    
    [self startAnimating];
    CFRelease(imageSource);
}


@end

