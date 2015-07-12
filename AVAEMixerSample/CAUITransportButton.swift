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

/* This UIButton subclass programatically draws a transport button with a particular drawing style.
It features a fill color that can be an accent color.
If the button has the recordEnabledButtonStyle, it pulses on and off.

These buttons resize themselves dynamically at runtime so that their bounds is a minimum of 44 x 44 pts
in order to make them easy to press.
The button image will draw at the original size specified in the storyboard
*/
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
            let bounds = CGRectMake(0, 0, widthDelta > 0 ? kMinimumButtonSize : imageRect.size.width, heightDelta > 0 ? kMinimumButtonSize : imageRect.size.height)
            let frame  = CGRectMake(widthDelta > 0 ? round(self.frame.origin.x - (widthDelta / 2)) : self.frame.origin.x,
                heightDelta > 0 ? round(self.frame.origin.y - (heightDelta / 2)) : self.frame.origin.y,
                bounds.size.width, bounds.size.height)
            
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
            let bounds = CGRectMake(0, 0, widthDelta > 0 ? kMinimumButtonSize : imageRect.size.width, heightDelta > 0 ? kMinimumButtonSize : imageRect.size.height)
            let theFrame  = CGRectMake(widthDelta > 0 ? round(self.frame.origin.x - (widthDelta / 2)) : self.frame.origin.x,
                heightDelta > 0 ? round(self.frame.origin.y - (heightDelta / 2)) : self.frame.origin.y,
                bounds.size.width, bounds.size.height)
            
            self.frame  = theFrame
            self.bounds = bounds
        }
    }
    
    override class func layerClass() -> AnyClass {
        return CAShapeLayer.self
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if event!.type == .Touches {
            let tempColor = UIColor(CGColor: (self.layer as! CAShapeLayer).fillColor!)
            (self.layer as! CAShapeLayer).fillColor = tempColor.colorWithAlphaComponent(0.5).CGColor
        }
        
        super.touchesBegan(touches, withEvent: event)
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if event!.type == .Touches {
            (self.layer as! CAShapeLayer).fillColor = fillColor
        }
        
        super.touchesEnded(touches, withEvent: event)
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        if event!.type == .Touches {
            (self.layer as! CAShapeLayer).fillColor = fillColor
        }
        
        super.touchesEnded(touches!, withEvent: event)
    }
    
    private func toRadians(degrees: CGFloat) -> CGFloat {
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
                
                self.backgroundColor = UIColor.clearColor()
                
                if style == .recordEnabledButtonStyle {
                    UIView.animateWithDuration(1, delay: 0, options: .CurveLinear,
                        animations: {
                            (self.layer as! CAShapeLayer).strokeColor = self.fillColor
                            (self.layer as! CAShapeLayer).fillColor = self.fillColor
                            (self.layer as! CAShapeLayer).lineWidth = 0.5
                            self.flash()
                        }, completion: nil)
                    
                } else if style == .recordButtonStyle {
                    (self.layer as! CAShapeLayer).removeAllAnimations()
                    UIView.animateWithDuration(1, delay: 0, options: .CurveLinear,
                        animations: {
                            (self.layer as! CAShapeLayer).strokeColor = UIColor.clearColor().CGColor
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
        let color = UIColor(CGColor: fillColor!).colorWithAlphaComponent(0.2)
        CATransaction.begin()
        let strokeAnim = CABasicAnimation(keyPath: "fillColor")
        strokeAnim.fromValue = (self.layer as! CAShapeLayer).fillColor
        strokeAnim.toValue = color.CGColor
        strokeAnim.duration = 2.0
        strokeAnim.repeatCount = 0
        strokeAnim.autoreverses = true
        CATransaction.setCompletionBlock {
            if self.drawingStyle == .recordEnabledButtonStyle {
                self.flash()
            }
        }
        (self.layer as! CAShapeLayer).addAnimation(strokeAnim, forKey: "animateStrokeColor")
        CATransaction.commit()
    }
    
    private func newPathRefForStyle(style: CAUITransportButtonStyle) -> CGPath? {
        var path: CGPath? = nil
        var size = min(imageRect.size.width, imageRect.size.height)
        
        switch style {
        case .rewindButtonStyle:
            let tempPath = CGPathCreateMutable()
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
                CGPathAddArc(tempPath, nil, radius, yOffset + height/2, radius, toRadians(120), toRadians(240), false)
                CGPathAddArc(tempPath, nil, 0.5 * width - radius, yOffset + radius, radius, toRadians(240), toRadians(0), false)
                CGPathAddArc(tempPath, nil, 0.5 * width - radius, yOffset + height - radius, radius, toRadians(0), toRadians(120), false)
                CGPathCloseSubpath(tempPath)
                
                // second arrow
                CGPathMoveToPoint(tempPath, nil, 0.5*size, yOffset + height/2)
                CGPathAddArc(tempPath, nil, 0.5*size + radius, yOffset + height/2, radius, toRadians(180), toRadians(240), false)
                CGPathAddArc(tempPath, nil, width - radius, yOffset + radius, radius, toRadians(240), toRadians(0), false)
                CGPathAddArc(tempPath, nil, width - radius, yOffset + height - radius, radius, toRadians(0), toRadians(120), false)
                CGPathAddArc(tempPath, nil, 0.5*size + radius, yOffset + height/2, radius, toRadians(120), toRadians(180), false)
            #else
                var xOffset = 0.062 * size
                CGPathAddRoundedRect(tempPath, nil, CGRectMake(0, yOffset, xOffset, height), radius, radius)
                
                radius = (size * 0.0631)/2
                xOffset += 0.006 * size
                
                CGPathAddArc(tempPath, nil, xOffset + radius, yOffset + height/2, radius, toRadians(120), toRadians(240), false)
                CGPathAddArc(tempPath, nil, xOffset + width - radius, yOffset + radius, radius, toRadians(240), toRadians(0), false)
                CGPathAddArc(tempPath, nil, xOffset + width - radius, yOffset + height - radius, radius, toRadians(0), toRadians(120), false)
            #endif
            CGPathCloseSubpath(tempPath)
            
            path = tempPath
        case .pauseButtonStyle:
            let tempPath = CGPathCreateMutable()
            var height = size * 0.857
            let width  = size * 0.7452
            let barWidth = size * 0.2776
            let xOffset = round((imageRect.size.width - width)/2)
            let	yOffset = round((imageRect.size.height - height)/2)
            let radius = (size * 0.0397)/2
            
            height = round(height)
            
            CGPathAddRoundedRect(tempPath, nil, CGRectMake(xOffset, yOffset, barWidth, height), radius, radius)
            CGPathAddRoundedRect(tempPath, nil, CGRectMake(round(imageRect.size.width - xOffset - barWidth), yOffset, barWidth, height), radius, radius)
            
            path = tempPath
        case .playButtonStyle:
            let tempPath = CGPathCreateMutable()
            var height = size * 0.857
            let width  = size * 0.6538
            let xOffset = round((imageRect.size.width - width)/2)
            let yOffset = round((imageRect.size.height - height)/2)
            let radius  = (size * 0.0631)/2
            
            height = round(height)
            
            CGPathAddArc(tempPath, nil, xOffset + radius, yOffset + radius, radius, toRadians(180), toRadians(300), false)
            CGPathAddArc(tempPath, nil, xOffset + width - radius, yOffset + height/2, radius, toRadians(300), toRadians(60), false)
            CGPathAddArc(tempPath, nil, xOffset + radius, yOffset + height - radius, radius, toRadians(60), toRadians(180), false)
            CGPathCloseSubpath(tempPath)
            path = tempPath
        case .recordButtonStyle, .recordEnabledButtonStyle:
            size *= 0.7825
            let elipseRect = CGRectMake((imageRect.size.width - size)/2, (imageRect.size.height - size)/2, size, size)
            
            path = CGPathCreateWithEllipseInRect(elipseRect, nil)
        case .stopButtonStyle:
            let tempPath = CGPathCreateMutable()
            var height = size * 0.857
            let offset = round((imageRect.size.width - height)/2)
            let radius = (size * 0.0397)/2
            
            height = round(height)
            
            CGPathAddRoundedRect(tempPath, nil, CGRectMake(offset, offset, height, height), radius, radius)
            
            path = tempPath
        }
        return path
    }
    
}