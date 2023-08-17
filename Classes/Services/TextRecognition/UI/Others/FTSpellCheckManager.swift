//
//  FTSpellCheckManager.swift
//  Noteshelf3
//
//  Created by Narayana on 15/02/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTSpellCheckManager: NSObject {
    static let shared = FTSpellCheckManager()

     var spellCheckPlistURL: URL {
        let documentURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
         let plistURL = documentURL.appendingPathComponent("FTSpellChecker.plist")
        return plistURL
    }

    override init() {
        super.init()
        self.createPlistIfNeeded()
    }

    private func createPlistIfNeeded() {
        if !FileManager.default.fileExists(atPath: spellCheckPlistURL.path) {
            let dict = NSDictionary()
            let success = dict.write(toFile: spellCheckPlistURL.path, atomically: true)
            if success {
                print("Plist file created at: \(spellCheckPlistURL)")
            } else {
                print("Error creating plist file")
            }
        }
    }

     func save(spellWord: String) {
        do {
            let spellData = try Data(contentsOf: self.spellCheckPlistURL)
            if var spellDict = try PropertyListSerialization.propertyList(from: spellData, options: [], format: nil) as? [String: Date] {
                if !spellDict.contains(where: { $0.key == spellWord }) {
                    spellDict[spellWord] = Date()
                    let updatedData = try PropertyListSerialization.data(fromPropertyList: spellDict as [String: Date], format: .xml, options: 0)
                    try updatedData.write(to: self.spellCheckPlistURL, options: NSData.WritingOptions.atomic)
                }
            }
        }
        catch {
            print("Error occured while saving" + "\(String(describing: spellWord))" + "data.")
        }
    }

    func remove(spellWord: String) {
        do {
            let spellData = try Data(contentsOf: self.spellCheckPlistURL)
            if var spellDict = try PropertyListSerialization.propertyList(from: spellData, options: [], format: nil) as? [String: Date] {
                if spellDict.contains(where: { $0.key == spellWord }) {
                    spellDict.removeValue(forKey: spellWord)
                }
                let updatedData = try PropertyListSerialization.data(fromPropertyList: spellDict as [String: Date], format: .xml, options: 0)
                try updatedData.write(to: self.spellCheckPlistURL, options: .atomic)
            }
        }
        catch {
            print("Error occured while removing" + "\(String(describing: spellWord))" + "data.")
        }
    }

     func fetchSpellLearnWords() -> [String] {
         var spellDict = [String: Date]()
        do {
            let spellData = try Data(contentsOf: self.spellCheckPlistURL)
            if let dict = try PropertyListSerialization.propertyList(from: spellData, options: [], format: nil) as? [String: Date] {
                spellDict = dict
            }
            else {
                spellDict = [String: Date]()
            }
        }
        catch {
            spellDict = [String: Date]()
        }
        return Array(spellDict.keys)
    }
}
