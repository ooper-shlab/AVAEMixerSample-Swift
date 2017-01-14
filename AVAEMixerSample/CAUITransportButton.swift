//
//  CAUITransportButton.swift
//  AVAEMixerSample
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/2/24.
//
//
/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:
 This UIButton subclass programatically draws a transport button with a particular drawing style.
         It features a fill color that can be an accent color.
         If the button has the recordEnabledButtonStyle, it pulses on and off.

         These buttons resize themselves dynamically at runtime so that their bounds is a minimum of 44 x 44 pts
         in order to make them easy to press.
         The button image will draw at the original size specified in the storyboard
 */

import UIKit

@objc enum CAUITransportButtonStyle: Int {
    case rewindButtonStyle = 1
    case pauseButtonStyle
    case playButtonStyle
    case recordButtonStyle
    case recordEnabledButtonStyle
    case stopButtonStyle
}

@objc(CAUITransportButton)
class CAUITransportButton: UIButton {
    var _drawingStyle: CAUITransportButtonStyle = .rewindButtonStyle
    var _fillColor: CGColor?
    
    var imageRect: CGRect = CGRect()
    
    private final let kMinimumButtonSize: CGFloat = 24
    // #define drawDoubleArrows 1		// uncomment to activate a double arrow drawing style instead of a bar with a single triangle
    
    //MARK: - Intialization
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        imageRect = self.bounds
        let widthDelta = kMinimumButtonSize - self.bounds.size.width
        let heightDelta = kMinimumButtonSize - self.bounds.size.height
        
        if widthDelta > 0 || heightDelta > 0 {
            // update the frame
            let bounds = CGRect(x: 0, y: 0, width: widthDelta > 0 ? kMinimumButtonSize : imageRect.size.width, height: heightDelta > 0 ? kMinimumButtonSize : imageRect.size.height)
            let frame  = CGRect(x: widthDelta > 0 ? round(self.frame.origin.x - (widthDelta / 2)) : self.frame.origin.x,
                y: heightDelta > 0 ? round(self.frame.origin.y - (heightDelta / 2)) : self.frame.origin.y,
                width: bounds.size.width, height: bounds.size.height)
            
            self.frame = frame
            self.bounds = bounds
            
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        imageRect = self.bounds
        let widthDelta = kMinimumButtonSize - frame.size.width
        let heightDelta = kMinimumButtonSize - frame.size.height
        
        if widthDelta > 0 || heightDelta > 0 {
            // update the frame
            let bounds = CGRect(x: 0, y: 0, width: widthDelta > 0 ? kMinimumButtonSize : imageRect.size.width, height: heightDelta > 0 ? kMinimumButtonSize : imageRect.size.height)
            let theFrame  = CGRect(x: widthDelta > 0 ? round(self.frame.origin.x - (widthDelta / 2)) : self.frame.origin.x,
                y: heightDelta > 0 ? round(self.frame.origin.y - (heightDelta / 2)) : self.frame.origin.y,
                width: bounds.size.width, height: bounds.size.height)
            
            self.frame  = theFrame
            self.bounds = bounds
        }
    }
    
