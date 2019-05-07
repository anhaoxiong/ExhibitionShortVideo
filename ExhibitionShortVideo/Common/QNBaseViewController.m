//
//  QNBaseViewController.m
//  PLShortVideoKitDemo
//
//  Created by hxiongan on 2018/2/1.
//  Copyright © 2018年 Pili Engineering, Qiniu Inc. All rights reserved.
//

#import "QNBaseViewController.h"
#import <Masonry.h>
#import <sys/utsname.h>
#import <MediaPlayer/MediaPlayer.h>
#import <Photos/Photos.h>

@interface QNBaseViewController ()
@end

@implementation QNBaseViewController

- (void)dealloc {
    NSLog(@"[dealloc] %@", self.description);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:25.0/255 green:24.0/255 blue:36.0/255 alpha:1];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)showWating {
    if (nil == self.activityIndicatorView) {
        self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:self.view.bounds];
        self.activityIndicatorView.center = self.view.center;
        [self.activityIndicatorView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhite];
        self.activityIndicatorView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    }
    
    [self.view addSubview:self.activityIndicatorView];
    if (![self.activityIndicatorView isAnimating]) {
        [self.activityIndicatorView startAnimating];
    }
}

- (void)hideWating {
    if ([self.activityIndicatorView isAnimating]) {
        [self.activityIndicatorView stopAnimating];
    }
    [self.activityIndicatorView removeFromSuperview];
    [self.progressLabel removeFromSuperview];
    self.progressLabel.text = @"";
}

- (void)setProgress:(CGFloat)progress {
    if (nil == self.progressLabel) {
        self.progressLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 22)];
        self.progressLabel.textAlignment =  NSTextAlignmentCenter;
        self.progressLabel.textColor = [UIColor lightTextColor];
        self.progressLabel.center = CGPointMake(self.view.center.x, self.view.center.y + 20);
        self.progressLabel.font = [UIFont monospacedDigitSystemFontOfSize:14 weight:(UIFontWeightRegular)];
    }
    [self.view addSubview:self.progressLabel];
    
    self.progressLabel.text = [NSString stringWithFormat:@"%d%%", (int)(progress * 100)];
}


- (void)showAlertMessage:(NSString *)title message:(NSString *)message {
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:(UIAlertControllerStyleAlert)];
    UIAlertAction *sureAction = [UIAlertAction actionWithTitle:@"确定" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
    }];
    [alert addAction:sureAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

+ (NSURL *)movieURL:(PHAsset *)phasset {
    
    __block NSURL *url = nil;
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
    options.version = PHVideoRequestOptionsVersionOriginal;
    options.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
    options.networkAccessAllowed = YES;
    
    PHImageManager *manager = [PHImageManager defaultManager];
    [manager requestAVAssetForVideo:phasset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
        AVURLAsset *urlAsset = (AVURLAsset *)asset;
        url = urlAsset.URL;
        
        dispatch_semaphore_signal(semaphore);
    }];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return url;
}

+ (NSInteger)suitableVideoBitrateWithSize:(CGSize)videoSize {
    
    if (videoSize.width + videoSize.height > 720 + 1280) {
        // 1080P 的，使用 6M 码率
        return 6 * 1000 * 1000;
    } else if (videoSize.width + videoSize.height > 540 + 960) {
        // 720P  的，使用 3M 码率
        return 3 * 1000 * 1000;
    } else if (videoSize.width + videoSize.height > 360 + 640) {
        // 小于 360P ~ 540P 之间的使用 1.5 M 码率
        return 1.5 * 1000 * 1000;
    } else {
        return 1.0 * 1000 * 1000;
    }
}

+ (PLSAudioBitRate)suitableAudioBitrateWithSampleRate:(CGFloat)sampleRate channel:(NSInteger)channel {
    
    if (sampleRate >= 44100) {
        if (1 == channel) {
            return PLSAudioBitRate_64Kbps;
        } else {
            return PLSAudioBitRate_128Kbps;
        }
    } else if (sampleRate >= 22050) {
        if (1 == channel) {
            return PLSAudioBitRate_32Kbps;
        } else {
            return PLSAudioBitRate_64Kbps;
        }
    } else {
        return PLSAudioBitRate_32Kbps;
    }
    
    return PLSAudioBitRate_64Kbps;
}

- (void)requestMPMediaLibraryAuth:(void (^)(BOOL))completeBlock {
    
    if (MPMediaLibraryAuthorizationStatusDenied == [MPMediaLibrary authorizationStatus]) {
        [self.view showTip:@"请到系统设置中允许对音乐库的访问"];
        completeBlock(NO);
        return;
    } else if (MPMediaLibraryAuthorizationStatusNotDetermined == [MPMediaLibrary authorizationStatus]) {
        [MPMediaLibrary requestAuthorization:^(MPMediaLibraryAuthorizationStatus status) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (MPMediaLibraryAuthorizationStatusAuthorized == status) {
                    completeBlock(YES);
                } else {
                    [self.view showTip:@"请到系统设置中允许对音乐库的访问"];
                    completeBlock(NO);
                }
            });
        }];
    } else if (MPMediaLibraryAuthorizationStatusAuthorized == [MPMediaLibrary authorizationStatus]){
        completeBlock(YES);
    }
}

