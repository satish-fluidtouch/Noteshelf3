//
//  FTPenDefaults.swift
//  Noteshelf3
//
//  Created by Narayana on 18/07/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTRenderKit

@objcMembers public class FTRackData: NSObject {
    let type: FTRackType
    private(set) var userActivity: NSUserActivity?

    private var lastSelectedPenType: Int!
    private var lastSelectedHighlighterType: Int!

    private var pioletPenInfo: FTPilotPen!
    private var caligraphyPenInfo: FTCaligraphyPen!
    private var penInfo: FTPen!
    private var pencilInfo: FTPencil!
    private var flatHighlighterInfo: FTFlatHighlighter!
    private var highlighterInfo: FTHighlighter!

    private var shapeInfo: FTShapeTypeInfo!

    private(set) var defaultPresetColors: [String] = []
    private(set) var laserPenColors: [String] = []
    private(set) var laserPointerColors: [String] = []

    private var _currentPresetColors: [String] = []
    private var _currentPenSet: FTPenSetProtocol!

    public init(type:FTRackType,userActivity: NSUserActivity?) {
        self.type = type
        self.userActivity = userActivity
        self._currentPenSet = FTDefaultPenSet()
        super.init()
        self.fillExistingData()
    }

    var currentPresetColors: [String] {
        get {
            return _currentPresetColors
        }
        set {
            self._currentPresetColors = newValue
        }
    }

    var currentPenset: FTPenSetProtocol {
        get {
            if let penset = _currentPenSet {
                return penset
            }
            return self.type == .pen ? FTDefaultPenSet() : FTDefaultHighlighterSet()
        }
        set {
            self._currentPenSet = newValue
        }
    }

    var penSizes: [FTPenSize] {
        var sizes = FTPenSize.allCases
        if self.type == .highlighter {
            sizes = FTPenSize.allCases.filter { $0 != .zero && $0 != .seven && $0 != .eight }
        }
        return sizes
    }
}

extension FTRackData {
    public func defaultColors(for type: FTPenType) -> [FTFavoriteColor] {
        let rackDict = FTRackDataManager.shared.getDefaultStockData()
        var colors: [FTFavoriteColor] = []
        switch type {
        case .caligraphy:
            colors = rackDict.caligraphyPen.favouriteColors
        case .pilotPen:
            colors = rackDict.pilotPen.favouriteColors
        case .pencil:
            colors = rackDict.pencil.favouriteColors
        case .pen:
            colors = rackDict.pen.favouriteColors
        case .highlighter:
            colors = rackDict.highlighter.favouriteColors
        case .flatHighlighter:
            colors = rackDict.flatHighlighter.favouriteColors
        default:
            break
        }
        return colors
    }

    public func lastSelectedColor(for type: FTPenType) -> String {
        var color: String?
        if self.type == .pen {
            if type == .caligraphy {
                color = self.caligraphyPenInfo.selectedColor
            } else if type == .pilotPen {
                color = self.pioletPenInfo.selectedColor
            } else if type == .pencil {
                color = self.pencilInfo.selectedColor
            } else {
                color = self.penInfo.selectedColor
            }
        } else if self.type == .highlighter {
            if type == .flatHighlighter {
                color = self.flatHighlighterInfo.selectedColor
            } else {
                color = self.highlighterInfo.selectedColor
            }
        } else if self.type == .shape {
            color = self.shapeInfo.selectedColor
        }
        return color ?? self.currentPenset.color
    }

    public func lastSelectedPenSize(for type: FTPenType) -> (size: FTPenSize, preciseSize: CGFloat) {
        var size: CGFloat?
        if self.type == .pen {
            if type == .caligraphy {
                size = self.caligraphyPenInfo.selectedSize
            } else if type == .pilotPen {
                size = self.pioletPenInfo.selectedSize
            } else if type == .pencil {
                size = self.pencilInfo.selectedSize
            } else {
                size = self.penInfo.selectedSize
            }
        } else if self.type == .highlighter {
            if type == .flatHighlighter {
                size = self.flatHighlighterInfo.selectedSize
            } else {
                size = self.highlighterInfo.selectedSize
            }
        } else if self.type == .shape {
            size = self.shapeInfo.selectedSize
        }
        guard let selSize = size, let penSize = FTPenSize(rawValue: Int(truncating: selSize as NSNumber)) else {
            return (self.currentPenset.size, self.currentPenset.preciseSize)
        }
       return (penSize, selSize)
    }

