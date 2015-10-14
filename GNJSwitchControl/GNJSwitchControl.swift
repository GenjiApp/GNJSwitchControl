//
//  GNJSwitchControl.swift
//  GNJSwitchControl
//
//  Created by Genji on 2015/10/14.
//  Copyright © 2015 Genji App. All rights reserved.
//

import Cocoa

//////////////////
// MARK: Constants
private let kOffStateBackgroundColor = NSColor.darkGrayColor()
private let kBackgroundBorderColor = NSColor(white: 0.4, alpha: 0.5)
private let kKnobBorderColor = NSColor(white: 0.6, alpha: 1.0)
private let kKnobColor = NSColor(white: 0.9, alpha: 1.0)
private let kClickedKnobColor = NSColor(white: 0.85, alpha: 1.0)
private let kCornerRadiusRatio: CGFloat = 0.25
private let kDraggingEdgeMargin: CGFloat = 10.0

@IBDesignable
class GNJSwitchControl: NSControl {

  /////////////////////
  // MARK: - Properties
  @IBInspectable var tintColor: NSColor = NSColor.greenColor() {
    didSet {
      if state {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        backgroundLayer.backgroundColor = tintColor.CGColor
        CATransaction.commit()
      }
    }
  }

  @IBInspectable var state: Bool = false {
    didSet {
      knobLayer.frame.origin.x = state ? NSMaxX(bounds) - NSWidth(knobLayer.frame) : 0.0
      backgroundLayer.backgroundColor = state ? tintColor.CGColor : kOffStateBackgroundColor.CGColor
    }
  }

  @IBInspectable override var enabled: Bool {
    didSet {
      CATransaction.begin()
      CATransaction.setDisableActions(true)
      // layer?.opacity = 0.5 としたとき、knobGradientLayer が可視だと
      // knobLayer の角丸の背景が抜けず、表示が乱れる。
      knobGradientLayer.opacity = enabled ? 1.0 : 0.0
      layer?.opacity = enabled ? 1.0 : 0.5
      CATransaction.commit()
    }
  }

  // highlighted を override すれば良さそうだがうまくいかない。
  // たとえば、mouseDragged() で highlighted = true と代入しても、
  // 直後に print() すると false になってたりして、よく解らん。
  private var activated: Bool = false {
    didSet {
      knobLayer.backgroundColor = activated ? kClickedKnobColor.CGColor : kKnobColor.CGColor
    }
  }

  private var clickedLocationInKnob: CGPoint? = nil
  private var dragged = false

  private let backgroundLayer = CALayer()
  private let backgroundGradientLayer = CAGradientLayer()
  private let knobLayer = CALayer()
  private let knobGradientLayer = CAGradientLayer()


