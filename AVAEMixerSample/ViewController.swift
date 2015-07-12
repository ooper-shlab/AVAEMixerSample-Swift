//
//  ViewController.swift
//  AVAEMixerSample
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/2/28.
//
//
/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information

    Abstract:
    View Controller class that drives the UI
*/

import UIKit

@objc(ViewController)
class ViewController: UIViewController, AudioEngineDelegate {
    private var engine: AudioEngine!
    
    @IBOutlet weak var marimbaPlayButton: UIButton!
    @IBOutlet weak var marimbaVolumeSlider: UISlider!
    @IBOutlet weak var marimbaPanSlider: UISlider!
    
    @IBOutlet weak var drumsPlayButton: UIButton!
    @IBOutlet weak var drumsVolumeSlider: UISlider!
    @IBOutlet weak var drumsPanSlider: UISlider!
    
    @IBOutlet weak var rewindButton: CAUITransportButton!
    @IBOutlet weak var playButton: CAUITransportButton!
    @IBOutlet weak var recordButton: CAUITransportButton!
    
    @IBOutlet weak var reverbWetDrySlider: UISlider!
    @IBOutlet weak var delayWetDrySlider: UISlider!
    
    @IBOutlet weak var masterVolumeSlider: UISlider!
    
    @IBOutlet weak var shadowView: UIView!
    
    var recording: Bool = false
    var playing: Bool = false
    var canPlayback: Bool = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        engine = AudioEngine()
        engine.delegate = self
        
        self.updateUIElements()
    }
    
    private func updateUIElements() {
        // update UI
        marimbaVolumeSlider.value   = engine.marimbaPlayerVolume
        marimbaPanSlider.value      = engine.marimbaPlayerPan
        
        drumsVolumeSlider.value    = engine.drumPlayerVolume
        drumsPanSlider.value       = engine.drumPlayerPan
        
        delayWetDrySlider.value    = engine.delayWetDryMix
        reverbWetDrySlider.value = engine.reverbWetDryMix
        
        masterVolumeSlider.value   = engine.outputVolume
        
        marimbaPlayButton.layer.cornerRadius = 5
        drumsPlayButton.layer.cornerRadius = 5
        
        self.styleButton(marimbaPlayButton, isPlaying: engine.marimbaPlayerIsPlaying)
        self.styleButton(drumsPlayButton, isPlaying: engine.marimbaPlayerIsPlaying)
        
        shadowView.layer.shadowColor = UIColor.blackColor().CGColor
        shadowView.layer.shadowRadius = 10.0
        shadowView.layer.shadowOffset = CGSizeMake(0.0, 5.0)
        shadowView.layer.shadowOpacity = 0.5
        
        rewindButton.drawingStyle = .rewindButtonStyle
        rewindButton.fillColor = UIColor.whiteColor().CGColor
        rewindButton.enabled = false
        rewindButton.alpha = rewindButton.enabled ? 1 : 0.25
        
        playButton.drawingStyle = .playButtonStyle
        playButton.fillColor = UIColor.whiteColor().CGColor
        playButton.enabled = false
        playButton.alpha = playButton.enabled ? 1 : 0.25
        
        recordButton.drawingStyle = .recordButtonStyle
        recordButton.fillColor = UIColor.redColor().CGColor
        
        self.updateButtonStates()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func styleButton(button: UIButton, isPlaying: Bool) {
        if isPlaying {
            button.setTitle("Stop", forState: .Normal)
            button.layer.backgroundColor = button.tintColor!.CGColor
            button.layer.borderWidth = 0
            button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        } else {
            button.setTitle("Play", forState: .Normal)
            button.layer.backgroundColor = UIColor.clearColor().CGColor
            button.layer.borderWidth = 2
            button.setTitleColor(button.tintColor, forState: .Normal)
            button.layer.borderColor = button.tintColor!.CGColor
        }
    }
    
    func engineConfigurationHasChanged() {
        self.updateUIElements()
    }
    
    func engineWasInterrupted() {
        playing = false
        recording = false
        self.updateUIElements()
    }
    
    @IBAction func togglePlayMarimba(_: AnyObject) {
        engine.toggleMarimba()
        
        self.styleButton(marimbaPlayButton, isPlaying: engine.marimbaPlayerIsPlaying)
    }
    
    @IBAction func setMarimbaVolume(sender: UISlider) {
        engine.marimbaPlayerVolume = sender.value
    }
    
    @IBAction func setMarimbaPan(sender: UISlider) {
        engine.marimbaPlayerPan = sender.value
    }
    
    @IBAction func togglePlayDrums(_: AnyObject) {
        engine.toggleDrums()
        
        self.styleButton(drumsPlayButton, isPlaying: engine.drumPlayerIsPlaying)
    }
    
    @IBAction func setDrumVolume(sender: UISlider) {
        engine.drumPlayerVolume = sender.value
    }
    
    @IBAction func setDrumPan(sender: UISlider) {
        engine.drumPlayerPan = sender.value
        
    }
    
    private func updateButtonStates() {
        recordButton.drawingStyle = recording ? .recordEnabledButtonStyle : .recordButtonStyle
        
        playButton.enabled = canPlayback
        rewindButton.enabled = canPlayback
        playButton.alpha = playButton.enabled ? 1 : 0.25
        rewindButton.alpha = rewindButton.enabled ? 1 : 0.25
        
        playButton.drawingStyle = playing ? .pauseButtonStyle : .playButtonStyle
    }
    
    func mixerOutputFilePlayerHasStopped() {
        playing = false
        self.updateButtonStates()
    }
    
    @IBAction func rewindAction(_: AnyObject) {
        // rewind stops playback and recording
        recording = false
        playing = false
        
        engine.stopPlayingRecordedFile()
        engine.stopRecordingMixerOutput()
        self.updateButtonStates()
    }
    
    @IBAction func playPauseAction(_: AnyObject) {
        // playing/pausing stops recording toggles playback state
        recording = false
        playing = !playing
        
        engine.stopRecordingMixerOutput()
        if playing {
            engine.playRecordedFile()
        } else {
            engine.pausePlayingRecordedFile()
        }
        self.updateButtonStates()
    }
    
    @IBAction func recordAction(_: AnyObject) {
        // recording stops playback and recording if we are already recording
        playing = false
        recording = !recording
        canPlayback = true
        
        engine.stopPlayingRecordedFile()
        if recording {
            engine.startRecordingMixerOutput()
        } else {
            engine.stopRecordingMixerOutput()
        }
        self.updateButtonStates()
    }
    
    @IBAction func setReverbMix(sender: UISlider) {
        engine.reverbWetDryMix = sender.value
    }
    
    @IBAction func setDelayMix(sender: UISlider) {
        engine.delayWetDryMix = sender.value
    }
    
    @IBAction func setMasterVolume(sender: UISlider) {
        engine.outputVolume = sender.value
    }
}