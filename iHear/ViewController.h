//
//  ViewController.h
//  iHear
//
//  Created by Mayanka  on 9/26/15.
//  Copyright © 2015 umkc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <AVFoundation/AVFoundation.h>


/*  EZAudio  */
#import "EZAudio/EZAudio.h"


@interface ViewController : UIViewController <EZMicrophoneDelegate, EZAudioFFTDelegate>

@property (strong, nonatomic) IBOutlet UIButton *RecordButtom;

@property (strong, nonatomic) IBOutlet UIButton *PlayButton;
@property (strong, nonatomic) IBOutlet UIButton *PauseButton;

@property (strong, nonatomic) IBOutlet UIButton *StopButton;

@property (strong, nonatomic) AVAudioRecorder *audioRecorder;
@property (strong, nonatomic) AVAudioPlayer *audioPlayer;

#pragma mark - EZAudio Components

/**
 EZAudioPlot for frequency plot
 */
@property (nonatomic,weak) IBOutlet EZAudioPlot *audioPlotFreq;

/**
 EZAudioPlot for time plot
 */
@property (nonatomic,weak) IBOutlet EZAudioPlot *audioPlotTime;

/**
 A label used to display the maximum frequency (i.e. the frequency with the highest energy) calculated from the FFT.
 */
@property (nonatomic, weak) IBOutlet UILabel *maxFrequencyLabel;

/**
 The microphone used to get input.
 */
@property (nonatomic,strong) EZMicrophone *microphone;

/**
 Used to calculate a rolling FFT of the incoming audio data.
 */
@property (nonatomic, strong) EZAudioFFTRolling *fft;


- (IBAction)RecordAudio:(id)sender;

- (IBAction)PlayAudio:(id)sender;

//- (IBAction)PauseAudio:(id)sender;

- (IBAction)StopAudio:(id)sender;

@end

