//
//  ReverbViewController.swift
//  AVAEMixerSample
//
//  Translated by OOPer in cooperation with shlab.jp, on 2016/1/30.
//
//
/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information

    Abstract:
    The ReverbViewController class provides specific UI Elements to interact with the AVAudioUnitReverb object.

                    UISlider *reverbWetDrySlider;   Set the wet/dry mix of the current reverb preset
                    UIPickerView *reverbTypePicker; Select a preset for the unit
*/

import UIKit

@objc(ReverbViewController)
class ReverbViewController: AudioViewController {
    
    @IBOutlet weak var reverbWetDrySlider: UISlider!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func updateUIElements() {
        self.reverbWetDrySlider.value = self.audioEngine?.reverbWetDryMix ?? 0.0
    }
    
    @IBAction func setWetDryMix(_ sender: UISlider) {
        self.audioEngine?.reverbWetDryMix = sender.value
    }
    
}