    public func getFavoriteColors(for type: FTPenType) -> [FTFavoriteColor] {
        var favColors: [FTFavoriteColor] = []
        if self.type == .pen {
            if type == .caligraphy {
                favColors = self.caligraphyPenInfo.favouriteColors
            } else if type == .pilotPen {
                favColors = self.pioletPenInfo.favouriteColors
            } else if type == .pencil {
                favColors = self.pencilInfo.favouriteColors
            } else {
                favColors = self.penInfo.favouriteColors
            }
        } else if self.type == .highlighter {
            if type == .flatHighlighter {
                favColors = self.flatHighlighterInfo.favouriteColors
            } else {
                favColors = self.highlighterInfo.favouriteColors
            }
        } else if self.type == .shape {
            favColors = self.shapeInfo.favouriteColors
        }
        return favColors
    }

    public func getFavoriteSizes(for type: FTPenType) -> [FTFavoriteSize] {
        var favSizes: [FTFavoriteSize] = []
        if self.type == .pen {
            if type == .caligraphy {
                favSizes = self.caligraphyPenInfo.favouriteSizes
            } else if type == .pilotPen {
                favSizes = self.pioletPenInfo.favouriteSizes
            } else if type == .pencil {
                favSizes = self.pencilInfo.favouriteSizes
            } else {
                favSizes = self.penInfo.favouriteSizes
            }
        } else if self.type == .highlighter {
            if type == .flatHighlighter {
                favSizes = self.flatHighlighterInfo.favouriteSizes
            } else {
                favSizes = self.highlighterInfo.favouriteSizes
            }
        }  else if self.type == .shape {
            favSizes = self.shapeInfo.favouriteSizes
        }
        return favSizes
    }

    public func saveFavoriteColors(_ colors: [FTPenColorModel], type: FTPenType) {
        var rackDict = self.getExistingRackDictionary()
        let favColors: [FTFavoriteColor] = colors.map({
            FTFavoriteColor(color: $0.hex, isSelected: $0.isSelected)
        })
        if self.type == .pen {
            if type == .caligraphy {
                self.caligraphyPenInfo.favouriteColors = favColors
                rackDict.caligraphyPen = self.caligraphyPenInfo
            } else if type == .pilotPen {
                self.pioletPenInfo.favouriteColors = favColors
                rackDict.pilotPen = self.pioletPenInfo
            } else if type == .pencil {
                self.pencilInfo.favouriteColors = favColors
                rackDict.pencil = self.pencilInfo
            } else {
                self.penInfo.favouriteColors = favColors
                rackDict.pen = self.penInfo
            }
        } else if self.type == .highlighter {
            if type == .flatHighlighter {
                self.flatHighlighterInfo.favouriteColors = favColors
                rackDict.flatHighlighter = self.flatHighlighterInfo
            } else {
                self.highlighterInfo.favouriteColors = favColors
                rackDict.highlighter = self.highlighterInfo
            }
        } else if self.type == .shape {
            self.shapeInfo.favouriteColors = favColors
            rackDict.shapeInfo = self.shapeInfo
        }
        FTRackDataManager.shared.saveRackData(rackDict)
    }

    public func saveFavoriteSizes(_ sizes: [FTPenSizeModel], type: FTPenType) {
        var rackDict = self.getExistingRackDictionary()
        let favSizes: [FTFavoriteSize] = sizes.map({
            FTFavoriteSize(size: $0.size, isSelected: $0.isSelected)
        })
        if self.type == .pen {
            if type == .caligraphy {
                self.caligraphyPenInfo.favouriteSizes = favSizes
                rackDict.caligraphyPen = self.caligraphyPenInfo
            } else if type == .pilotPen {
                self.pioletPenInfo.favouriteSizes = favSizes
                rackDict.pilotPen = self.pioletPenInfo
            } else if type == .pencil {
                self.pencilInfo.favouriteSizes = favSizes
                rackDict.pencil = self.pencilInfo
            } else {
                self.penInfo.favouriteSizes = favSizes
                rackDict.pen = self.penInfo
            }
        } else if self.type == .highlighter {
            if type == .flatHighlighter {
                self.flatHighlighterInfo.favouriteSizes = favSizes
                rackDict.flatHighlighter = self.flatHighlighterInfo
            } else {
                self.highlighterInfo.favouriteSizes = favSizes
                rackDict.highlighter = self.highlighterInfo
            }
        } else if self.type == .shape {
            self.shapeInfo.favouriteSizes = favSizes
            rackDict.shapeInfo = self.shapeInfo
        }
        FTRackDataManager.shared.saveRackData(rackDict)
    }

