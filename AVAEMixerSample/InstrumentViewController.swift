//
//  InstrumentViewController.swift
//  AVAEMixerSample
//
//  Translated by OOPer in cooperation with shlab.jp, on 2016/1/30.
//
//
/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information

    Abstract:
    The InstrumentViewController class provides specific UI Elements to interact with the AVAudioSequencer object. The sequencer is not directly part of AVAudioEngine.

                        UISlider *samplerDirectVolumeSlider;    Sets the volume of the instrument using AVAudioMixingDestination
                        UISlider *reverbVolumeSlider;           Sets the volume of the instrument using AVAudioMixingDestination
*/

import UIKit

@objc(InstrumentViewController)
class InstrumentViewController: AudioViewController {
    
    @IBOutlet weak var directVolumeSlider: UISlider!
    @IBOutlet weak var effectVolumeSlider: UISlider!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func updateUIElements() {
        self.directVolumeSlider.value = self.audioEngine?.samplerDirectVolume ?? 0.0
        self.effectVolumeSlider.value = self.audioEngine?.samplerEffectVolume ?? 0.0
    }
    
    @IBAction func setSamplerDirectVolume(sender: UISlider) {
        self.audioEngine?.samplerDirectVolume = sender.value
    }
    
    @IBAction func setEffectVolime(sender: UISlider) {
        self.audioEngine?.samplerEffectVolume = sender.value
    }
    
    
}