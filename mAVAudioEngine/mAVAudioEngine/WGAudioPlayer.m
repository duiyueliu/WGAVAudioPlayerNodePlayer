//
//  WGAudioPlayer.m
//  mAVAudioEngine
//
//  Created by shikaiming on 2019/9/29.
//  Copyright © 2019 skm. All rights reserved.
//

#import "WGAudioPlayer.h"


@interface WGAudioPlayer ()

@property (nonatomic, strong) AVAudioEngine *mbEngine;

@property (nonatomic, strong) AVAudioPlayerNode *mbPlayerNode;

@property (nonatomic, strong) AVAudioUnitTimePitch *mbAudioUnitTimePitch;
@property (nonatomic, strong) AVAudioUnitVarispeed *mbAudioUnitVarispeed;


@property (nonatomic, strong) AVAudioFile *mbAudioFile;

@property (nonatomic, strong) AVAudioFile *mbHeadsetAudioFile;


@property (nonatomic, strong) dispatch_source_t timer;

@property (nonatomic, assign) double playerNodeDuration;

@property (nonatomic, copy) NSString     *bgmMp3FilePath;

@property (nonatomic, copy) NSString     *headsetBgmMp3FilePath;

/** 是否需要切换为耳机伴奏*/
@property (nonatomic, assign) BOOL isNeedToChangeHeadset;

/** 当前播放的进度，秒*/
@property (nonatomic, assign) double playerNodeCurrenttime;

/** 开始播放前位置*/
@property (nonatomic, assign) double lastStartFramePosition;

@end

@implementation WGAudioPlayer

- (void)initMbPlayerWithFile:(NSString *)bgmMp3FilePath andHeadsetBgm:(NSString *)headsetBgmMp3FilePath{

    NSError *error;
    
    @try {
        self.mbAudioFile = [[AVAudioFile alloc] initForReading:[NSURL fileURLWithPath:bgmMp3FilePath] error:&error];
    }
    @catch (NSException *exception) {
        NSLog(@"mbAudioFileError:%@",exception.reason);
           if (self.mbPlayerErrorBlock) {
               self.mbPlayerErrorBlock(exception);
           }
    }
    @finally {

    }
    
    if (headsetBgmMp3FilePath) {
        self.headsetBgmMp3FilePath = headsetBgmMp3FilePath;
        @try {
            self.mbHeadsetAudioFile = [[AVAudioFile alloc] initForReading:[NSURL fileURLWithPath:headsetBgmMp3FilePath] error:&error];
        } @catch (NSException *exception) {
            NSLog(@"mbHeadsetAudioFileError:%@",error.localizedDescription);
        } @finally {

        }

    }
    
    //总时长
    @try {
        self.playerNodeDuration = self.mbAudioFile.length/self.mbAudioFile.processingFormat.sampleRate;
    }
    @catch (NSException *exception) {
        NSLog(@"playerNodeDurationError:%@",exception.reason);
        if (self.mbPlayerErrorBlock) {
            self.mbPlayerErrorBlock(exception);
        }
    }
    @finally {
       
    }
    
    [self mbRedayForEngine];

}

- (void)mbAudioPlay{
    NSError *error;
    
    if (self.mbEngine) {
        if (!self.mbEngine.isRunning) {
            [self.mbEngine startAndReturnError:&error];
        }
    }else{
        [self mbRedayForEngine];
    }
    
    if (error) {
        NSLog(@"mbAudioPlay_mbEngineError:%@",error.localizedDescription);
        NSException *exception = [NSException exceptionWithName:@"mbEngineStartError" reason:error.localizedDescription userInfo:error.userInfo];
        if (self.mbPlayerErrorBlock) {
            self.mbPlayerErrorBlock(exception);
        }
        return;
    }else{
        @try {
            [self.mbPlayerNode play];
        } @catch (NSException *exception) {
            if (self.mbPlayerErrorBlock) {
                self.mbPlayerErrorBlock(exception);
            }
            return;
        } @finally {
            
        }
    }
    
    [self startGCD];

}