    override class var layerClass : AnyClass {
        return CAShapeLayer.self
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if event!.type == .touches {
            let tempColor = UIColor(cgColor: (self.layer as! CAShapeLayer).fillColor!)
            (self.layer as! CAShapeLayer).fillColor = tempColor.withAlphaComponent(0.5).cgColor
        }
        
        super.touchesBegan(touches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if event!.type == .touches {
            (self.layer as! CAShapeLayer).fillColor = fillColor
        }
        
        super.touchesEnded(touches, with: event)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if event!.type == .touches {
            (self.layer as! CAShapeLayer).fillColor = fillColor
        }
        
        super.touchesEnded(touches, with: event)
    }
    
    private func toRadians(_ degrees: CGFloat) -> CGFloat {
        return (degrees * CGFloat(M_PI))/180.0
    }
    
    //MARK: - Property methods
    /* We don't do any actual drawing in this class. This method sets the properties of the layer object based on the type of button we are drawing */
    var drawingStyle: CAUITransportButtonStyle {
        set(style) {
            if _drawingStyle != style {
                _drawingStyle = style
                let path = self.newPathRefForStyle(style)
                (self.layer as! CAShapeLayer).path = path
                
                self.backgroundColor = UIColor.clear
                
                if style == .recordEnabledButtonStyle {
                    UIView.animate(withDuration: 1, delay: 0, options: .curveLinear,
                        animations: {
                            (self.layer as! CAShapeLayer).strokeColor = self.fillColor
                            (self.layer as! CAShapeLayer).fillColor = self.fillColor
                            (self.layer as! CAShapeLayer).lineWidth = 0.5
                            self.flash()
                        }, completion: nil)
                    
                } else if style == .recordButtonStyle {
                    (self.layer as! CAShapeLayer).removeAllAnimations()
                    UIView.animate(withDuration: 1, delay: 0, options: .curveLinear,
                        animations: {
                            (self.layer as! CAShapeLayer).strokeColor = UIColor.clear.cgColor
                            (self.layer as! CAShapeLayer).fillColor = self.fillColor
                            (self.layer as! CAShapeLayer).lineWidth = 0
                        }, completion: nil)
                }
                self.setNeedsDisplay()
            }
        }
        
        get {
            return _drawingStyle
        }
    }
    
    var fillColor: CGColor? {
        set(color) {
            _fillColor = color
            (self.layer as! CAShapeLayer).fillColor = color
        }
        
        get {
            return _fillColor
        }
    }
    
    //MARK: - Drawing methods
    private func flash() {
        let color = UIColor(cgColor: fillColor!).withAlphaComponent(0.2)
        CATransaction.begin()
        let strokeAnim = CABasicAnimation(keyPath: "fillColor")
        strokeAnim.fromValue = (self.layer as! CAShapeLayer).fillColor
        strokeAnim.toValue = color.cgColor
        strokeAnim.duration = 2.0
        strokeAnim.repeatCount = 0
        strokeAnim.autoreverses = true
        CATransaction.setCompletionBlock {
            if self.drawingStyle == .recordEnabledButtonStyle {
                self.flash()
            }
        }
        (self.layer as! CAShapeLayer).add(strokeAnim, forKey: "animateStrokeColor")
        CATransaction.commit()
    }
    
    private func newPathRefForStyle(_ style: CAUITransportButtonStyle) -> CGPath? {
        var path: CGPath? = nil
        var size = min(imageRect.size.width, imageRect.size.height)
        
        switch style {
        case .rewindButtonStyle:
            let tempPath = CGMutablePath()
            #if drawDoubleArrows
                var height = size * 0.613
                let width  = size
                let radius = (size * 0.0631)/2
            #else
                var height = size * 0.857
                let width  = size * 0.699
                var radius = (size * 0.026)/2
            #endif
            let yOffset = round((imageRect.size.height - height)/2)
            
            height = round(height)
            
            #if drawDoubleArrows
                // first arrow
                tempPath.addArc(center: CGPoint(x: radius, y: yOffset + height/2), radius: radius, startAngle: toRadians(120), endAngle: toRadians(240), clockwise: false)
                tempPath.addArc(center: CGPoint(x: 0.5 * width - radius, y: yOffset + radius), radius: radius, startAngle: toRadians(240), endAngle: toRadians(0), clockwise: false)
                tempPath.addArc(center: CGPoint(x: 0.5 * width - radius, y: yOffset + height - radius), radius: radius, startAngle: toRadians(0), endAngle: toRadians(120), clockwise: false)
                tempPath.closeSubpath()
                
                // second arrow
                tempPath.move(to: CGPoint(x: 0.5*size, y: yOffset + height/2))
                tempPath.addArc(center: CGPoint(x: 0.5*size + radius, y: yOffset + height/2), radius: radius, startAngle: toRadians(180), endAngle: toRadians(240), clockwise: false)
                tempPath.addArc(center: CGPoint(x: width - radius, y: yOffset + radius), radius: radius, startAngle: toRadians(240), endAngle: toRadians(0), clockwise: false)
                tempPath.addArc(center: CGPoint(x: width - radius, y: yOffset + height - radius), radius: radius, startAngle: toRadians(0), endAngle: toRadians(120), clockwise: false)
                tempPath.addArc(center: CGPoint(x: 0.5*size + radius, y: yOffset + height/2), radius: radius, startAngle: toRadians(120), endAngle: toRadians(180), clockwise: false)
            #else
                var xOffset = 0.062 * size
                tempPath.addRoundedRect(in: CGRect(x: 0, y: yOffset, width: xOffset, height: height), cornerWidth: radius, cornerHeight: radius)
                
                radius = (size * 0.0631)/2
                xOffset += 0.006 * size
                
                tempPath.addArc(center: CGPoint(x: xOffset + radius, y: yOffset + height/2), radius: radius, startAngle: toRadians(120), endAngle: toRadians(240), clockwise: false)
                tempPath.addArc(center: CGPoint(x: xOffset + width - radius, y: yOffset + radius), radius: radius, startAngle: toRadians(240), endAngle: toRadians(0), clockwise: false)
                tempPath.addArc(center: CGPoint(x: xOffset + width - radius, y: yOffset + height - radius), radius: radius, startAngle: toRadians(0), endAngle: toRadians(120), clockwise: false)
            #endif
            tempPath.closeSubpath()
            
            path = tempPath
        case .pauseButtonStyle:
            let tempPath = CGMutablePath()
            var height = size * 0.857
            let width  = size * 0.7452
            let barWidth = size * 0.2776
            let xOffset = round((imageRect.size.width - width)/2)
            let	yOffset = round((imageRect.size.height - height)/2)
            let radius = (size * 0.0397)/2
            
            height = round(height)
            
            tempPath.addRoundedRect(in: CGRect(x: xOffset, y: yOffset, width: barWidth, height: height), cornerWidth: radius, cornerHeight: radius)
            tempPath.addRoundedRect(in: CGRect(x: round(imageRect.size.width - xOffset - barWidth), y: yOffset, width: barWidth, height: height), cornerWidth: radius, cornerHeight: radius)
            
            path = tempPath
        case .playButtonStyle:
            let tempPath = CGMutablePath()
            var height = size * 0.857
            let width  = size * 0.6538
            let xOffset = round((imageRect.size.width - width)/2)
            let yOffset = round((imageRect.size.height - height)/2)
            let radius  = (size * 0.0631)/2
            
            height = round(height)
            
            tempPath.addArc(center: CGPoint(x: xOffset + radius, y: yOffset + radius), radius: radius, startAngle: toRadians(180), endAngle: toRadians(300), clockwise: false)
            tempPath.addArc(center: CGPoint(x: xOffset + width - radius, y: yOffset + height/2), radius: radius, startAngle: toRadians(300), endAngle: toRadians(60), clockwise: false)
            tempPath.addArc(center: CGPoint(x: xOffset + radius, y: yOffset + height - radius), radius: radius, startAngle: toRadians(60), endAngle: toRadians(180), clockwise: false)
            tempPath.closeSubpath()
            path = tempPath
        case .recordButtonStyle, .recordEnabledButtonStyle:
            size *= 0.7825
            let elipseRect = CGRect(x: (imageRect.size.width - size)/2, y: (imageRect.size.height - size)/2, width: size, height: size)
            
            path = CGPath(ellipseIn: elipseRect, transform: nil)
        case .stopButtonStyle:
            let tempPath = CGMutablePath()
            var height = size * 0.857
            let offset = round((imageRect.size.width - height)/2)
            let radius = (size * 0.0397)/2
            
            height = round(height)
            
            tempPath.addRoundedRect(in: CGRect(x: offset, y: offset, width: height, height: height), cornerWidth: radius, cornerHeight: radius)
            
            path = tempPath
        }
        return path
    }
    
}