  ///////////////////////
  // MARK: - Initializers
  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    setup()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setup()
  }


  /////////////////////////
  // MARK: - Private Method
  private func setup() {
    enabled = true
    wantsLayer = true
    let rootLayer = CALayer()
    rootLayer.needsDisplayOnBoundsChange = true
    rootLayer.delegate = self
    layer = rootLayer

    backgroundLayer.masksToBounds = true
    backgroundLayer.borderColor = kBackgroundBorderColor.CGColor
    backgroundLayer.borderWidth = 1.0
    backgroundLayer.backgroundColor = kOffStateBackgroundColor.CGColor
    layer?.addSublayer(backgroundLayer)

    backgroundGradientLayer.colors = [
      NSColor(white: 0.5, alpha: 0.0).CGColor,
      NSColor(white: 0.5, alpha: 0.25).CGColor,
    ]
    backgroundGradientLayer.locations = [
      NSNumber(float: 0.0),
      NSNumber(float: 0.95),
    ]
    backgroundGradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
    backgroundGradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
    backgroundLayer.addSublayer(backgroundGradientLayer)

    knobLayer.masksToBounds = true
    knobLayer.borderColor = kKnobBorderColor.CGColor
    knobLayer.borderWidth = 1.0
    knobLayer.backgroundColor = kKnobColor.CGColor
    layer?.addSublayer(knobLayer)

    knobGradientLayer.colors = [
      NSColor(white: 1.0, alpha: 0.2).CGColor,
      NSColor(white: 1.0, alpha: 0.3).CGColor,
      NSColor(white: 1.0, alpha: 0.4).CGColor,
      NSColor(white: 1.0, alpha: 0.7).CGColor,
    ]
    knobGradientLayer.locations = [
      NSNumber(float: 0.0),
      NSNumber(float: 0.5),
      NSNumber(float: 0.5),
      NSNumber(float: 1.0),
    ]
    knobGradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
    knobGradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
    knobLayer.addSublayer(knobGradientLayer)
  }


  /////////////////////////////////
  // MARK: - CALayerDelegate Method
  override func displayLayer(layer: CALayer) {
    let cornerRadius = frame.size.height * kCornerRadiusRatio

    CATransaction.begin()
    CATransaction.setDisableActions(true)
    backgroundLayer.frame = NSInsetRect(bounds, 1.0, 0.0)
    backgroundLayer.cornerRadius = cornerRadius

    backgroundGradientLayer.frame = backgroundLayer.bounds

    let knobWidth = bounds.size.width * 0.5
    knobLayer.frame = NSRect(
      x: state ? NSMaxX(bounds) - knobWidth : 0.0,
      y: 0.0,
      width: knobWidth,
      height: bounds.size.height)
    knobLayer.cornerRadius = cornerRadius

    knobGradientLayer.frame = knobLayer.bounds
    CATransaction.commit()
  }


  ////////////////////////////
  // MARK: - NSControl Methods
  override func mouseDown(theEvent: NSEvent) {
    if !enabled { return }

    activated = true

    let locationInSwitch = convertPoint(theEvent.locationInWindow, fromView: nil)
    if NSPointInRect(locationInSwitch, knobLayer.frame) {
      clickedLocationInKnob = knobLayer.convertPoint(locationInSwitch, fromLayer: layer)
      if clickedLocationInKnob!.x < kDraggingEdgeMargin {
        clickedLocationInKnob!.x = kDraggingEdgeMargin
      }
      else if clickedLocationInKnob!.x > NSMaxX(knobLayer.frame) - kDraggingEdgeMargin {
        clickedLocationInKnob!.x = NSMaxX(knobLayer.frame) - kDraggingEdgeMargin
      }
    }
    else {
      clickedLocationInKnob = nil
    }
  }

  override func mouseDragged(theEvent: NSEvent) {
    if !enabled { return }

    dragged = true
    let locationInWindow = theEvent.locationInWindow
    activated = NSPointInRect(locationInWindow, frame)
    var x: CGFloat
    if let clickedLocationInKnob = clickedLocationInKnob where activated {
      let locationInSwitch = convertPoint(locationInWindow, fromView: nil)
      x = locationInSwitch.x - clickedLocationInKnob.x
      if x < 0 {
        x = 0.0
      }
      else if x > NSMaxX(bounds) - NSWidth(knobLayer.frame) {
        x = NSMaxX(bounds) - NSWidth(knobLayer.frame)
      }
    }
    else {
      x = state ? NSMaxX(bounds) - NSWidth(knobLayer.frame) : 0.0
    }
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    knobLayer.frame.origin.x = x
    CATransaction.commit()
  }

  override func mouseUp(theEvent: NSEvent) {
    if !enabled { return }

    let locationInWindow = theEvent.locationInWindow
    if dragged && clickedLocationInKnob != nil {
      let oldState = state
      state = NSMidX(knobLayer.frame) > NSMidX(bounds)
      if state != oldState && action != nil {
        sendAction(action, to: target)
      }
    }
    else if NSPointInRect(locationInWindow, frame) {
      state = !state
      if action != nil {
        sendAction(action, to: target)
      }
    }

    activated = false
    dragged = false
    clickedLocationInKnob = nil
  }

}
