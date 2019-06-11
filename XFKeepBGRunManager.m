//
//  KeepBGRunManager.m
//  TestPod
//
//  Created by 李雪峰 on 2019/6/3.
//  Copyright © 2019 李雪峰. All rights reserved.
//

#import "XFKeepBGRunManager.h"
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
///循环时间
static NSInteger _circulaDuration = 30;
static XFKeepBGRunManager *_sharedManger;

@interface XFKeepBGRunManager ()
@property (nonatomic,assign) UIBackgroundTaskIdentifier task;
///后台播放
@property (nonatomic,strong) AVAudioPlayer *playerBack;
@property (nonatomic, strong) NSTimer *timerAD;
///用来打印测试
@property (nonatomic, strong) NSTimer *timerLog;
@property (nonatomic,assign) NSInteger count;

@end

@implementation XFKeepBGRunManager
{
    CFRunLoopRef _runloopRef;
    dispatch_queue_t _queue;
}

+ (instancetype)shareManager{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!_sharedManger) {
            _sharedManger = [[XFKeepBGRunManager alloc] init];
        }
    });
    return _sharedManger;
}

/// 重写init方法，初始化音乐文件
- (instancetype)init {
    if (self = [super init]) {
        [self setupAudioSession];
        _queue = dispatch_queue_create("com.audio.inBackground", NULL);
        // 任意音频文件，但不能为空
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"systemSound1" ofType:@"wav"];
        NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:filePath];
        self.playerBack = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:nil];
        [self.playerBack prepareToPlay];
        // 0.0~1.0,默认为1.0
//        self.playerBack.volume = 1.0;
        // 循环播放
        self.playerBack.numberOfLoops = -1;
    }
    return self;
}

- (void)setupAudioSession {
    // 新建AudioSession会话
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    // 设置后台播放
    NSError *error = nil;
    [audioSession setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionMixWithOthers error:&error];
    if (error) {
        NSLog(@"Error setCategory AVAudioSession: %@", error);
    }
    NSLog(@"%d", audioSession.isOtherAudioPlaying);
    NSError *activeSetError = nil;
    // 启动AudioSession，如果一个前台app正在播放音频则可能会启动失败
    [audioSession setActive:YES error:&activeSetError];
    if (activeSetError) {
        NSLog(@"Error activating AVAudioSession: %@", activeSetError);
    }
}

/**
 启动后台运行
 */
- (void)startBGRun{
    [self.playerBack play];
    [self applyforBackgroundTask];
    ///确保两个定时器同时进行
    dispatch_async(_queue, ^{
        self.timerLog = [[NSTimer alloc] initWithFireDate:[NSDate date] interval:1 target:self selector:@selector(log) userInfo:nil repeats:YES];
        self.timerAD = [[NSTimer alloc] initWithFireDate:[NSDate date] interval:_circulaDuration target:self selector:@selector(startAudioPlay) userInfo:nil repeats:YES];
        _runloopRef = CFRunLoopGetCurrent();
        [[NSRunLoop currentRunLoop] addTimer:self.timerAD forMode:NSDefaultRunLoopMode];
        [[NSRunLoop currentRunLoop] addTimer:self.timerLog forMode:NSDefaultRunLoopMode];
        CFRunLoopRun();
    });
}

/**
 申请后台
 */
- (void)applyforBackgroundTask{
    _task =[[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] endBackgroundTask:_task];
            _task = UIBackgroundTaskInvalid;
        });
    }];
}

/**
 打印
 */
- (void)log{
    _count = _count + 1;
    NSLog(@"_count = %ld",_count);
}

/**
 检测后台运行时间
 */
- (void)startAudioPlay{
    _count = 0;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([[UIApplication sharedApplication] backgroundTimeRemaining] < _circulaDuration + 1) {
            NSLog(@"后台快被杀死了");
            [self.playerBack play];
            [self applyforBackgroundTask];
        }
        else{
            NSLog(@"后台继续活跃呢");
        }///再次执行播放器停止，后台一直不会播放音乐文件
        [self.playerBack stop];
    });
}

/**
 停止后台运行
 */
- (void)stopBGRun{
    if (self.timerAD) {
        CFRunLoopStop(_runloopRef);
        [self.timerLog invalidate];
        self.timerLog = nil;
        // 关闭定时器即可
        [self.timerAD invalidate];
        self.timerAD = nil;
        [self.playerBack stop];
    }
    if (_task) {
        [[UIApplication sharedApplication] endBackgroundTask:_task];
        _task = UIBackgroundTaskInvalid;
    }
}

@end
