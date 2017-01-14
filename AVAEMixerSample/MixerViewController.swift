//
//  MixerViewController.swift
//  AVAEMixerSample
//
//  Translated by OOPer in cooperation with shlab.jp, on 2016/1/30.
//
//
/*
    Copyright (C) 2017 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information

    Abstract:
    The MixerViewController class provides specific UI Elements to interact with the AVAudioEngine mainMixerNode object.

                    CAUITransportButton *recordButton;          Installs a tap on the output bus for the mixer and records to a file
                    UISlider            *masterVolumeSlider;    Sets the output volume of the mixer
*/

import UIKit

@objc(MixerViewController)
class MixerViewController: AudioViewController {
    
    @IBOutlet private weak var recordButton: CAUITransportButton!
    @IBOutlet private weak var masterVolumeSlider: UISlider!
    
    private var recording: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func updateUIElements() {
        self.masterVolumeSlider.value   = self.audioEngine?.outputVolume ?? 0.0
        self.recordButton.drawingStyle = .recordButtonStyle
        self.recordButton.fillColor = UIColor(red: 255/255.0, green: 102/255.0, blue: 102/255.0, alpha: 1).cgColor
    }
    
    @IBAction func setMasterVolume(_ sender: UISlider) {
        self.audioEngine?.outputVolume = sender.value
    }
    
    @IBAction func recordAction(_ sender: UISlider) {
        self.recording = !self.recording
        
        if self.recording {
            self.audioEngine?.startRecordingMixerOutput()
        } else {
            self.audioEngine?.stopRecordingMixerOutput()
        }
        
        self.recordButton.drawingStyle = self.recording ? .recordEnabledButtonStyle : .recordButtonStyle
    }
    
    
}
