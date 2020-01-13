# WGAVAudioPlayerNodePlayer
#####(有错误的地方请指教)
###AVAudioEngine播放变速不变调,AVAudioPlayerNode获取总时间以及当前播放时间

AVAudioPlayer也能通过rate属性控制播放的速率，但是变速后会变调，而AVAudioEngine能做到控制播放变速不变调。

    //1,create Node
    self.mbEngine = [AVAudioEngine new];
    self.mbPlayerNode = [AVAudioPlayerNode new];
    self.mbAudioUnitTimePitch = [AVAudioUnitTimePitch new];
    self.mbAudioUnitVarispeed = [AVAudioUnitVarispeed new];
    
    [self.mbEngine attachNode:self.mbPlayerNode];
    [self.mbEngine attachNode:self.mbAudioUnitTimePitch];
    [self.mbEngine attachNode:self.mbAudioUnitVarispeed];
    
    //2,connectNode
    [self.mbEngine connect:self.mbPlayerNode to:self.mbAudioUnitTimePitch format:self.mbAudioFile.processingFormat];
    
    [self.mbEngine connect:self.mbAudioUnitTimePitch to:self.mbAudioUnitVarispeed format:self.mbAudioFile.processingFormat];
    
    [self.mbEngine connect:self.mbAudioUnitVarispeed to:self.mbEngine.mainMixerNode format:self.mbAudioFile.processingFormat];
    //3,start Engine
    [self.mbEngine prepare];
    [self.mbEngine startAndReturnError:&error];
   
    //通过设置mbAudioUnitVarispeed和AVAudioUnitTimePitch来控制速度和音调。两者间存在个关系。
    float  speed = 0.5;
    float  pitch = 0;
    pitch = fabsf(log2f(speed)) *1200;
    self.mbAudioUnitVarispeed.rate = speed;
    self.mbAudioUnitTimePitch.pitch = pitch;
    
    
    //4,然后是播放,控制一下两边极值
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
            [self.mbPlayerNode play];
        }
    }
   
    
    ###关于获取总时间和当前的播放时间
    AVAudioTime *playerTime = [self.mbPlayerNode playerTimeForNodeTime:self.mbPlayerNode.lastRenderTime];
      self.playerNodeCurrenttime = (self.lastStartFramePosition+playerTime.sampleTime)/playerTime.sampleRate;
