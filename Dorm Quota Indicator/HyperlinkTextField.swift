//
//  HyperlinkTextField.swift
//  Dorm Quota Indicator
//
//  Created by Gamcheong Yuen on 25/6/2019.
//  Copyright © 2019 GreenYun Organization. All rights reserved.
//

import Cocoa

class HyperlinkTextField: NSTextField {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let attributes: [NSAttributedString.Key: AnyObject] = [
            .foregroundColor: NSColor.blue,
            .underlineStyle: NSUnderlineStyle.single.rawValue as AnyObject
        ]
        self.attributedStringValue = NSAttributedString(string: self.stringValue, attributes: attributes)
    }
    
    var url: URL?
    
    override func resetCursorRects() {
        if url != nil {
            discardCursorRects()
            addCursorRect(bounds, cursor: NSCursor.pointingHand)
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        super.mouseMoved(with: event)
        
        if url != nil {
            NSWorkspace.shared.open(url!)
        }
    }
    
}
