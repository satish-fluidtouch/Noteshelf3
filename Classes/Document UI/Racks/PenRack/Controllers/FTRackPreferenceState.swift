//
//  FTRackPreferenceState.swift
//  Noteshelf
//
//  Created by srinivas on 23/08/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTRackPreferenceState {
    
    private enum Keys: String {
        case handWriting
        case textBoxes
        case photos
        case shapes
        case autoSelectPreviousTool
        case eraseEntireStroke
        case eraseHighlighterOnly
        case erasePencilOnly
        case holdToConvertToShape
        case drawStraightLines
        case selectionTypeLasso
    }
}

// MARK: - Lasso
extension FTRackPreferenceState {
    
    public static var handWriting: Bool {
        
        get {
            if nil == UserDefaults.standard.value(forKey: Keys.handWriting.rawValue) {
                return true
            }
            return UserDefaults.standard.bool(forKey: Keys.handWriting.rawValue)
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.handWriting.rawValue)
        }
        
    }
    
    public static var textBoxes: Bool {
        
        get {
            if nil == UserDefaults.standard.value(forKey: Keys.textBoxes.rawValue) {
                return true
            }
            return UserDefaults.standard.bool(forKey: Keys.textBoxes.rawValue)
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.textBoxes.rawValue)
        }
        
    }
    
    public static var photos: Bool {
        
        get {
            if nil == UserDefaults.standard.value(forKey: Keys.photos.rawValue) {
                return true
            }
            return UserDefaults.standard.bool(forKey: Keys.photos.rawValue)
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.photos.rawValue)
        }
        
    }
    
    public static var shapes: Bool {
        
        get {
            if nil == UserDefaults.standard.value(forKey: Keys.shapes.rawValue) {
                return true
            }
            return UserDefaults.standard.bool(forKey: Keys.shapes.rawValue)
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.shapes.rawValue)
        }
        
    }
    
    public static var lassoSelectionType: Int {
        
        get {
            UserDefaults.standard.integer(forKey: Keys.selectionTypeLasso.rawValue)
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.selectionTypeLasso.rawValue)
        }
        
    }
    
    
    public static func allowAnnotations() -> [FTAnnotationType] {
        var annoTypes = [FTAnnotationType]()
        if self.handWriting {
            annoTypes.append(.stroke)
        }
        
        if self.textBoxes {
            annoTypes.append(.text)
        }
        
        if self.photos {
            annoTypes.append(.image)
            annoTypes.append(.sticker)
            annoTypes.append(.sticky)
            annoTypes.append(.webclip)
        }
        
        if self.shapes {
            annoTypes.append(.shape)
        }
        
        return annoTypes
    }
    
}

// MARK: - Eraser
extension FTRackPreferenceState {
    
    public static var autoSelectPreviousTool: Bool {
        
        get {
            UserDefaults.standard.bool(forKey: Keys.autoSelectPreviousTool.rawValue)
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.autoSelectPreviousTool.rawValue)
        }
        
    }
    
    public static var eraseEntireStroke: Bool {
        
        get {
            UserDefaults.standard.bool(forKey: Keys.eraseEntireStroke.rawValue)
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.eraseEntireStroke.rawValue)
        }
        
    }
    
    public static var eraseHighlighterOnly: Bool {
        
        get {
            UserDefaults.standard.bool(forKey: Keys.eraseHighlighterOnly.rawValue)
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.eraseHighlighterOnly.rawValue)
        }
        
    }
    
    public static var erasePencilOnly: Bool {
        
        get {
            UserDefaults.standard.bool(forKey: Keys.erasePencilOnly.rawValue)
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.erasePencilOnly.rawValue)
        }
        
    }
    
}

// MARK: - Pen, Highlighter
extension FTRackPreferenceState {
    
    public static var holdToConvertToShape: Bool {
        
        get {
            UserDefaults.standard.bool(forKey: Keys.holdToConvertToShape.rawValue)
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.holdToConvertToShape.rawValue)
        }
        
    }
    
    public static var drawStraightLines: Bool {
        
        get {
            UserDefaults.standard.bool(forKey: Keys.drawStraightLines.rawValue)
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.drawStraightLines.rawValue)
        }
        
    }
    
}
