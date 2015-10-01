//
//  ViewController.m
//  iHear
//
//  Created by Mayanka  on 9/26/15.
//  Copyright © 2015 umkc. All rights reserved.
//

#import "ViewController.h"



@interface ViewController ()

@end

static vDSP_Length const ViewControllerFFTWindowSize = 4096;

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    //Setting up AVAudioSession. If not EZMicrophone will not work properly in ios
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error;
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    if (error)
    {
        NSLog(@"Error setting up audio session category: %@", error.localizedDescription);
    }
    [session setActive:YES error:&error];
    if (error)
    {
        NSLog(@"Error setting up audio session active: %@", error.localizedDescription);
    }

    //Setup time domain audio plot
    self.audioPlotTime.plotType = EZPlotTypeBuffer;
    self.maxFrequencyLabel.numberOfLines = 0;
    
    //Setup frequency domain audio plot
    self.audioPlotFreq.shouldFill = YES;
    self.audioPlotFreq.plotType = EZPlotTypeBuffer;
    self.audioPlotFreq.shouldCenterYAxis = NO;
    
    //Create an instance of the microphone, and tell the viewcontroller to use this instance as the delegate
    
    self.microphone = [EZMicrophone microphoneWithDelegate:self];
    
    //Create an instance of the EZAudioFFTRolling to keep a history of the incomming audio data and calculate the FFT
    
    self.fft = [EZAudioFFTRolling fftWithWindowSize:ViewControllerFFTWindowSize
                                         sampleRate:self.microphone.audioStreamBasicDescription.mSampleRate
                                           delegate:self];
    
    
    //Start the mic
    [self.microphone startFetchingAudio];
    
    
    
    
    // Do any additional setup after loading the view, typically from a nib.
    _PlayButton.enabled = NO;
    _StopButton.enabled = NO;
    _PauseButton.enabled = NO;
    
    NSArray *dirpaths;
    NSString *docsDir;
    
    dirpaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    docsDir = dirpaths[0];
    
    NSString *soundFilePath = [docsDir stringByAppendingPathComponent:@"sound.caf"];
    
    NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
    
    NSDictionary *recordSettings = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:AVAudioQualityMin],AVEncoderAudioQualityKey,[NSNumber numberWithInt:16],AVEncoderBitRateKey,[NSNumber numberWithInt:2],AVNumberOfChannelsKey,[NSNumber numberWithFloat:44100.0],AVSampleRateKey, nil];
    
    NSError *audioerror = nil;
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord
                        error:nil];
    
    _audioRecorder = [[AVAudioRecorder alloc]
                      initWithURL:soundFileURL
                      settings:recordSettings
                      error:&audioerror];
    
    if (audioerror)
    {
        NSLog(@"error: %@", [error localizedDescription]);
    } else {
        [_audioRecorder prepareToRecord];
    }
}

#pragma mark - MemoryWarning

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - EZMicrophoneDelegate

- (void) microphone:(EZMicrophone *)microphone hasAudioReceived:(float **)buffer withBufferSize:(UInt32)bufferSize withNumberOfChannels:(UInt32)numberOfChannels{
    
    //buffer[0] - left , biffer[1] - right
    //Calculate FFT, will triger EZAudioFFTDelegate
    [self.fft computeFFTWithBuffer:buffer[0] withBufferSize:bufferSize];
    
    __weak typeof (self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.audioPlotTime updateBuffer:buffer[0]
                              withBufferSize:bufferSize];
    });
}

#pragma mark - EZAudioFFTDelegate

- (void) fft:(EZAudioFFT *)fft
 updatedWithFFTData:(float *)fftData
         bufferSize:(vDSP_Length)bufferSize
{
    float maxFrequency = [fft maxFrequency];
    NSString *noteName = [EZAudioUtilities noteNameStringForFrequency:maxFrequency
                                                        includeOctave:YES];
    
    __weak typeof (self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.maxFrequencyLabel.text = [NSString stringWithFormat:@"Highest Note: %@,\nFrequency: %.2f", noteName, maxFrequency];
        [weakSelf.audioPlotFreq updateBuffer:fftData withBufferSize:(UInt32)bufferSize];
    });
}

#pragma recording and pausing

- (IBAction)RecordAudio:(id)sender {
    if (!_audioRecorder.recording)
    {
        _PlayButton.enabled = NO;
        _StopButton.enabled = YES;
        _PauseButton.enabled =YES;
        [_audioRecorder record];
    }
}

- (IBAction)PlayAudio:(id)sender {
    if (!_audioRecorder.recording)
    {
        _StopButton.enabled = YES;
        _PauseButton.enabled = YES;
        _RecordButtom.enabled = NO;
        
        NSError *error;
        
        _audioPlayer = [[AVAudioPlayer alloc]
                        initWithContentsOfURL:_audioRecorder.url
                        error:&error];
        
        _audioPlayer.delegate = self;
        
        if (error)
            NSLog(@"Error: %@",
                  [error localizedDescription]);
        else
            [_audioPlayer play];
    }
}

- (IBAction)StopAudio:(id)sender {
    _StopButton.enabled = NO;
    _PauseButton.enabled = NO;
    _PlayButton.enabled = YES;
    _RecordButtom.enabled = YES;
    
    if (_audioRecorder.recording)
    {
        [_audioRecorder stop];
    } else if (_audioPlayer.playing) {
        [_audioPlayer stop];
    }
}

#pragma Deligate Methods-indicate errors

-(void)audioPlayerDidFinishPlaying:
(AVAudioPlayer *)player successfully:(BOOL)flag
{
    _RecordButtom.enabled = YES;
    _StopButton.enabled = NO;
}

-(void)audioPlayerDecodeErrorDidOccur:
(AVAudioPlayer *)player error:(NSError *)error
{
    NSLog(@"Decode Error occurred");
}

-(void)audioRecorderDidFinishRecording:
(AVAudioRecorder *)recorder
                          successfully:(BOOL)flag
{
}

-(void)audioRecorderEncodeErrorDidOccur:
(AVAudioRecorder *)recorder
                                  error:(NSError *)error
{
    NSLog(@"Encode Error occurred");
}

@end
