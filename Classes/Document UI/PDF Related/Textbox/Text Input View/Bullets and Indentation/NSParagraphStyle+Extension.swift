//
//  NSParagraph+Extension.swift
//  Noteshelf
//
//  Created by Sameer on 14/09/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//
import Foundation
import UIKit
extension NSParagraphStyle {
    var bulletLists : [AnyObject]? {
        get {
            let selector = NSSelectorFromString("textLists")
            let imp = method(for: selector)
            typealias textListFunc = @convention(c) (Any?, Selector) -> [AnyObject]?
            let `func`: textListFunc = unsafeBitCast(imp, to: textListFunc.self)
            let items = `func`(self, selector)
            return items
        }
        set {
            let selector = NSSelectorFromString("setTextLists:")
            let imp = method(for: selector)
            typealias textListFunc = @convention(c) (Any, Selector, [AnyObject]?) -> Void
            let `func`: textListFunc = unsafeBitCast(imp, to: textListFunc.self)
            `func`(self, selector, newValue)
        }
    }
    
  func currentTextList(withScale scale: CGFloat) -> FTTextList? {
       if !SUPPORTS_BULLETS {
            return nil
       } else {
            guard let bulletList = bulletLists, !bulletList.isEmpty else {
                return nil
            }
            let intent = self.headIndent / scale
            let headIndent = ceilf(Float(intent))
            var level = Int(headIndent / Float(indentOffset))
            level -= 1
            if level < 0 {
                level = 0
            #if DEBUG
                print("Incorrect Head Indent \(self.headIndent)")
            #endif
            }
            level = level % bulletList.count
            return bulletList[level] as? FTTextList
        }
    }
    
  func isOrderedTextList(withScale scale: CGFloat) -> Bool {
       if !SUPPORTS_BULLETS {
             return false
        } else {
            let textList = currentTextList(withScale: scale)
            return textList?._isOrdered() ?? false
        }
    }
    
   func bulletChar(in string: String?, contentScale scale: CGFloat) -> String? {
      if !SUPPORTS_BULLETS {
          return nil
      } else {
          let currentTextList = self.currentTextList(withScale: scale)
          let scanner = Scanner(string: string ?? "")
          var scannedString: String?
        
          if #available(iOS 13.0, *) {
              scannedString = scanner.scanUpToString("\t")
          } else {
              var result: NSString?
              _ = scanner.scanUpTo("\t", into: &result)
              scannedString = result as String?
          }

          if scannedString == nil {
              return nil
          }
          var bulletString: String?
          let newNumber = currentTextList?.markerItemNumber(inLineString: string ?? "") ?? 0
          var markerString = currentTextList?.attributedMarker(forItemNumber: newNumber, scale: 1)?.string
          if !(markerString == scannedString) {
              markerString = nil
          }
          if let markerString = markerString {
              bulletString = "\(markerString)\t"
          }
          return bulletString
      }
    }
    
   func hasBullet() -> Bool {
        if !SUPPORTS_BULLETS {
             return false
        } else  {
            if headIndent > 0.01 {
                 return true
             }
             return false
        }
    }
    
    func bulletType(withScale scale: CGFloat) -> FTBulletType {
        var type = FTBulletType.none
        let bulletList = currentTextList(withScale: scale)
        if let bulletList = bulletList {
            let format = bulletList.markerFormat()
            if format == "{checkbox}" {
                type = .checkBox
            } else if (format == "{decimal}") || (format == "{upper-alpha}") {
                type = .numbers
            } else if (format == "{disc}") || (format == "{hyphen}") || (format == "{circle}") || (format == "{diamond}") {
                type = .one
            } else if (format == "{box}") || (format == "{square}") || (format == "{octal}") {
                type = .two
            }
        }
        return type
    }
}
