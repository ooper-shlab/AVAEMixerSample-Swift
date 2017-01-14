//
//  CAAVParameterView.swift
//  AVAEMixerSample
//
//  Translated by OOPer in cooperation with shlab.jp, on 2016/1/21.
//
//
/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information

    Abstract:
    This subclass of UIView holds the various UIElemets for interfacing with the AudioEngine. It also implements a gesture recognizer to dismiss the view
*/

import UIKit

@objc(CAAVParameterView)
class CAAVParameterView: UIView {
    
    var presentedController: UIViewController?
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    - (void)drawRect:(CGRect)rect {
    // Drawing code
    }
    */
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(CAAVParameterView.swipeRecognizer(_:)))
        swipe.direction = UISwipeGestureRecognizerDirection.down
        self.addGestureRecognizer(swipe)
        
    }
    
    //swipe down to dismiss the controller
    @objc func swipeRecognizer(_ sender: UISwipeGestureRecognizer) {
        if self.presentedController != nil {
            self.presentedController?.dismiss(animated: true, completion: nil)
            self.presentedController = nil
        }
    }
    
}