    public func saveCurrentColors() {
        var rackDict = self.getExistingRackDictionary()
        if self.type == .highlighter {
            rackDict.currentHighlighterPresetColors = self.currentPresetColors
        } else {
            rackDict.currentPresetColors = self.currentPresetColors
        }
        FTRackDataManager.shared.saveRackData(rackDict)
    }

    func getCurrentPenSet() -> FTPenSetProtocol {
        if let penSet = self.currentPenSetFromUserActivity() {
            return penSet
        }
        else if let penSet = self.currentPenSetFromUserdefaults() {
            self.saveCurrentPenSetInfForQuickAccess(penSet)
            return penSet
        }
        else {
            self.saveCurrentPenSetInfForQuickAccess(self.currentPenset)
            return self.currentPenset
        }
    }

    public func resetColors() {
        var rackDict = self.getExistingRackDictionary()
        if self.type == .highlighter {
            rackDict.currentHighlighterPresetColors = self.defaultPresetColors
        } else {
            rackDict.currentPresetColors = self.defaultPresetColors
        }
        FTRackDataManager.shared.saveRackData(rackDict)
    }

    public func saveCurrentSelection() {
        var rackDict = self.getExistingRackDictionary()
        let penSet = self.currentPenset
        var currentPenSet: [String: AnyObject] = [:]
        if self.type == .presenter, let presenterSet = self.currentPenset as? FTPresenterSetProtocol {
            currentPenSet[FTRackPersistanceKey.PresenterSet.presenterType.rawValue] = presenterSet.type.rawValue as AnyObject?
            currentPenSet[FTRackPersistanceKey.PresenterSet.pointerColor.rawValue] = presenterSet.pointerColor as AnyObject?
            currentPenSet[FTRackPersistanceKey.PresenterSet.penColor.rawValue] = presenterSet.penColor as AnyObject?
        } else {
            currentPenSet[FTRackPersistanceKey.PenSet.size.rawValue] = penSet.size.rawValue as AnyObject?
            currentPenSet[FTRackPersistanceKey.PenSet.type.rawValue] = penSet.type.rawValue as AnyObject?
            currentPenSet[FTRackPersistanceKey.PenSet.color.rawValue] = penSet.color as AnyObject?
            currentPenSet[FTRackPersistanceKey.PenSet.preciseSize.rawValue] = penSet.preciseSize as AnyObject?
        }
        if self.type == .pen {
            rackDict.lastSelectedPenType = penSet.type.rawValue
        } else if self.type == .highlighter {
            rackDict.lastSelectedHighlighterType = penSet.type.rawValue
        }
        FTRackDataManager.shared.saveRackData(rackDict)
        self.saveCurrentPenSetInfForQuickAccess(penSet)
    }
}

