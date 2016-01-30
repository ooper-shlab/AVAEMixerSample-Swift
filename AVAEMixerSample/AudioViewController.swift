//
//  AudioViewController.swift
//  AVAEMixerSample
//
//  Translated by OOPer in cooperation with shlab.jp, on 2016/1/30.
//
//
/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information

    Abstract:
    This class represents a node/sequencer.
                    It contains -
                        A reference to the AudioEngine
                        Basic Views for displaying parameters. Subclasses can provide their own views for customization
 */

import UIKit

@objc(AudioViewController)
class AudioViewController: UIViewController {
    
    var audioEngine: AudioEngine?
    
    @IBOutlet weak var titleView: UIView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var parameterView: CAAVParameterView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //if the device is an iPad, add the view to the stackview and display it right away
        //else for iPhone, make the title bar selectable, and then present the view modally
        
        
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            self.stackView.addArrangedSubview(self.parameterView)
        } else {
            let titleViewTap = UITapGestureRecognizer(target: self, action: "showParameterView:")
            self.titleView.addGestureRecognizer(titleViewTap)
        }
        
        self.updateUIElements()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // style play/stop button
    func styleButton(button: UIButton, isPlaying: Bool) {
        if isPlaying {
            button.setTitle("Stop", forState: .Normal)
        } else {
            button.setTitle("Play", forState: .Normal)
        }
    }
    
    //present parameter view
    @objc func showParameterView(recognizer: UITapGestureRecognizer) {
        
        if UIDevice.currentDevice().userInterfaceIdiom != .Pad {
            let controller = UIViewController()
            controller.view = self.parameterView
            self.parameterView?.presentedController = controller
            self.presentViewController(controller, animated: true, completion: nil)
        }
    }
    
    //subclasses can overide this method to update their UI elements when the engine is re/configured
    func updateUIElements() {
        
    }
    
    
    
}