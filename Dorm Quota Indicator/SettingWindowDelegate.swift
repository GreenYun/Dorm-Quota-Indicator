//
//  SettingWindowDelegate.swift
//  Dorm Quota Indicator
//
//  Created by Gamcheong Yuen on 24/6/2019.
//  Copyright © 2019 GreenYun Organization. All rights reserved.
//

import Cocoa

class SettingWindowDelegate: NSObject, NSWindowDelegate {
    
    var shouldCloseHandler: () -> Bool = { return false }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        return shouldCloseHandler()
    }
}
