//
//  QNBaseViewController.h
//  PLShortVideoKitDemo
//
//  Created by hxiongan on 2018/2/1.
//  Copyright © 2018年 Pili Engineering, Qiniu Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PLShortVideoKit/PLSTypeDefines.h>

#define iPhoneX_SERIES (enumDeviceTypeIPhoneXR == [QNBaseViewController deviceType] || enumDeviceTypeIPhoneX == [QNBaseViewController deviceType] || enumDeviceTypeIPhoneXS == [QNBaseViewController deviceType] || enumDeviceTypeIPhoneXSMax == [QNBaseViewController deviceType])


typedef enum : NSUInteger {
    //iPhone
    enumDeviceTypeIPhone4,
    enumDeviceTypeIPhone4s,
    enumDeviceTypeIPhone5,
    enumDeviceTypeIPhone5c,
    enumDeviceTypeIPhone5s,
    enumDeviceTypeIPhone6,
    enumDeviceTypeIPhone6Plus,
    enumDeviceTypeIPhone6s,
    enumDeviceTypeIPhone6sPlus,
    enumDeviceTypeIPhoneSE,
    enumDeviceTypeIPhone7,
    enumDeviceTypeIPhone7Plus,
    enumDeviceTypeIPhone8,
    enumDeviceTypeIPhone8Plus,
    enumDeviceTypeIPhoneX,
    enumDeviceTypeIPhoneXS,
    enumDeviceTypeIPhoneXR,
    enumDeviceTypeIPhoneXSMax,
    
    //iPad
    //......
    
} EnumDeviceType;

@import Photos;

@interface QNBaseViewController : UIViewController

@property (strong, nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (strong, nonatomic) UILabel *progressLabel;

- (void)showWating;

- (void)hideWating;

- (void)setProgress:(CGFloat)progress;

+ (NSURL *)movieURL:(PHAsset *)phasset;

+ (EnumDeviceType)deviceType;

+ (NSInteger)suitableVideoBitrateWithSize:(CGSize)videoSize;

+ (PLSAudioBitRate)suitableAudioBitrateWithSampleRate:(CGFloat)sampleRate channel:(NSInteger)channel;

- (void)showAlertMessage:(NSString *)title message:(NSString *)message;

- (void)requestMPMediaLibraryAuth:(void(^)(BOOL succeed))completeBlock;

- (void)requestCameraAuth:(void(^)(BOOL succeed))completeBlock;

- (void)requestMicrophoneAuth:(void(^)(BOOL succeed))completeBlock;

- (void)requestPhotoLibraryAuth:(void(^)(BOOL succeed))completeBlock;

- (NSString *)formatTimeString:(NSTimeInterval)time;

@end
