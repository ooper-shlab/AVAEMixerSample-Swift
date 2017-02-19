//
//  AudioViewController.swift
//  AVAEMixerSample
//
//  Translated by OOPer in cooperation with shlab.jp, on 2016/1/30.
//
//
/*
    Copyright (C) 2017 Apple Inc. All Rights Reserved.
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
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var parameterView: CAAVParameterView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //if the device is an iPad, add the view to the stackview and display it right away
        //else for iPhone, make the title bar selectable, and then present the view modally
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.stackView.addArrangedSubview(self.parameterView)
        } else {
            let titleViewTap = UITapGestureRecognizer(target: self, action: #selector(AudioViewController.showParameterView(_:)))
            self.titleView.addGestureRecognizer(titleViewTap)
            
            let swipe = UISwipeGestureRecognizer(target: self, action: #selector(swipeRecognizer))
            swipe.direction = .down
            self.parameterView.addGestureRecognizer(swipe)
        }
        
        self.updateUIElements()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // style play/stop button
    func styleButton(_ button: UIButton, isPlaying: Bool) {
        if isPlaying {
            button.setTitle("Stop", for: UIControlState())
        } else {
            button.setTitle("Play", for: UIControlState())
        }
    }
    
    //present parameter view
    @objc func showParameterView(_ recognizer: UITapGestureRecognizer) {
        
        if UIDevice.current.userInterfaceIdiom != .pad {
            let navigationController = UINavigationController()
            let controller = UIViewController()
            controller.view = self.parameterView
            navigationController.viewControllers = [controller]
            navigationController.navigationBar.isTranslucent = false
            navigationController.navigationBar.barTintColor = self.titleView.tintColor
            navigationController.navigationBar.topItem?.title = self.titleLabel.text
            UINavigationBar.appearance().tintColor = UIColor.black
            
            let dismissButton = UIBarButtonItem(title: "Dismiss",
                                                style: .plain,
                                                target: self,
                                                action: #selector(swipeRecognizer))
            navigationController.navigationBar.topItem?.rightBarButtonItem = dismissButton
            
            self.parameterView.presentedController = navigationController
            self.present(navigationController, animated: true, completion: nil)
        }
    }
    
    //swipe down to dismiss the controller
    @objc func swipeRecognizer(_ sender: UISwipeGestureRecognizer) {
        self.parameterView.presentedController?.dismiss(animated: true, completion: nil)
        self.parameterView.presentedController = nil
    }
    
    //subclasses can overide this method to update their UI elements when the engine is re/configured
    func updateUIElements() {
        
    }
    
    
    
}
