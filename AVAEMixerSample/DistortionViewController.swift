//
//  DistortionViewController.swift
//  AVAEMixerSample
//
//  Translated by OOPer in cooperation with shlab.jp, on 2016/1/30.
//
//
/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information

    Abstract:
    The DistortionViewController class provides specific UI Elements to interact with the AVAudioUnitDistortion object.

                    UISlider *distortionWetDrySlider;   Set the wet/dry mix of the current reverb preset
                    UIPickerView *distortionTypePicker; Select a preset for the unit
*/

import UIKit

@objc(DistortionViewController)
class DistortionViewController: AudioViewController {
    
    @IBOutlet weak var distortionWetDrySlider: UISlider!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func updateUIElements() {
        self.distortionWetDrySlider.value = self.audioEngine?.distortionWetDryMix ?? 0.0
    }
    
    @IBAction func setWetDryMix(_ sender: UISlider) {
        self.audioEngine?.distortionWetDryMix = sender.value
    }
    
}
