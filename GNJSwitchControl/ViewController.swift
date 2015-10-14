//
//  ViewController.swift
//  GNJSwitchControl
//
//  Created by Genji on 2015/10/14.
//  Copyright © 2015 Genji App. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

  override func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
  }

  override var representedObject: AnyObject? {
    didSet {
      // Update the view, if already loaded.
    }
  }

  @IBAction func switchStateChanged(sender: GNJSwitchControl) {
    print(sender.state)
  }

}

