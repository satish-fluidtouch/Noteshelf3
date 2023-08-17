//
//  AppDelegate_KeyCommands.swift
//  Noteshelf
//
//  Created by Amar on 01/06/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

extension UIResponder {
    @objc func zoomOverlayPanDown(_ sender:Any?) {
        debugLog("UIResponder - zoomOverlayPanDown");
    }
    
    @objc func zoomOverlayPanUp(_ sender:Any?) {
        debugLog("UIResponder - zoomOverlayPanUp");
    }

    @objc func zoomOverlayPanLeft(_ sender:Any?) {
        debugLog("UIResponder - zoomOverlayPanLeft");
    }
    
    @objc func zoomOverlayPanRight(_ sender:Any?) {
        debugLog("UIResponder - zoomOverlayPanRight");
    }
}

extension UIKeyCommand {
    static var zoomOverlayPanLeft: UIKeyCommand {
        return UIKeyCommand(input: UIKeyCommand.inputLeftArrow,
                            modifierFlags: UIKeyModifierFlags(rawValue: 0),
                            action: #selector(UIResponder.zoomOverlayPanLeft(_:)));
    }
    
    static var zoomOverlayPanRight: UIKeyCommand {
        return UIKeyCommand(input: UIKeyCommand.inputRightArrow,
                            modifierFlags: UIKeyModifierFlags(rawValue: 0),
                            action: #selector(UIResponder.zoomOverlayPanRight(_:)));
    }

    static var zoomOverlayPanDown: UIKeyCommand {
        return UIKeyCommand(input: UIKeyCommand.inputDownArrow,
                            modifierFlags: UIKeyModifierFlags(rawValue: 0),
                            action: #selector(UIResponder.zoomOverlayPanDown(_:)));
    }

    static var zoomOverlayPanUp: UIKeyCommand {
        return UIKeyCommand(input: UIKeyCommand.inputUpArrow,
                            modifierFlags: UIKeyModifierFlags(rawValue: 0),
                            action: #selector(UIResponder.zoomOverlayPanUp(_:)));
    }
}
