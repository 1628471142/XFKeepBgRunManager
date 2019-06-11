//
//  KeepBGRunManager.h
//  TestPod
//
//  Created by 李雪峰 on 2019/6/3.
//  Copyright © 2019 李雪峰. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XFKeepBGRunManager : NSObject
+ (instancetype)shareManager;

/**
 开启后台运行
 */
- (void)startBGRun;

/**
 关闭后台运行
 */
- (void)stopBGRun;

@end

NS_ASSUME_NONNULL_END