- (void)mbRedayForEngine{
    NSError *error;
    
    //attachNode
    self.mbEngine = [AVAudioEngine new];
    self.mbPlayerNode = [AVAudioPlayerNode new];
    self.mbAudioUnitTimePitch = [AVAudioUnitTimePitch new];
    self.mbAudioUnitVarispeed = [AVAudioUnitVarispeed new];
    
    [self.mbEngine attachNode:self.mbPlayerNode];
    [self.mbEngine attachNode:self.mbAudioUnitTimePitch];
    [self.mbEngine attachNode:self.mbAudioUnitVarispeed];
    
    
    //connectNode
    [self.mbEngine connect:self.mbPlayerNode to:self.mbAudioUnitTimePitch format:self.mbAudioFile.processingFormat];
    
    [self.mbEngine connect:self.mbAudioUnitTimePitch to:self.mbAudioUnitVarispeed format:self.mbAudioFile.processingFormat];
    
    [self.mbEngine connect:self.mbAudioUnitVarispeed to:self.mbEngine.mainMixerNode format:self.mbAudioFile.processingFormat];
    
    [self.mbEngine prepare];
    
    @try {
        [self.mbEngine startAndReturnError:&error];
        if (error) {
            NSLog(@"mbEngineError:%@",error.localizedDescription);
        }
    }
    @catch (NSException *exception) {
        NSLog(@"mbEngineError:%@",exception.reason);
        if (self.mbPlayerErrorBlock) {
            self.mbPlayerErrorBlock(exception);
        }
    }
    @finally {

    }

}

- (void)mbAudioPause{
    
    [self.mbPlayerNode pause];
}

- (void)mbAudioStop{
    [self.mbPlayerNode stop];
}

- (void)mbAudioSeekTime:(double)seekTime{
    
    seekTime = seekTime > self.playerNodeDuration ? self.playerNodeDuration : seekTime;
    
    AVAudioFile *tempFile = self.mbAudioFile;
    
    if (self.isNeedToChangeHeadset) {
        tempFile = self.mbHeadsetAudioFile;
        if (!self.mbHeadsetAudioFile) {
            return;
        }
    }else{
        tempFile = self.mbAudioFile;
        if (!self.mbAudioFile) {
            return;
        }
    }
    
    
    //以实际音频长度为主
    seekTime = seekTime > self.playerNodeDuration ? self.playerNodeDuration : seekTime;
    
    seekTime = seekTime > 0 ? seekTime : 0;
    
    AVAudioFramePosition seekFrame = seekTime * tempFile.processingFormat.sampleRate;
    //记录一下播放前的位置,用来计算当前的播放时间
    self.lastStartFramePosition = seekFrame;
    AVAudioFrameCount frameCount = (AVAudioFrameCount)(tempFile.length - seekFrame);
    
    BOOL isPlaying = self.mbPlayerNode.isPlaying;
    
    [self.mbPlayerNode stop];
    
    if (seekFrame < (AVAudioFramePosition)tempFile.length) {
        
        [self.mbPlayerNode scheduleSegment:tempFile startingFrame:seekFrame frameCount:frameCount atTime:nil completionHandler:^{
            
        }];
        
        if (isPlaying) {
            [self mbAudioPlay];
        }
    }
    
}

/** 播放正常伴奏*/
- (void)musicChangeToSpeaker{
    
    self.isNeedToChangeHeadset = NO;
    
    @try {
        self.playerNodeDuration = self.mbAudioFile.length/self.mbAudioFile.processingFormat.sampleRate;
    }
    @catch (NSException *exception) {
        NSLog(@"musicChangeToSpeaker_playerNodeDurationError:%@",exception.reason);
    }
    @finally {
        
    }
    
    [self mbAudioSeekTime:self.playerNodeCurrenttime];
}

