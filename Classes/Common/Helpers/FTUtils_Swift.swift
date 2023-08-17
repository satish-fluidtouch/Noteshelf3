//
//  NSObject+Convenience.swift
//  Noteshelf
//
//  Created by Paramasivan on 18/10/16.
//  Copyright © 2016 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit
import FTCommon

let minImageExportSize = Int(768)

extension Notification.Name {
    static let didCompleteDropBoxAuthetication = Notification.Name(rawValue: "FTDidCompleteDropBoxAuthetication")
    static let didCancelDropBoxAuthetication = Notification.Name(rawValue: "FTDidCancelDropBoxAuthetication")
    static let didFinishDragOperation = Notification.Name(rawValue: "FTDidFinishDragOperation")
}

extension FTUtils {
    class func validateFileName(fromTextField textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let modifiedText = (textField.text! as NSString).replacingCharacters(in: range, with: string).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines);
        return !modifiedText.hasPrefix(".");
    }
    class func validateFileName(fromTextView textView: UITextView, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let modifiedText = (textView.text! as NSString).replacingCharacters(in: range, with: string).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines);
        return !modifiedText.hasPrefix(".");
    }
    static var mediaLibraryDirectoryURL: URL {
        var tempFileLoc = "";
        if let library = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).last {
            let url = URL(fileURLWithPath: library).appendingPathComponent("ClipArts");
            tempFileLoc = url.path;
            var isDir : ObjCBool = false;
            if FileManager.default.fileExists(atPath: tempFileLoc, isDirectory: &isDir) == false || !isDir.boolValue {
                do {
                    try FileManager.default.createDirectory(atPath: tempFileLoc, withIntermediateDirectories: true, attributes:nil);
                }
                catch {
                    debugPrint("Error Occured in Creating Clipart Directory")
                }
            }
        }
        return URL(fileURLWithPath: tempFileLoc);
    }
    
   class func tempZipLoc() -> NSString {
        let folder = (FTUtils.applicationCacheDirectory() as NSString).appendingPathComponent("TempZip")
        do {
            try FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true, attributes: nil)
        } catch {
            
        }
        return folder as NSString
    }
    
    class  func copyFileToTempLoc(_ fileName: String, _ path: NSString, error: inout NSError?) -> String? {
        let fileName = fileName
        let fileLoc = FTUtils.tempZipLoc().appendingPathComponent(fileName.appending(".\(nsPDFExtension)"))
        _ = try? FileManager.default.removeItem(atPath: fileLoc)
        _ = try? FileManager.default.copyItem(atPath: path as String, toPath: fileLoc)
        return fileLoc
    }
}

extension CGSize
{
    static func aspectFittedSize(_ inSize : CGSize, max maxSize : CGSize) -> CGSize {
        if (inSize.width <= maxSize.width && inSize.height <= maxSize.height) {
            return inSize;
        }
        let originalAspectRatio = inSize.width / inSize.height;
        let maxAspectRatio = maxSize.width / maxSize.height;
        
        var newSize = maxSize;
        if (originalAspectRatio > maxAspectRatio) { // scale by width
            newSize.height = CGFloat(Int(maxSize.width * inSize.height / inSize.width));
        } else {
            newSize.width = CGFloat(Int(maxSize.height  * inSize.width / inSize.height));
        }
        return newSize;
    }
    
    static func aspectFittedSize(_ inSize : CGSize, min minSize : CGSize) -> CGSize {
        if (inSize.width >= minSize.width && inSize.height >= minSize.height) {
            return inSize;
        }
        let originalAspectRatio = inSize.width / inSize.height;
        let minAspectRatio = minSize.width / minSize.height;
        
        var newSize = minSize;
        if (originalAspectRatio > minAspectRatio) { // scale by width
            newSize.width = CGFloat(Int(minSize.height  * inSize.width / inSize.height));
        } else {
            newSize.height = CGFloat(Int(minSize.width * inSize.height / inSize.width));
        }
        return newSize;
    }
}

///Use this method to measure time taken by a synchronous block of code.
func measureTime(name: String = "Time Taken", block:() -> Void) {
    #if DEBUG
        let start = now()
        block()
        let end = now()        
        NSLog("⏳ \(name): \(end-start)")
    #else
        block()
    #endif
}

func now() -> DispatchTime {
    return DispatchTime.now()
}

extension DispatchTime {
    static func - (lhs: DispatchTime, rhs: DispatchTime) -> Double {
        let nanoTime = lhs.uptimeNanoseconds - rhs.uptimeNanoseconds
        let timeInterval = Double(nanoTime) / 1_000_000
        return timeInterval // in milli seconds
    }
}

extension CGRect {
    static func union(of rects:[CGRect]) -> CGRect {
        let rect = rects.reduce(CGRect.null) { (res, rect) -> CGRect in
            return res.union(rect)
        }
        return rect
    }

    func intersects(with rects:[CGRect]) -> Bool {
        var didIntersect = false
        for rect in rects where rect.intersects(self) {
            didIntersect = true
            break
        }
        return didIntersect
    }
    
    static func clamp(rect: CGRect,maxRect: CGRect) -> CGRect {
        var newX = min(rect.origin.x,
                       maxRect.width - rect.size.width);
        newX = max(0, newX);
        
        var newY = min(rect.origin.y,
                       maxRect.height - rect.size.height);
        newY = max(0, newY);
        
        let tempRect = CGRect(x: newX,
                              y: newY,
                              width: rect.size.width,
                              height: rect.size.height);
        return tempRect;
    }

}

#if  !NS2_SIRI_APP && !NOTESHELF_ACTION && os(iOS)
func startBackgroundTask() -> UIBackgroundTaskIdentifier
{
    var task = UIBackgroundTaskIdentifier.invalid;
    task = UIApplication.shared.beginBackgroundTask(expirationHandler: {
        UIApplication.shared.endBackgroundTask(task)
    })
    return task;
}

func endBackgroundTask(_ task:UIBackgroundTaskIdentifier)
{
    if(task != UIBackgroundTaskIdentifier.invalid) {
        UIApplication.shared.endBackgroundTask(task)
    } else {
        print("Trying to end invalid task")
    }
}
#endif

#if targetEnvironment(macCatalyst)
let isMacCatalyst: Bool = true;
#else
let isMacCatalyst: Bool = false;
#endif