// MARK: - Helper Methods of data preparation, data fetching, data saving etc
private extension FTRackData {
    private func fillExistingData() {
        let rackDict = self.getExistingRackDictionary()
        if self.type == .highlighter {
            self.defaultPresetColors = rackDict.defaultHighlighterPresetColors
            self.currentPresetColors = rackDict.currentHighlighterPresetColors
        } else {
            self.defaultPresetColors = rackDict.defaultPresetColors
            self.currentPresetColors = rackDict.currentPresetColors
        }
        self.laserPenColors = rackDict.presenterInfo.penColors.map({ $0.color })
        self.laserPointerColors = rackDict.presenterInfo.pointerColors.map({ $0.color })

        // Pens info
        self.pioletPenInfo = rackDict.pilotPen
        self.caligraphyPenInfo = rackDict.caligraphyPen
        self.penInfo = rackDict.pen
        self.pencilInfo = rackDict.pencil
        self.lastSelectedPenType = rackDict.lastSelectedPenType

        // Highlighters info
        self.flatHighlighterInfo = rackDict.flatHighlighter
        self.highlighterInfo = rackDict.highlighter
        self.lastSelectedHighlighterType = rackDict.lastSelectedHighlighterType

        // ShapeInfo
        self.shapeInfo = rackDict.shapeInfo

        // current penset
        if let penSet = currentPenSetFromUserActivity() {
            self._currentPenSet = penSet
        } else if let penSet = currentPenSetFromUserdefaults() {
            self._currentPenSet = penSet
        } else {
            if self.type == .pen {
                self._currentPenSet = self.getCurrentPenInfo(using: rackDict)
            } else if self.type == .highlighter {
                self._currentPenSet = self.getCurrentHighlighterInfo(using: rackDict)
            } else if self.type == .presenter {
                self._currentPenSet = self.getCurrentPresenterInfo(using: rackDict)
            } else if self.type == .shape {
                // Always we are drawing shape with pilot pen, initial attributes assignment
                self._currentPenSet.type = .pilotPen
                if let prevSize: CGFloat = self.shapeInfo.selectedSize,  let size = FTPenSize(rawValue: Int(truncating: prevSize as NSNumber)) {
                    self._currentPenSet.size = size
                    self._currentPenSet.preciseSize = prevSize
                }
                if let prevColor: String = self.shapeInfo.selectedColor {
                    self._currentPenSet.color = prevColor
                }
            }
        }

        if self.type == .pen {
            self.lastSelectedPenType = self._currentPenSet.type.rawValue
        } else if self.type == .highlighter {
            self.lastSelectedHighlighterType = self._currentPenSet.type.rawValue
        }
    }

    private func getExistingRackDictionary() -> FTRackInfoModel {
        let rackDictionary = FTRackDataManager.shared.getRackData()
        return rackDictionary
    }

    private func currentPenSetFromUserActivity() -> FTPenSetProtocol? {
        if let penSetInfo = self.userActivity?.userInfo?[self.type.persistencekey] as? [String: Any] {
            return self.loadCurrentPenSet(info: penSetInfo)
        }
        return nil
    }

    private func currentPenSetFromUserdefaults() -> FTPenSetProtocol? {
        let standardUserDefaults = UserDefaults.standard
        if let penSetDictionary = standardUserDefaults.value(forKey: self.type.persistencekey) as? [String: Any] {
            return self.loadCurrentPenSet(info: penSetDictionary)
        }
        return nil
    }

    private func loadCurrentPenSet(info: [String: Any]) -> FTPenSetProtocol {
        if self.type == .presenter {
            return FTPresenterSet.getPensetFrom(info: info)
        } else {
            if let currentSize = info[FTRackPersistanceKey.PenSet.size.rawValue] as? NSNumber, let currentType = info[FTRackPersistanceKey.PenSet.type.rawValue] as? NSNumber, let currentColor = info[FTRackPersistanceKey.PenSet.color.rawValue] as? String, let size = FTPenSize(rawValue: Int(truncating: currentSize)), let penType = FTPenType(rawValue: Int(truncating: currentType)) {

                let penset = FTPenSet(type: penType, color: currentColor, size:size)
                //Precise size may not be needed to store everytime.
                if let preciseSize = info[FTRackPersistanceKey.PenSet.preciseSize.rawValue] as? CGFloat {
                    penset.preciseSize = preciseSize
                }
                return penset
            }
            return FTDefaultPenSet()
        }
    }

