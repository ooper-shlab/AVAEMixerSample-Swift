//
//  AudioEngineViewController.swift
//  AVAEMixerSample
//
//  Translated by OOPer in cooperation with shlab.jp, on 2016/1/30.
//
//
/*
    Copyright (C) 2017 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information

    Abstract:
    AudioEngineViewController hosts the AudioEngine UI as well as the UI for each individual node

                This controller is linked to a size-classes storyboard that supports both iPhone and iPad UI
 */

import UIKit

@objc(AudioEngineViewController)
class AudioEngineViewController: UIViewController, AudioEngineDelegate {
    
    
    private var audioEngine: AudioEngine?
    @IBOutlet private weak var shadowView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.setupUI()
        
    }
    
    private func setupUI() {
        //apply a drop shadow to the boxes
        self.shadowView.layer.shadowColor = UIColor.black.cgColor
        self.shadowView.layer.shadowRadius = 10.0
        self.shadowView.layer.shadowOffset = CGSize(width: 0.0, height: 5.0)
        self.shadowView.layer.shadowOpacity = 0.5
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //initialize
        if self.audioEngine == nil {
            self.audioEngine = AudioEngine()
            self.audioEngine!.delegate = self
        }
        
        //Pass the audio engine to all the audioviewcontrollers
        if let controller = segue.destination as? AudioViewController {
            controller.audioEngine = self.audioEngine
        }
        
    }
    
    
    //MARK: AudioEngineDelegate Methods
    func engineWasInterrupted() {
        //update the UI elements for all the audioviewcontrollers
        for case let controller as AudioViewController in self.childViewControllers {
            controller.updateUIElements()
        }
    }
    
    func engineConfigurationHasChanged() {
        //update the UI elements for all the audioviewcontrollers
        for case let controller as AudioViewController in self.childViewControllers {
            controller.updateUIElements()
        }
    }
    
    
}
