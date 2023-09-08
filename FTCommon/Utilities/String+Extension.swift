//
//  File.swift
//  
//
//  Created by Narayana on 16/05/22.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

public extension String {
    var floatValue: Float {
        return Float(self) ?? 0;
    }

    var localized : String {
        return NSLocalizedString(self, comment: "Localized String")
    }

    var localizedEnglish: String {
        let bundle = Bundle.main
        if let path = bundle.path(forResource: "en", ofType: "lproj") {
            let localizedBundle = Bundle(path: path)
            return NSLocalizedString(self, tableName: "Localizable", bundle: localizedBundle ?? bundle, value: "", comment: "")
        } else {
            return NSLocalizedString(self, tableName: "Localizable", bundle: bundle, value: "", comment: "")
        }
    }

    func containsWhitespaceAndNewlines() -> Bool {
        return rangeOfCharacter(from: .whitespacesAndNewlines) != nil
    }

    var firstUppercased: String {
       return prefix(1).uppercased() + dropFirst()
    }

    var firstCapitalized: String {
      return  prefix(1).capitalized + dropFirst()
    }

    var pathExtension: String {
        return (self as NSString).pathExtension
    }
    var lastPathComponent: String {
        return (self as NSString).lastPathComponent
    }

    var deletingPathExtension: String {
        return (self as NSString).deletingPathExtension
    }

    var deletingLastPathComponent: String {
        return (self as NSString).deletingLastPathComponent
    }

    func validateFileName() -> String {
        var docName = components(separatedBy: CharacterSet.controlCharacters).joined(separator: " ")

        let extentsion = docName.pathExtension
        docName = docName.deletingPathExtension

        docName = docName.replacingOccurrences(of: "/", with: "-")
        docName = (docName as NSString).replacingOccurrences(of: ".", with: "", options: .anchored, range: NSRange(location: 0, length: docName.count))

        //doc name cannot be greater than 240 charecters
        if docName.count > 240 {
            let range = (docName as NSString).rangeOfComposedCharacterSequence(at: 240)
            docName = (docName as NSString).substring(to: range.location)
        }

        if docName.count == 0 {
            docName = NSLocalizedString("Untitled", comment: "Untitled")
        }
        docName = docName.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        docName = docName + "." + extentsion
        return docName
    }

    func widthOfString(usingFont font: Font) -> CGFloat {
        let fontAttributes = [NSAttributedString.Key.font: font]
        let size = self.size(withAttributes: fontAttributes)
        return size.width
    }

    mutating func add(prefix: String) {
        self = prefix + self
    }
    
    var isValidURL: Bool {
      let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
      if let match = detector.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count)) {
        // it is a link, if the match covers the whole string
        return match.range.length == self.utf16.count
      } else {
        return false
      }
    }
    
    func getUrlRequestFromString() ->URLRequest? {
        if self.isEmpty == false {
            var searchString = self.trimmingCharacters(in: .whitespaces)
            
            if searchString.isValidURL {
                if !searchString.hasPrefix("https://") && !searchString.hasPrefix("http://") {
                    searchString = "https://" + searchString
                }
                
                var components = URLComponents(string: searchString)
                if let host = components?.host?.lowercased() {
                    if !host.hasPrefix("www.") {
                        components?.host = "www." + host
                    }
                }

                if let urlString = components?.url?.absoluteString, let url = URL(string: urlString) {
                    let request = URLRequest(url: url)
                    return request
                }
                
            } else {
                let strFormat = self.replacingOccurrences(of: " ", with: "+")
                let selectedAddress = String(format: "https://www.google.com/search?q=%@",strFormat)
                if let webURL = URL(string: selectedAddress) {
                    let request = URLRequest(url: webURL)
                    return request
                }
            }
        }
        return nil
    }
}
