//
//  SequencerViewController.swift
//  AVAEMixerSample
//
//  Translated by OOPer in cooperation with shlab.jp, on 2016/1/30.
//
//
/*
    Copyright (C) 2017 Apple Inc. All Rights Reserved.
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
    
    private var _sequencerPositionSliderUpdateTimer: DispatchSourceTimer?
    
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
        self.sequencerPositionSlider.isContinuous = false
        self.sequencerPlaybackRateSlider.value = self.audioEngine?.sequencerPlaybackRate ?? 0.0
        self.sequencerPlayButton.layer.cornerRadius = 5
        self.styleButton(sequencerPlayButton, isPlaying: self.audioEngine?.sequencerIsPlaying ?? false)
    }
    
    private func startTimer() {
        _sequencerPositionSliderUpdateTimer = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags(rawValue: 0), queue: DispatchQueue.main)
        if let sequencerPositionSliderUpdateTimer = _sequencerPositionSliderUpdateTimer {
            sequencerPositionSliderUpdateTimer.scheduleRepeating(deadline: .now(), interval: 0.1 * Double(NSEC_PER_SEC), leeway: .nanoseconds(0))
            sequencerPositionSliderUpdateTimer.setEventHandler {
                self.sequencerPositionSlider.value = Float(self.audioEngine?.sequencerCurrentPosition ?? 0.0)
            }
            sequencerPositionSliderUpdateTimer.resume()
        }
    }
    
    private func stopTimer() {
        if let sequencerPositionSliderUpdateTimer = _sequencerPositionSliderUpdateTimer {
            sequencerPositionSliderUpdateTimer.cancel()
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
    
    @IBAction func sequencerPositionSliderValueChanged(_ sender: UISlider) {
        if self.audioEngine?.sequencerIsPlaying ?? false {
            self.audioEngine?.sequencerCurrentPosition = Double(sender.value)
            self.startTimer()
        }
    }
    
    @IBAction func setSequencerPlaybackRate(_ sender: UISlider) {
        self.audioEngine?.sequencerPlaybackRate = sender.value
    }
    
}
