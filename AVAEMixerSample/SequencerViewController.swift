//
//  SequencerViewController.swift
//  AVAEMixerSample
//
//  Translated by OOPer in cooperation with shlab.jp, on 2016/1/30.
//
//
/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information

    Abstract:
    The SequencerViewController class provides specific UI Elements to interact with the AVAudioSequencer object. The sequencer is not directly part of AVAudioEngine.

                    UISlider *sequencerPlaybackRateSlider;  Set the playback rate for the sequencer
                    UISlider *sequencerPositionSlider;      Set the current position for the current track
                    UIButton *sequencerPlayButton;          Toggle the state of the sequencer
*/

import UIKit

@objc(SequencerViewController)
class SequencerViewController: AudioViewController {
    
    private var _sequencerPositionSliderUpdateTimer: dispatch_source_t?
    
    @IBOutlet private weak var sequencerPlaybackRateSlider: UISlider!
    @IBOutlet private weak var sequencerPositionSlider: UISlider!
    @IBOutlet private weak var sequencerPlayButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func updateUIElements() {
        self.sequencerPositionSlider.value = 0
        self.sequencerPositionSlider.continuous = false
        self.sequencerPlaybackRateSlider.value = self.audioEngine?.sequencerPlaybackRate ?? 0.0
        self.sequencerPlayButton.layer.cornerRadius = 5
        self.styleButton(sequencerPlayButton, isPlaying: self.audioEngine?.sequencerIsPlaying ?? false)
    }
    
    private func startTimer() {
        _sequencerPositionSliderUpdateTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue())
        if let sequencerPositionSliderUpdateTimer = _sequencerPositionSliderUpdateTimer {
            dispatch_source_set_timer(sequencerPositionSliderUpdateTimer, DISPATCH_TIME_NOW, UInt64(0.1 * Double(NSEC_PER_SEC)), 0)
            dispatch_source_set_event_handler(sequencerPositionSliderUpdateTimer) {
                self.sequencerPositionSlider.value = Float(self.audioEngine?.sequencerCurrentPosition ?? 0.0)
            }
            dispatch_resume(sequencerPositionSliderUpdateTimer)
        }
    }
    
    private func stopTimer() {
        if let sequencerPositionSliderUpdateTimer = _sequencerPositionSliderUpdateTimer {
            dispatch_source_cancel(sequencerPositionSliderUpdateTimer)
            _sequencerPositionSliderUpdateTimer = nil
        }
    }
    
    @IBAction func togglePlaySequencer(_: AnyObject) {
        self.audioEngine?.toggleSequencer()
        
        self.styleButton(sequencerPlayButton, isPlaying: self.audioEngine?.sequencerIsPlaying ?? false)
        if self.audioEngine?.sequencerIsPlaying ?? false {
            self.startTimer()
        } else {
            self.stopTimer()
        }
    }
    @IBAction func sequencerPositionSliderTouchDown(_: AnyObject) {
        if self.audioEngine?.sequencerIsPlaying ?? false {
            self.stopTimer()
        }
    }
    
    @IBAction func sequencerPositionSliderValueChanged(sender: UISlider) {
        if self.audioEngine?.sequencerIsPlaying ?? false {
            self.audioEngine?.sequencerCurrentPosition = Double(sender.value)
            self.startTimer()
        }
    }
    
    @IBAction func setSequencerPlaybackRate(sender: UISlider) {
        self.audioEngine?.sequencerCurrentPosition = Double(sender.value)
    }
    
}