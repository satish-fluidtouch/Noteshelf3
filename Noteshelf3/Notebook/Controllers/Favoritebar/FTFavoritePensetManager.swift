//
//  FTFavoritebarManager.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 29/09/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

private let favoriteKey = "FTDefaultFavoriteInfo"
private let currentFavMode = "FTFavoriteCurrentMode"

class FTFavoritePensetManager: NSObject {
    let dataManager = FTFavoritePensetDataManager()
    private let userActivity: NSUserActivity?
    private var _currentPenSet: FTPenSetProtocol!

    init(activity: NSUserActivity?) {
        self.userActivity = activity
    }

    func removeDuplicates(fromFavPenSets penSets: [FTPenSetProtocol]) -> (uniqueElements: [FTPenSetProtocol], duplicateExists: Bool) {
        var result = [FTPenSetProtocol]()
        var duplicateExists = false
        for value in penSets {
            if let _ = result.firstIndex(where: {$0.isEqualTo(value)}) {
                duplicateExists = true
            } else {
                result.append(value)
            }
        }
        return (result, duplicateExists)
    }

    func fetchFavorites() -> [FTPenSetProtocol] {
        let favorites = dataManager.fetchFavorites().favorites
        let favs = favorites.compactMap(({$0.getPenset()}))
        return favs
    }

    func saveFavorites(_ favorites: [FTPenSetProtocol]) {
        var dataModel = dataManager.fetchFavorites()
        dataModel.favorites = favorites.compactMap({ penset in
            FTFavoritePenInfo(type: penset.type.rawValue, color: penset.color, size: CGFloat(penset.size.rawValue), preciseSize: String(Float(penset.preciseSize)))
        })
        self.dataManager.saveFavorites(dataModel)
    }

    public func fetchCurrentPenset() -> FTPenSetProtocol {
        let prevRackMode = self.fetchCurrentFavoriteMode()
        if prevRackMode == .pen {
            return self.fetchCurrentPenset(for: .pen)
        } else {
            return self.fetchCurrentPenset(for: .highlighter)
        }
    }

    func fetchCurrentFavoriteMode() -> FTRackType {
        if let prevInfo = self.userActivity?.userInfo?[currentFavMode] as? [String: Any], let rackRawValue = prevInfo[currentFavMode] as? NSNumber {
            if let type = FTRackType(rawValue: Int(truncating: rackRawValue)) {
                return type
            }
        } else {
            let standardUserDefaults = UserDefaults.standard
            let rackRawValue = standardUserDefaults.integer(forKey: currentFavMode)
            if let type = FTRackType(rawValue: Int(truncating: rackRawValue as NSNumber)) {
                return type
            }
        }
        return .pen
    }

    public func fetchCurrentPenset(for segment: FTFavoriteRackSegment) -> FTPenSetProtocol {
        let key = getFavoriteKey(for: segment.rackType)
        guard let curPenset = getCurrentPenSet(for: key) else {
            // This will be executed only once
            if let penset = fetchFavorites().first {
                // To avoid first time issue of segment change(The other rack type current pen set is saved as default penset)
                if penset.type.rackType == .pen {
                    saveCurrentSelection(penSet: FTDefaultHighlighterSet())
                } else {
                    saveCurrentSelection(penSet: FTDefaultHighlighterSet())
                }
                saveCurrentSelection(penSet: penset)
                return penset // recent saved penset ll be available
            } else { // this is for safe check, ll never be executed
                let penset: FTPenSetProtocol = (segment == .pen) ? FTDefaultPenSet() : FTDefaultHighlighterSet()
                saveCurrentSelection(penSet: penset)
                return penset
            }
        }
        return curPenset
    }

    public func saveCurrentSelection(penSet: FTPenSetProtocol) {
        var currentPenSet: [String: AnyObject] = [:]
        currentPenSet[FTRackPersistanceKey.PenSet.size.rawValue] = penSet.size.rawValue as AnyObject?
        currentPenSet[FTRackPersistanceKey.PenSet.type.rawValue] = penSet.type.rawValue as AnyObject?
        currentPenSet[FTRackPersistanceKey.PenSet.color.rawValue] = penSet.color as AnyObject?
        currentPenSet[FTRackPersistanceKey.PenSet.preciseSize.rawValue] = penSet.preciseSize as AnyObject?
        self.saveCurrentPenSetInfForQuickAccess(penSet)
    }
}

private extension FTFavoritePensetManager {
    private func getFavoriteKey(for rackType: FTRackType) -> String {
        let key = favoriteKey + rackType.persistencekey
        return key
    }

    private func getCurrentPenSet(for key: String) -> FTPenSetProtocol? {
        if let penSet = self.currentPenSetFromUserActivity(for: key) {
            return penSet
        }
        else if let penSet = self.currentPenSetFromUserdefaults(for: key) {
            self.saveCurrentPenSetInfForQuickAccess(penSet)
            return penSet
        }
        return nil
    }

    private func currentPenSetFromUserActivity(for key: String) -> FTPenSetProtocol? {
        if let penSetInfo = self.userActivity?.userInfo?[key] as? [String: Any] {
            return self.loadCurrentPenSet(info: penSetInfo)
        }
        return nil
    }

    private func currentPenSetFromUserdefaults(for key: String) -> FTPenSetProtocol? {
        let standardUserDefaults = UserDefaults.standard
        if let penSetDictionary = standardUserDefaults.value(forKey: key) as? [String: Any] {
            return self.loadCurrentPenSet(info: penSetDictionary)
        }
        return nil
    }

    private func loadCurrentPenSet(info: [String: Any]) -> FTPenSetProtocol {
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

    func saveCurrentPenSetInfForQuickAccess(_ penSet : FTPenSetProtocol?) {
        guard let _penSet = penSet else { return  }
        let standardUserDefaults = UserDefaults.standard
        var penSetDictionary = [String: Any]()
        penSetDictionary[FTRackPersistanceKey.PenSet.size.rawValue] = _penSet.size.rawValue as AnyObject?
        penSetDictionary[FTRackPersistanceKey.PenSet.type.rawValue] = _penSet.type.rawValue as AnyObject?
        penSetDictionary[FTRackPersistanceKey.PenSet.color.rawValue] = _penSet.color as AnyObject?
        penSetDictionary[FTRackPersistanceKey.PenSet.preciseSize.rawValue] = _penSet.preciseSize as AnyObject?
        let key = self.getFavoriteKey(for: _penSet.type.rackType)
        standardUserDefaults.setValue(penSetDictionary, forKey: key)
        standardUserDefaults.setValue(_penSet.type.rackType.rawValue, forKey: currentFavMode)

        standardUserDefaults.synchronize()
        if self.userActivity?.userInfo == nil {
            self.userActivity?.userInfo = [AnyHashable:Any]()
        }
        self.userActivity?.userInfo?[key] = penSetDictionary
        self.userActivity?.userInfo?[currentFavMode] = [currentFavMode : _penSet.type.rackType.rawValue]
    }
}
