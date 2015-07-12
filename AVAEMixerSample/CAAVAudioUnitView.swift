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
    AVAudioUnitView
*/

import UIKit

private let kRoundedCornerRadius: CGFloat = 10

@objc(CAAVAudioUnitView)
class CAAVAudioUnitView: UIView {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        let fillPath = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: [.TopLeft, .TopRight], cornerRadii: CGSizeMake(kRoundedCornerRadius, kRoundedCornerRadius))

        let pathLayer = CAShapeLayer()
        pathLayer.path = fillPath.CGPath
        pathLayer.frame = fillPath.bounds

        self.layer.mask = pathLayer
    }

}