//
//  ViewController.swift
//  AVAEMixerSample
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/2/28.
//
//
///*
//    Copyright (C) 2015 Apple Inc. All Rights Reserved.
//    See LICENSE.txt for this sample’s licensing information
//
//    Abstract:
//    View Controller class that drives the UI
//*/
//
//@import UIKit;
import UIKit
//
//@class AudioEngine, CAUITransportButton;
@objc(ViewController)
class ViewController: UIViewController, AudioEngineDelegate {
//@interface ViewController : UIViewController {
//    AudioEngine *engine;
    private var engine: AudioEngine!
//}
//@property (unsafe_unretained, nonatomic) IBOutlet UIButton *marimbaPlayButton;
    @IBOutlet weak var marimbaPlayButton: UIButton!
//@property (unsafe_unretained, nonatomic) IBOutlet UISlider *marimbaVolumeSlider;
    @IBOutlet weak var marimbaVolumeSlider: UISlider!
//@property (unsafe_unretained, nonatomic) IBOutlet UISlider *marimbaPanSlider;
    @IBOutlet weak var marimbaPanSlider: UISlider!
//
//@property (unsafe_unretained, nonatomic) IBOutlet UIButton *drumsPlayButton;
    @IBOutlet weak var drumsPlayButton: UIButton!
//@property (unsafe_unretained, nonatomic) IBOutlet UISlider *drumsVolumeSlider;
    @IBOutlet weak var drumsVolumeSlider: UISlider!
//@property (unsafe_unretained, nonatomic) IBOutlet UISlider *drumsPanSlider;
    @IBOutlet weak var drumsPanSlider: UISlider!
//
//@property (unsafe_unretained, nonatomic) IBOutlet CAUITransportButton *rewindButton;
    @IBOutlet weak var rewindButton: CAUITransportButton!
//@property (unsafe_unretained, nonatomic) IBOutlet CAUITransportButton *playButton;
    @IBOutlet weak var playButton: CAUITransportButton!
//@property (unsafe_unretained, nonatomic) IBOutlet CAUITransportButton *recordButton;
    @IBOutlet weak var recordButton: CAUITransportButton!
//
//- (IBAction)togglePlayMarimba:(id)sender;
//- (IBAction)setMarimbaVolume:(id)sender;
//- (IBAction)setMarimbaPan:(id)sender;
//
//- (IBAction)togglePlayDrums:(id)sender;
//- (IBAction)setDrumVolume:(id)sender;
//- (IBAction)setDrumPan:(id)sender;
//
//- (IBAction)rewindAction:(id)sender;
//- (IBAction)playPauseAction:(id)sender;
//- (IBAction)recordAction:(id)sender;
//
//@property (unsafe_unretained, nonatomic) IBOutlet UISlider *reverbWetDrySlider;
    @IBOutlet weak var reverbWetDrySlider: UISlider!
//@property (unsafe_unretained, nonatomic) IBOutlet UISlider *delayWetDrySlider;
    @IBOutlet weak var delayWetDrySlider: UISlider!
//
//- (IBAction)setReverbMix:(id)sender;
//- (IBAction)setDelayMix:(id)sender;
//
//@property (unsafe_unretained, nonatomic) IBOutlet UISlider *masterVolumeSlider;
    @IBOutlet weak var masterVolumeSlider: UISlider!
//- (IBAction)setMasterVolume:(id)sender;
//
//@property (unsafe_unretained, nonatomic) IBOutlet UIView *shadowView;
    @IBOutlet weak var shadowView: UIView!
//
//@property (getter=isRecording) BOOL recording;
    var recording: Bool = false
//@property (getter=isPlaying) BOOL playing;
    var playing: Bool = false
//@property BOOL canPlayback;
    var canPlayback: Bool = false
//@end
//
//
//#import "ViewController.h"
//#import "AudioEngine.h"
//#import "CAUITransportButton.h"
//
//@interface ViewController () <AudioEngineDelegate>
//
//@end
//
//#define kRoundedCornerRadius    10
//
//
//@implementation ViewController
//
//- (void)viewDidLoad
//{
    override func viewDidLoad() {
//    [super viewDidLoad];
        super.viewDidLoad()
//
//    engine = [[AudioEngine alloc] init];
        engine = AudioEngine()
//    engine.delegate = self;
        engine.delegate = self
//
//    [self updateUIElements];
        self.updateUIElements()
//}
    }
//
//- (void)updateUIElements
//{
    private func updateUIElements() {
//    // update UI
//    _marimbaVolumeSlider.value   = engine.marimbaPlayerVolume;
        marimbaVolumeSlider.value   = engine.marimbaPlayerVolume
//    _marimbaPanSlider.value      = engine.marimbaPlayerPan;
        marimbaPanSlider.value      = engine.marimbaPlayerPan
//
//    _drumsVolumeSlider.value    = engine.drumPlayerVolume;
        drumsVolumeSlider.value    = engine.drumPlayerVolume
//    _drumsPanSlider.value       = engine.drumPlayerPan;
        drumsPanSlider.value       = engine.drumPlayerPan
//
//    _delayWetDrySlider.value    = engine.delayWetDryMix;
        delayWetDrySlider.value    = engine.delayWetDryMix
//    _reverbWetDrySlider.value = engine.reverbWetDryMix;
        reverbWetDrySlider.value = engine.reverbWetDryMix
//
//    _masterVolumeSlider.value   = engine.outputVolume;
        masterVolumeSlider.value   = engine.outputVolume
//
//    _marimbaPlayButton.layer.cornerRadius = 5;
        marimbaPlayButton.layer.cornerRadius = 5
//    _drumsPlayButton.layer.cornerRadius = 5;
        drumsPlayButton.layer.cornerRadius = 5
//
//    [self styleButton: _marimbaPlayButton isPlaying: engine.marimbaPlayerIsPlaying];
        self.styleButton(marimbaPlayButton, isPlaying: engine.marimbaPlayerIsPlaying)
//    [self styleButton: _drumsPlayButton isPlaying: engine.drumPlayerIsPlaying];
        self.styleButton(drumsPlayButton, isPlaying: engine.marimbaPlayerIsPlaying)
//
//    _shadowView.layer.shadowColor = [UIColor blackColor].CGColor;
        shadowView.layer.shadowColor = UIColor.blackColor().CGColor
//    _shadowView.layer.shadowRadius = 10.0f;
        shadowView.layer.shadowRadius = 10.0
//    _shadowView.layer.shadowOffset = CGSizeMake(0.0f, 5.0f);
        shadowView.layer.shadowOffset = CGSizeMake(0.0, 5.0)
//    _shadowView.layer.shadowOpacity = 0.5f;
        shadowView.layer.shadowOpacity = 0.5
//
//    _rewindButton.drawingStyle = rewindButtonStyle;
        rewindButton.drawingStyle = .rewindButtonStyle
//    _rewindButton.fillColor = [UIColor whiteColor].CGColor;
        rewindButton.fillColor = UIColor.whiteColor().CGColor
//    _rewindButton.enabled = NO;
        rewindButton.enabled = false
//    _rewindButton.alpha = _rewindButton.enabled ? 1 : .25;
        rewindButton.alpha = rewindButton.enabled ? 1 : 0.25
//
//    _playButton.drawingStyle = playButtonStyle;
        playButton.drawingStyle = .playButtonStyle
//    _playButton.fillColor = [UIColor whiteColor].CGColor;
        playButton.fillColor = UIColor.whiteColor().CGColor
//    _playButton.enabled = NO;
        playButton.enabled = false
//    _playButton.alpha = _playButton.enabled ? 1 : .25;
        playButton.alpha = playButton.enabled ? 1 : 0.25
//
//    _recordButton.drawingStyle = recordButtonStyle;
        recordButton.drawingStyle = .recordButtonStyle
//    _recordButton.fillColor = [UIColor redColor].CGColor;
        recordButton.fillColor = UIColor.redColor().CGColor
//
//    [self updateButtonStates];
        self.updateButtonStates()
//}
    }
//
//- (void)didReceiveMemoryWarning {
    override func didReceiveMemoryWarning() {
//    [super didReceiveMemoryWarning];
        super.didReceiveMemoryWarning()
//    // Dispose of any resources that can be recreated.
//}
    }
//
//- (void)styleButton:(UIButton *)button isPlaying:(BOOL)isPlaying {
    private func styleButton(button: UIButton, isPlaying: Bool) {
//    if (isPlaying) {
        if isPlaying {
//        [button setTitle: @"Stop" forState: UIControlStateNormal];
            button.setTitle("Stop", forState: .Normal)
//        button.layer.backgroundColor = button.tintColor.CGColor;
            button.layer.backgroundColor = button.tintColor!.CGColor
//        button.layer.borderWidth = 0;
            button.layer.borderWidth = 0
//        [button setTitleColor: [UIColor whiteColor] forState: UIControlStateNormal];
            button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
//    } else {
        } else {
//        [button setTitle: @"Play" forState: UIControlStateNormal];
            button.setTitle("Play", forState: .Normal)
//        button.layer.backgroundColor = [UIColor clearColor].CGColor;
            button.layer.backgroundColor = UIColor.clearColor().CGColor
//        button.layer.borderWidth = 2;
            button.layer.borderWidth = 2
//        [button setTitleColor: button.tintColor forState: UIControlStateNormal];
            button.setTitleColor(button.tintColor, forState: .Normal)
//        button.layer.borderColor = button.tintColor.CGColor;
            button.layer.borderColor = button.tintColor!.CGColor
//    }
        }
//}
    }
//
//- (void)engineConfigurationHasChanged
//{
    func engineConfigurationHasChanged() {
//    [self updateUIElements];
        self.updateUIElements()
//}
    }
//
//- (IBAction)togglePlayMarimba:(id)sender {
    @IBAction func togglePlayMarimba(AnyObject) {
//    [engine toggleMarimba];
        engine.toggleMarimba()
//
//    [self styleButton: _marimbaPlayButton isPlaying: engine.marimbaPlayerIsPlaying];
        self.styleButton(marimbaPlayButton, isPlaying: engine.marimbaPlayerIsPlaying)
//}
    }
//
//- (IBAction)setMarimbaVolume:(id)sender {
    @IBAction func setMarimbaVolume(sender: UISlider) {
//    engine.marimbaPlayerVolume = ((UISlider *)sender).value;
        engine.marimbaPlayerVolume = sender.value
//}
    }
//
//- (IBAction)setMarimbaPan:(id)sender {
    @IBAction func setMarimbaPan(sender: UISlider) {
//    engine.marimbaPlayerPan = ((UISlider *)sender).value;
        engine.marimbaPlayerPan = sender.value
//}
    }
//
//- (IBAction)togglePlayDrums:(id)sender {
    @IBAction func togglePlayDrums(AnyObject) {
//    [engine toggleDrums];
        engine.toggleDrums()
//
//    [self styleButton: _drumsPlayButton isPlaying: engine.drumPlayerIsPlaying];
        self.styleButton(drumsPlayButton, isPlaying: engine.drumPlayerIsPlaying)
//}
    }
//
//- (IBAction)setDrumVolume:(id)sender {
    @IBAction func setDrumVolume(sender: UISlider) {
//    engine.drumPlayerVolume = ((UISlider *)sender).value;
        engine.drumPlayerVolume = sender.value
//}
    }
//
//- (IBAction)setDrumPan:(id)sender {
    @IBAction func setDrumPan(sender: UISlider) {
//    engine.drumPlayerPan = ((UISlider *)sender).value;
        engine.drumPlayerPan = sender.value
//
//}
    }
//
//-(void) updateButtonStates {
    private func updateButtonStates() {
//    _recordButton.drawingStyle = _recording ? recordEnabledButtonStyle : recordButtonStyle;
        recordButton.drawingStyle = recording ? .recordEnabledButtonStyle : .recordButtonStyle
//
//    _playButton.enabled = _rewindButton.enabled = _canPlayback;
        playButton.enabled = canPlayback
        rewindButton.enabled = canPlayback
//    _playButton.alpha = _playButton.enabled ? 1 : .25;
        playButton.alpha = playButton.enabled ? 1 : 0.25
//    _rewindButton.alpha = _rewindButton.enabled ? 1 : .25;
        rewindButton.alpha = rewindButton.enabled ? 1 : 0.25
//
//    _playButton.drawingStyle = _playing ? pauseButtonStyle : playButtonStyle;
        playButton.drawingStyle = playing ? .pauseButtonStyle : .playButtonStyle
//}
    }
//
//- (void)mixerOutputFilePlayerHasStopped
//{
    func mixerOutputFilePlayerHasStopped() {
//    _playing = NO;
        playing = false
//    [self updateButtonStates];
        self.updateButtonStates()
//}
    }
//
//- (IBAction)rewindAction:(id)sender {
    @IBAction func rewindAction(AnyObject) {
//    // rewind stops playback and recording
//    _recording = NO;
        recording = false
//    _playing = NO;
        playing = false
//
//    [engine stopPlayingRecordedFile];
        engine.stopPlayingRecordedFile()
//    [engine stopRecordingMixerOutput];
        engine.stopRecordingMixerOutput()
//    [self updateButtonStates];
        self.updateButtonStates()
//}
    }
//
//- (IBAction)playPauseAction:(id)sender {
    @IBAction func playPauseAction(AnyObject) {
//    // playing/pausing stops recording toggles playback state
//    _recording = NO;
        recording = false
//    _playing = !_playing;
        playing = !playing
//
//    [engine stopRecordingMixerOutput];
        engine.stopRecordingMixerOutput()
//    if (_playing) [engine playRecordedFile];
        if playing {
            engine.playRecordedFile()
        } else {
//    else [engine pausePlayingRecordedFile];
            engine.pausePlayingRecordedFile()
        }
//    [self updateButtonStates];
        self.updateButtonStates()
//}
    }
//
//- (IBAction)recordAction:(id)sender {
    @IBAction func recordAction(AnyObject) {
//    // recording stops playback and recording if we are already recording
//    _playing = NO;
        playing = false
//    _recording = !_recording;
        recording = !recording
//    _canPlayback = YES;
        canPlayback = true
//
//    [engine stopPlayingRecordedFile];
        engine.stopPlayingRecordedFile()
//    if (_recording) [engine startRecordingMixerOutput];
        if recording {
            engine.startRecordingMixerOutput()
        } else {
//    else [engine stopRecordingMixerOutput];
            engine.stopRecordingMixerOutput()
        }
//    [self updateButtonStates];
        self.updateButtonStates()
//}
    }
//
//- (IBAction)setReverbMix:(id)sender {
    @IBAction func setReverbMix(sender: UISlider) {
//    engine.reverbWetDryMix = ((UISlider *)sender).value;
        engine.reverbWetDryMix = sender.value
//}
    }
//
//- (IBAction)setDelayMix:(id)sender {
    @IBAction func setDelayMix(sender: UISlider) {
//    engine.delayWetDryMix = ((UISlider *)sender).value;
        engine.delayWetDryMix = sender.value
//}
    }
//
//- (IBAction)setMasterVolume:(id)sender {
    @IBAction func setMasterVolume(sender: UISlider) {
//    engine.outputVolume = ((UISlider *)sender).value;
        engine.outputVolume = sender.value
//}
    }
//@end
}