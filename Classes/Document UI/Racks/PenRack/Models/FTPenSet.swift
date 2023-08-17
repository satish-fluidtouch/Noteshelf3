//
//  FTPenSet.swift
//  FTPenRack
//
//  Created by Siva on 08/04/17.
//  Copyright © 2017 Fluid Touch Pvt Ltd. All rights reserved.
//

import UIKit
import MobileCoreServices

protocol FTPenSetProtocol : NSItemProviderWriting,NSCopying {
    var type: FTPenType {get set}
    var color: String {get set}
    var size: FTPenSize {get set}
    var preciseSize: CGFloat {get set}
    func isEqualTo(_ other: FTPenSetProtocol) -> Bool
    var getPenReadableName : String {get}
}

extension FTPenSetProtocol {
    var getPenReadableName : String{
        switch self.type {
        case .pen:
            return "Ballpoint"
        case .caligraphy:
            return "FountainPen"
        case .pencil:
            return "Pencil"
        case .highlighter:
            return "HighlighterRounded"
        case .pilotPen:
            return "Sharpie"
        case .flatHighlighter:
            return "HighlighterAngled"
        default:
            return ""
        }
    }

    public static var writableTypeIdentifiersForItemProvider: [String] {
        return [    kUTTypeData as String]
    }
    
    public func loadData(withTypeIdentifier typeIdentifier: String, forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void) -> Progress? {
        let progress = Progress(totalUnitCount: 1)
        // 5
        do {
            let dict = ["penType" : self.type.name,
                        "Color":self.color,
                        "Size": self.size.rawValue] as [String : Any];
            let data = try PropertyListSerialization.data(fromPropertyList: dict,
                                                              format: .xml,
                                                              options: 0)
            progress.completedUnitCount = 1
            completionHandler(data, nil)
        } catch {
            completionHandler(nil, error)
        }
        return progress
    }
}
extension FTPenSetProtocol where Self: Equatable {
    func isEqualTo(_ other: FTPenSetProtocol) -> Bool {
        guard let otherPen = other as? Self else { return false }
        return self == otherPen
    }
}
@objcMembers public class FTPenSet : NSObject, FTPenSetProtocol {
    public func copy(with zone: NSZone? = nil) -> Any {
        return FTPenSet(penSet: self);
    }

    var type: FTPenType;
    var color: String
    var size: FTPenSize;
    var preciseSize: CGFloat;

    //MARK:- Init
    init(type: FTPenType, color: String, size: FTPenSize) {
        self.type = type;
        self.color = color;
        self.size = size;
        self.preciseSize = CGFloat(size.rawValue)
    }

    init(penSet: FTPenSet) {
        self.type = penSet.type;
        self.color = penSet.color;
        self.size = penSet.size;
        self.preciseSize = penSet.preciseSize
    }
    //MARK:- Custom
    func isEmpty() -> Bool {
        return (self.color == "");
    }
    public override func isEqual(_ object: Any?) -> Bool {
        if let set2 = object as? FTPenSet, self.size == set2.size
            && self.type == set2.type
            && self.color == set2.color
            && self.preciseSizeString == set2.preciseSizeString {
            return true;
        }
        return false;
    }

    private var preciseSizeString: String {
        return String(format:"%0.1f",self.preciseSize)
    }
    
    var penReadableName: String {
        switch self.type {
        case .pen:
            return "Ballpoint"
        case .caligraphy:
            return "FountainPen"
        case .pencil:
            return "Pencil"
        case .highlighter:
            return "HighlighterRounded"
        case .pilotPen:
            return "Sharpie"
        case .flatHighlighter:
            return "HighlighterAngled"
        default:
            return ""
        }
    }
}
class FTDefaultPresenterSet: FTPresenterSet {
    init() {
        super.init(presenterType: .laserPointer, pointerColor: "EA4226", penColor: "60CE3C")
    }
}
class FTDefaultPenSet: FTPenSet {
     init() {
        super.init(type: .pen, color: "151515", size: FTPenSize.two)
    }
}

class FTDefaultHighlighterSet: FTPenSet {
    init() {
        super.init(type: .highlighter, color: "151515", size: FTPenSize.three)
    }
}

extension FTPenSet:NSItemProviderWriting{
    public static var writableTypeIdentifiersForItemProvider: [String] {
        return [	kUTTypeData as String]
    }
    
    public func loadData(withTypeIdentifier typeIdentifier: String, forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void) -> Progress? {
        let progress = Progress(totalUnitCount: 1)
        // 5
        do {
            let dict = ["penType" : self.type.name,
                        "Color":self.color,
                        "Size": self.size.rawValue] as [String : Any];
            let data = try PropertyListSerialization.data(fromPropertyList: dict,
                                                              format: .xml,
                                                              options: 0)
            progress.completedUnitCount = 1
            completionHandler(data, nil)
        } catch {
            completionHandler(nil, error)
        }
        return progress
    }
    
}
