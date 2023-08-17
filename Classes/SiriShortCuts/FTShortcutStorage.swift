//
//  FTShortcutStorage.swift
//  Noteshelf
//
//  Created by Dev_Guest on 11/09/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

let DEFAULT_COUNTER = "5"
let MAX_COUNTER = "6"
let UUID_KEY = "uuid"
let VALUE_KEY = "counterValue"
let OPEN_NOTEBOOK_SHORTCUTS_LIST_KEY = "openNotebookShortcutList"
let QUICK_CREATE_SHORTCUTS_KEY = "quickCreateShortcut"
let CREATE_AUDIO_NOTE_SHORTCUT_KEY = "createAudioNoteShortcut"
let DONT_SAVE = "no"
let NEVER_SAVE = "never"
let SAVE = "yes"

//enum ShortcutStatus {
//    case Yes
//    case No
//    case Never
//}
// QC stands for QuickCreate
class FTShortcutStorage: NSObject {
    
    
    static func shouldSuggestShortcutForUUID(_ uuid : String) -> Bool {
        let userDefault = UserDefaults.standard
        
        if let shortcutArray = userDefault.array(forKey: OPEN_NOTEBOOK_SHORTCUTS_LIST_KEY) as? [[String : String]],
            let dictionary = (shortcutArray.filter{ $0[UUID_KEY] == uuid }).first  {
            if let number = Int(dictionary[VALUE_KEY]!) {
                return number == 1 ? true : false
            }else{
                return false
            }
        }
        return false
    }
    
    static func updateShortcutForUUID(_ uuid : String , valueString : String?) {
        let userDefault = UserDefaults.standard
        var shortcutArray = userDefault.array(forKey: OPEN_NOTEBOOK_SHORTCUTS_LIST_KEY) as? [[String : String]]
        if shortcutArray == nil {
            let dictionary = [UUID_KEY : uuid, VALUE_KEY : DEFAULT_COUNTER]
            shortcutArray = [[String : String]]()
            shortcutArray?.append(dictionary)
        }else{
            if var dictionary = (shortcutArray!.filter{ $0[UUID_KEY] == uuid }).first  {
                if dictionary[VALUE_KEY] == SAVE {
                    return
                }
                let index = shortcutArray!.index(of: dictionary)
                if index != nil {
                    shortcutArray?.remove(at: index!)
                }
                if valueString == nil {
                    if var number = Int(dictionary[VALUE_KEY]!) {
                        number -= 1
                        dictionary[VALUE_KEY] = "\(number)"
                    }
                }else{
                    if valueString == DONT_SAVE {
                        dictionary[VALUE_KEY] = MAX_COUNTER
                    }else{
                        dictionary[VALUE_KEY] = valueString!
                    }
                }
                shortcutArray?.append(dictionary)
            }else{
                let dictionary = [UUID_KEY : uuid, VALUE_KEY : DEFAULT_COUNTER]
                shortcutArray?.append(dictionary)
            }
        }
        userDefault.set(shortcutArray, forKey: OPEN_NOTEBOOK_SHORTCUTS_LIST_KEY)
        userDefault.synchronize()
    }
    
    static func removeShortcutDataForUUID(_ uuid : String) {
        let userDefault = UserDefaults.standard
        if var shortcutArray = userDefault.array(forKey: OPEN_NOTEBOOK_SHORTCUTS_LIST_KEY) as? [[String : String]],
            let dictionary = (shortcutArray.filter{ $0[UUID_KEY] == uuid }).first  {
            let index = shortcutArray.index(of: dictionary)
            if index != nil {
                shortcutArray.remove(at: index!)
                userDefault.set(shortcutArray, forKey: OPEN_NOTEBOOK_SHORTCUTS_LIST_KEY)
                userDefault.synchronize()
            }
        }
    }
    
    static func shouldSuggestAudioNoteShortcut() -> Bool {
        return self.shouldSuggestShortcutForKey(CREATE_AUDIO_NOTE_SHORTCUT_KEY)
    }
    
    static func updateAudioNoteShortcut(_ value : String?) {
        self.updateShortcutForKey(value, key: CREATE_AUDIO_NOTE_SHORTCUT_KEY)
    }
    
    static func shouldSuggestQCShortCut() -> Bool {
        return self.shouldSuggestShortcutForKey(QUICK_CREATE_SHORTCUTS_KEY)
    }
    
    static func updateQCShortcut(_ value : String?) {
        self.updateShortcutForKey(value, key: QUICK_CREATE_SHORTCUTS_KEY)
    }
    
    fileprivate static func shouldSuggestShortcutForKey(_ key : String) -> Bool {
        let userDefault = UserDefaults.standard
        if let value = userDefault.string(forKey: key) {
            if let number = Int(value) {
                return number == 1 ? true : false
            }else{
                return false
            }
        }
        return false
    }
    
    fileprivate static func updateShortcutForKey(_ value : String?, key: String) {
        let userDefault = UserDefaults.standard
        if let valueString = userDefault.string(forKey: key) {
            if valueString == SAVE {
                return
            }
            if value == nil {
                if var number = Int(valueString) {
                    number -= 1
                    userDefault.set("\(number)", forKey: key)
                }
            }else{
                if value == DONT_SAVE {
                    userDefault.set(MAX_COUNTER, forKey: key)
                }else{
                    userDefault.set(value!, forKey: key)
                }
            }
        }else{
            userDefault.set(DEFAULT_COUNTER, forKey: key)
        }
        userDefault.synchronize()
    }
}
