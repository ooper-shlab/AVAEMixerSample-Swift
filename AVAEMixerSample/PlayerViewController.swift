//
//  PlayerViewController.swift
//  AVAEMixerSample
//
//  Translated by OOPer in cooperation with shlab.jp, on 2016/1/30.
//
//
/*
    Copyright (C) 2017 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information

    Abstract:
    The PlayerViewController class provides specific UI Elements to interact with the PlayerNode.

                UISlider            *playerVolumeSlider;    Sets the volume on the player
                UISlider            *playerPanSlider;       Sets the pan on the player
                UIButton            *playerPlayButton;      Toggles the player state
                UISegmentedControl  *playerSegmentControl;  Provides a selection for different buffers/files
*/

import UIKit

@objc(PlayerViewController)
class PlayerViewController: AudioViewController {
    
    @IBOutlet weak var playerVolumeSlider: UISlider!
    @IBOutlet weak var playerPanSlider: UISlider!
    @IBOutlet weak var playerPlayButton: UIButton!
    @IBOutlet weak var playerSegmentControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.enableToggle(_:)), name: .RecordingCompleted, object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func toggleBuffer(_ sender: UISegmentedControl) {
        self.audioEngine?.toggleBuffer(sender.selectedSegmentIndex != 0)
    }
    
    @IBAction func togglePlay(_: Any) {
        self.audioEngine?.togglePlayer()
        self.styleButton(playerPlayButton, isPlaying: self.audioEngine?.playerIsPlaying ?? false)
    }
    
    @IBAction func setVolume(_ sender: UISlider) {
        self.audioEngine?.playerVolume = sender.value
    }
    
    @IBAction func setPan(_ sender: UISlider) {
        self.audioEngine?.playerPan = sender.value
    }
    
    @objc func enableToggle(_ notification: Notification) {
        self.playerSegmentControl.setEnabled(true, forSegmentAt: 1)
    }
    
    override func updateUIElements() {
        self.styleButton(playerPlayButton, isPlaying: self.audioEngine?.playerIsPlaying ?? false)
    }
    
    
}