/** 播放耳机伴奏*/
- (void)musicChangeToHeadset{
    
    //如果耳机伴奏不存在，沿用正常伴奏，不进行切换
    if (!self.mbHeadsetAudioFile) {
        return;
    }
    
    self.isNeedToChangeHeadset = YES;
    
    @try {
        self.playerNodeDuration = self.mbHeadsetAudioFile.length/self.mbHeadsetAudioFile.processingFormat.sampleRate;
    }
    @catch (NSException *exception) {
        NSLog(@"musicChangeToHeadset_playerNodeDurationError:%@",exception.reason);
    }
    @finally {
        
    }
    
        [self mbAudioSeekTime:self.playerNodeCurrenttime];
    
}

- (void)destroyPlayer{
    
    if (self.mbEngine) {
            [self.mbEngine stop];
            [self.mbEngine reset];
    }
    
    if (self.mbPlayerNode) {
        [self.mbPlayerNode stop];
    }
    
    [self cancelAndDeleteTimer];
    
    //清除本地的mp3文件
//    if (self.bgmMp3FilePath.length > 0) {
//        [self deleteRecognFile:self.bgmMp3FilePath];
//    }
//
//    if (self.headsetBgmMp3FilePath.length > 0) {
//        [self deleteRecognFile:self.headsetBgmMp3FilePath];
//    }
    
    
}

- (void)setupSpeed:(CGFloat)speed{

    float  pitch = 0;
    pitch = fabsf(log2f(speed)) *1200;
    self.mbAudioUnitVarispeed.rate = speed;
    self.mbAudioUnitTimePitch.pitch = pitch;
}

- (void)startGCD{
    [self cancelAndDeleteTimer];
    NSLog(@"开始时间%f",self.playerNodeCurrenttime);
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    self.timer = timer;
    
    dispatch_source_set_timer(timer,dispatch_walltime(NULL, 0),0.02*NSEC_PER_SEC, 0); //每秒执行
    
    dispatch_source_set_event_handler(timer, ^{
        
        dispatch_async(dispatch_get_main_queue(), ^{

            if (self.mbPlayerNode.isPlaying && self.mbEngine.isRunning) {
                AVAudioTime *playerTime = [self.mbPlayerNode playerTimeForNodeTime:self.mbPlayerNode.lastRenderTime];
                self.playerNodeCurrenttime = ( self.lastStartFramePosition+playerTime.sampleTime)/playerTime.sampleRate;
                NSLog(@"当前时间%f",self.playerNodeCurrenttime);
                if (self.playerNodeCurrentTimeAbseBlock) {
                    self.playerNodeCurrentTimeAbseBlock(self.playerNodeCurrenttime);
                }
                
                if (self.playerNodeCurrenttime >= self.playerNodeDuration) {
                                [self cancelAndDeleteTimer];
                            }
                if (self.playerNodeCurrentTimeAbseBlock) {
                    self.playerNodeCurrentTimeAbseBlock(self.playerNodeCurrenttime);
                }
            }else{
                [self cancelAndDeleteTimer];
            }

        });
    });
    
    dispatch_resume(timer);
}

- (void)cancelAndDeleteTimer {
    if (self.timer != nil) {
        dispatch_source_cancel(self.timer);
        self.timer = nil;
        NSLog(@"---取消监听,%f",self.playerNodeCurrenttime);
    }
    
}
             
- (void)deleteRecognFile:(NSString *)fileStr{
 
     NSFileManager *fileMgr = [NSFileManager defaultManager];
     NSError *error;
     if ([fileMgr fileExistsAtPath:fileStr]) {
         [fileMgr removeItemAtPath:fileStr error:&error];
         if (error) {
             NSLog(@"%@",error.localizedDescription);
         }else{
             NSLog(@"删除本地文件成功");
         }
         
     }else{
         NSLog(@"不存在该文件或文件夹");
     }
}

- (void)testForEngineStop{
    [self.mbEngine stop];
}
@end
