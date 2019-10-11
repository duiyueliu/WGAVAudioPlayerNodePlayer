//
//  WGAudioPlayer.h
//  mAVAudioEngine
//
//  Created by shikaiming on 2019/9/29.
//  Copyright © 2019 skm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WGAudioPlayer : NSObject

- (void)initMbPlayerWithFile:(NSString *)bgmMp3FilePath andHeadsetBgm:(NSString *)headsetBgmMp3FilePath;

- (void)mbAudioSeekTime:(double)seekTime;

- (void)mbAudioPlay;
- (void)mbAudioPause;
- (void)mbAudioStop;

- (void)mbRedayForEngine;

/** 设置变速*/
- (void)setupSpeed:(CGFloat)speed;

- (void)destroyPlayer;

/** errorBlock*/
@property (nonatomic, copy) void(^mbPlayerErrorBlock)(NSException *exception);

/** 总时长*/
@property (nonatomic, assign,readonly) double playerNodeDuration;

/** 当前播放的进度，秒*/
@property (nonatomic, assign,readonly) double playerNodeCurrenttime;

/** 当前播放时间回调*/
@property (nonatomic, copy) void(^playerNodeCurrentTimeAbseBlock)(double currentTime);

/** 是否需要切换为耳机伴奏*/
@property (nonatomic, assign,readonly) BOOL isNeedToChangeHeadset;

/** 播放正常伴奏*/
- (void)musicChangeToSpeaker;

/** 播放耳机伴奏*/
- (void)musicChangeToHeadset;

- (void)testForEngineStop;
@end

NS_ASSUME_NONNULL_END
