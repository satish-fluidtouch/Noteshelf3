//
//  FTPresenterSet.swift
//  Noteshelf
//
//  Created by Ramakrishna on 07/04/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import MobileCoreServices

protocol FTPresenterSetProtocol : FTPenSetProtocol {
    var pointerColor : String { get set }
    var penColor : String {get set}
}

@objcMembers public class FTPresenterSet : NSObject, FTPresenterSetProtocol
{
    var size: FTPenSize
    
    var preciseSize: CGFloat
    
    var type: FTPenType;
    var color: String
    var penColor : String
    var pointerColor : String

    init(presenterType : FTPenType, pointerColor: String,penColor :String) {
        self.type = FTPenType(rawValue: presenterType.rawValue) ?? .laser
        self.color = presenterType == .laserPointer ? pointerColor : penColor
        self.size = FTPenSize.six
        self.preciseSize = CGFloat(size.rawValue)
        self.penColor = penColor
        self.pointerColor = pointerColor
    }
    class func getPensetFrom(info:[String:Any]) -> FTPresenterSet {
        if let penTypeValue = info[FTRackPersistanceKey.PresenterSet.presenterType.rawValue] as? Int, let penColor = info[FTRackPersistanceKey.PresenterSet.penColor.rawValue] as? String, let pointerColor = info[FTRackPersistanceKey.PresenterSet.pointerColor.rawValue] as? String, let type = FTPenType(rawValue: penTypeValue) {
            return FTPresenterSet(presenterType: type, pointerColor: pointerColor, penColor: penColor)
        }
        return FTDefaultPresenterSet()
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let copyObj = FTPresenterSet(presenterType: self.type,
                                     pointerColor: self.pointerColor,
                                     penColor: self.penColor);
        return copyObj;
    }
}
extension FTPresenterSet:NSItemProviderWriting{
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