    private func saveCurrentPenSetInfForQuickAccess(_ penSet : FTPenSetProtocol?) {
        guard let _penSet = penSet else { return  }
        let standardUserDefaults = UserDefaults.standard
        var penSetDictionary = [String: Any]()
        if self.type == .presenter, let presenterSet = self.currentPenset as? FTPresenterSetProtocol
        {
            penSetDictionary[FTRackPersistanceKey.PresenterSet.presenterType.rawValue] = presenterSet.type.rawValue as AnyObject?
            penSetDictionary[FTRackPersistanceKey.PresenterSet.pointerColor.rawValue] = presenterSet.pointerColor as AnyObject?
            penSetDictionary[FTRackPersistanceKey.PresenterSet.penColor.rawValue] = presenterSet.penColor as AnyObject?
        }else{
            penSetDictionary[FTRackPersistanceKey.PenSet.size.rawValue] = _penSet.size.rawValue as AnyObject?
            penSetDictionary[FTRackPersistanceKey.PenSet.type.rawValue] = _penSet.type.rawValue as AnyObject?
            penSetDictionary[FTRackPersistanceKey.PenSet.color.rawValue] = _penSet.color as AnyObject?
            penSetDictionary[FTRackPersistanceKey.PenSet.preciseSize.rawValue] = _penSet.preciseSize as AnyObject?
        }
        standardUserDefaults.setValue(penSetDictionary, forKey: self.type.persistencekey)
        standardUserDefaults.synchronize()
        if self.userActivity?.userInfo == nil {
            self.userActivity?.userInfo = [AnyHashable:Any]()
        }
        self.userActivity?.userInfo?[self.type.persistencekey] = penSetDictionary
    }

    private func getCurrentPenInfo(using rackDict: FTRackInfoModel) -> FTPenSetProtocol {
        var penset: FTPenSetProtocol = FTDefaultPenSet()
        guard let type = FTPenType(rawValue: rackDict.lastSelectedPenType) else {
            return penset
        }
        var color: String?
        var size: CGFloat?
        
        if type == .caligraphy {
            color = self.caligraphyPenInfo.favouriteColors.first(where: { $0.isSelected == true })?.color
            size = self.caligraphyPenInfo.favouriteSizes.first(where: { $0.isSelected == true })?.size
        } else if type == .pilotPen {
            color = self.pioletPenInfo.favouriteColors.first(where: { $0.isSelected == true })?.color
            size = self.pioletPenInfo.favouriteSizes.first(where: { $0.isSelected == true })?.size
        } else if type == .pencil {
            color = self.pencilInfo.favouriteColors.first(where: { $0.isSelected == true })?.color
            size = self.pencilInfo.favouriteSizes.first(where: { $0.isSelected == true })?.size
        } else {
            color = self.penInfo.favouriteColors.first(where: { $0.isSelected == true })?.color
            size = self.penInfo.favouriteSizes.first(where: { $0.isSelected == true })?.size
        }
        
        if let selColor = color, let selSize = size, let reqSize = FTPenSize(rawValue: Int(truncating: selSize as NSNumber)) {
            penset = FTPenSet(type: type, color: selColor, size: reqSize)
            penset.preciseSize = selSize
        }
        return penset
    }

    private func getCurrentHighlighterInfo(using rackDict: FTRackInfoModel) -> FTPenSetProtocol {
        var highlighter: FTPenSetProtocol = FTDefaultHighlighterSet()
        guard let type = FTPenType(rawValue: rackDict.lastSelectedHighlighterType) else {
            return highlighter
        }
        var color: String?
        var size: CGFloat?

        if type == .flatHighlighter {
            color = self.flatHighlighterInfo.favouriteColors.first(where: { $0.isSelected == true })?.color
            size = self.flatHighlighterInfo.favouriteSizes.first(where: { $0.isSelected == true })?.size
        }  else {
            color = self.highlighterInfo.favouriteColors.first(where: { $0.isSelected == true })?.color
            size = self.highlighterInfo.favouriteSizes.first(where: { $0.isSelected == true })?.size
        }

        if let selColor = color, let selSize = size, let reqSize = FTPenSize(rawValue: Int(truncating: selSize as NSNumber)) {
            highlighter = FTPenSet(type: type, color: selColor, size: reqSize)
            highlighter.preciseSize = selSize
        }
        return highlighter
    }

    private func getCurrentPresenterInfo(using rackDict: FTRackInfoModel) -> FTPenSetProtocol {
        var presenter: FTPenSetProtocol = FTDefaultPresenterSet()
        let presenterInfo = rackDict.presenterInfo
        if let selPresenterInfo = presenterInfo.types.first(where: { $0.isSelected == true }) {
            if let type = FTPenType(rawValue: selPresenterInfo.type), let selPenColor = presenterInfo.penColors.first(where: { $0.isSelected == true }), let selPointerColor = presenterInfo.pointerColors.first(where: { $0.isSelected == true }) {
                presenter = FTPresenterSet(presenterType: type, pointerColor: selPointerColor.color, penColor: selPenColor.color)
            }
        }
        return presenter
    }
}
