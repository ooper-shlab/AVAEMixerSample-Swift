//
//  CAAVAudioUnitView.swift
//  AVAEMixerSample
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/2/24.
//
//
/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information

    Abstract:
    This subclass of UIView adds rounded corners to the view
*/

import UIKit

private let kRoundedCornerRadius: CGFloat = 10

@objc(CAAVAudioUnitView)
class CAAVAudioUnitView: UIView {
    
    override func setNeedsLayout() {
        super.setNeedsLayout()
        
        let fillPath = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: UIRectCorner.AllCorners, cornerRadii: CGSizeMake(kRoundedCornerRadius, kRoundedCornerRadius))
        
        let pathLayer = CAShapeLayer()
        pathLayer.path = fillPath.CGPath
        pathLayer.frame = fillPath.bounds
        
        self.layer.mask = pathLayer
    }
    
}