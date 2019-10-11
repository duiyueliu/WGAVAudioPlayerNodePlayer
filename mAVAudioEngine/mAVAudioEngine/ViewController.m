//
//  ViewController.m
//  mAVAudioEngine
//
//  Created by shikaiming on 2019/9/9.
//  Copyright © 2019 skm. All rights reserved.
//

#import "ViewController.h"

#import "WGAudioPlayer.h"


@interface ViewController ()

@property (nonatomic, strong) WGAudioPlayer *player;

@property (weak, nonatomic) IBOutlet UISlider *mySlider;
@property (weak, nonatomic) IBOutlet UILabel *myRateLabel;
@property (weak, nonatomic) IBOutlet UIStepper *myStepper;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.myStepper.value = 1.0;
    self.myRateLabel.text = @"rate:1.0";
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"music1" ofType:@"mp3"];
    
    NSString *headsetPath = [[NSBundle mainBundle] pathForResource:@"music2" ofType:@"mp3"];
    
    self.player = [WGAudioPlayer new];
    [self.player initMbPlayerWithFile:path andHeadsetBgm:headsetPath];
    [self.player mbAudioSeekTime:0.0];
    [self.player mbAudioPlay];
}

- (IBAction)destroyEngine:(id)sender {
    [self.player destroyPlayer];
}

- (IBAction)startNode:(id)sender {
 
    [self.player mbAudioSeekTime:self.mySlider.value * self.player.playerNodeDuration];
    [self.player mbAudioPlay];
}

- (IBAction)stopNode:(id)sender {

    [self.player mbAudioStop];
}

- (IBAction)pauseNode:(UIButton *)sender {
    [self.player mbAudioPause];
}

- (IBAction)startEngine:(id)sender {
    
    [self.player mbRedayForEngine];
}

- (IBAction)stopEngine:(id)sender {

    NSLog(@"engine stop");
    [self.player testForEngineStop];
}

- (IBAction)mySlider:(UISlider *)sender {
    
    double seekValue = sender.value;
    NSLog(@"当前进度比例%f",seekValue);

    [self.player mbAudioSeekTime:seekValue *self.player.playerNodeDuration];
    
}
- (IBAction)MyStepper:(UIStepper *)sender {
    
    NSLog(@"%f",sender.value);
    self.myRateLabel.text = [NSString stringWithFormat:@"rate:%.2f",sender.value];
    [self.player setupSpeed:sender.value];
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    if (self.player.isNeedToChangeHeadset) {
        [self.player musicChangeToSpeaker];
    }else{
        [self.player musicChangeToHeadset];
        
    }
}

@end