- (void)requestCameraAuth:(void (^)(BOOL))completeBlock {
    
    if (AVAuthorizationStatusDenied == [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
        [self.view showTip:@"请到系统设置中允许对相机的访问"];
        completeBlock(NO);
        return;
    } else if (AVAuthorizationStatusNotDetermined == [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            if (granted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completeBlock(YES);
                });
            } else {
                [self.view showTip:@"请到系统设置中允许对相机的访问"];
                completeBlock(NO);
            }
        }];
    } else if (AVAuthorizationStatusAuthorized == [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]){
        completeBlock(YES);
    }
}

- (void)requestMicrophoneAuth:(void (^)(BOOL))completeBlock {
    
    if (AVAuthorizationStatusDenied == [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio]) {
        [self.view showTip:@"请到系统设置中允许对麦克风的访问"];
        completeBlock(NO);
        return;
    } else if (AVAuthorizationStatusNotDetermined == [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio]) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
            if (granted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completeBlock(YES);
                });
            } else {
                [self.view showTip:@"请到系统设置中允许对麦克风的访问"];
                completeBlock(NO);
            }
        }];
    } else if (AVAuthorizationStatusAuthorized == [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio]){
        completeBlock(YES);
    }
}

- (void)requestPhotoLibraryAuth:(void (^)(BOOL))completeBlock {
    
    if (PHAuthorizationStatusDenied == [PHPhotoLibrary authorizationStatus]) {
        [self.view showTip:@"请到系统设置中允许对相册的访问"];
        completeBlock(NO);
        return;
    } else if (PHAuthorizationStatusNotDetermined == [PHPhotoLibrary authorizationStatus]) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            if (PHAuthorizationStatusAuthorized == status) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completeBlock(YES);
                });
            } else {
                [self.view showTip:@"请到系统设置中允许对相册的访问"];
                completeBlock(NO);
            }
        }];
    } else if (PHAuthorizationStatusAuthorized == [PHPhotoLibrary authorizationStatus]){
        completeBlock(YES);
    }
}

- (NSString *)formatTimeString:(NSTimeInterval)time {
    NSInteger intValue = round(time);
    int min = intValue / 60;
    int second = intValue % 60;
    return [NSString stringWithFormat:@"%02d:%02d", min, second];
}

+ (EnumDeviceType)deviceType {
    
//    https://stackoverflow.com/questions/26028918/how-to-determine-the-current-iphone-device-model/40091083
    
    struct utsname info = {0};
    uname(&info);
    NSString *modelName = [NSString stringWithUTF8String:info.machine];
    if ([modelName isEqualToString:@"iPhone3,1"] ||
        [modelName isEqualToString:@"iPhone3,2"] ||
        [modelName isEqualToString:@"iPhone3,3"]) {
        return enumDeviceTypeIPhone4;
    } else if ([modelName isEqualToString:@"iPhone4,1"]) {
        return enumDeviceTypeIPhone4s;
    } else if ([modelName isEqualToString:@"iPhone5,1"] ||
               [modelName isEqualToString:@"iPhone5,2"]) {
        return enumDeviceTypeIPhone5;
    } else if ([modelName isEqualToString:@"iPhone5,3"] ||
               [modelName isEqualToString:@"iPhone5,4"]) {
        return enumDeviceTypeIPhone5c;
    } else if ([modelName isEqualToString:@"iPhone6,1"] ||
               [modelName isEqualToString:@"iPhone6,2"]) {
        return enumDeviceTypeIPhone5s;
    } else if ([modelName isEqualToString:@"iPhone7,2"]) {
        return enumDeviceTypeIPhone6;
    } else if ([modelName isEqualToString:@"iPhone7,1"]) {
        return enumDeviceTypeIPhone6Plus;
    } else if ([modelName isEqualToString:@"iPhone8,1"]) {
        return enumDeviceTypeIPhone6s;
    } else if ([modelName isEqualToString:@"iPhone8,2"]) {
        return enumDeviceTypeIPhone6sPlus;
    } else if ([modelName isEqualToString:@"iPhone9,1"] ||
               [modelName isEqualToString:@"iPhone9,3"]) {
        return enumDeviceTypeIPhone7;
    } else if ([modelName isEqualToString:@"iPhone9,2"] ||
               [modelName isEqualToString:@"iPhone9,4"]) {
        return enumDeviceTypeIPhone7Plus;
    } else if ([modelName isEqualToString:@"iPhone8,4"]) {
        return enumDeviceTypeIPhoneSE;
    } else if ([modelName isEqualToString:@"iPhone10,1"] ||
               [modelName isEqualToString:@"iPhone10,4"]) {
        return enumDeviceTypeIPhone8;
    } else if ([modelName isEqualToString:@"iPhone10,2"] ||
               [modelName isEqualToString:@"iPhone10,5"]) {
        return enumDeviceTypeIPhone8Plus;
    } else if ([modelName isEqualToString:@"iPhone10,3"] ||
               [modelName isEqualToString:@"iPhone10,6"]) {
        return enumDeviceTypeIPhoneX;
    } else if ([modelName isEqualToString:@"iPhone11,2"]) {
        return enumDeviceTypeIPhoneXS;
    } else if ([modelName isEqualToString:@"iPhone11,4"] ||
               [modelName isEqualToString:@"iPhone11,6"]) {
        return enumDeviceTypeIPhoneXSMax;
    } else if ([modelName isEqualToString:@"iPhone11,8"]) {
        return enumDeviceTypeIPhoneXR;
    }
    
    return enumDeviceTypeIPhoneX;
}
@end
