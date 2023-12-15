//
//  FTShelfDisplayStyle.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 19/06/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

public enum FTShelfDisplayStyle: Int {
    case Gallery, Icon, List;
    
    var displayTitle: String {
        switch self {
        case .Gallery:
            return "shelf.view.largeNotebooks".localized
        case .Icon:
            return "shelf.view.smallNotebooks".localized
        case .List:
            return "shelf.view.list".localized
        }
    }
    
    var iconName: String {
        switch self {
        case .Gallery:
            return "squareshape.split.2x2"
        case .Icon:
            return "squareshape.split.3x3"
        case .List:
            return "list.bullet"
        }
    }
    
    var shelfItemSize: CGSize {
        switch self {
        case .Gallery:
            return CGSize(width: 259, height: 399);
        case .Icon:
            return CGSize(width: 165, height: 269);
        case .List:
            return CGSize(width: 165, height: 88);
        }
    }
    
    static var supportedStyles: [FTShelfDisplayStyle] {
        return [.Gallery,.Icon,.List];
    }
    
    private static var cachedDefaults: UserDefaults?

    private static var ftDefaults: UserDefaults {
        if let defaults = cachedDefaults {
            return defaults
        } else {
            let newDefaults = FTUserDefaults.defaults()
            cachedDefaults = newDefaults
            return newDefaults
        }
    }

    static var displayStyle : FTShelfDisplayStyle {
        get {
            let style = ftDefaults.integer(forKey: "displayStyle")
            return FTShelfDisplayStyle(rawValue: style) ?? .Gallery;
        }
        set {
            ftDefaults.setValue(newValue.rawValue, forKey: "displayStyle");
        }
    }
}

#if targetEnvironment(macCatalyst)
extension FTShelfDisplayStyle {
    var menuIdentifier: UIAction.Identifier {
        switch self {
        case .Gallery:
            return UIAction.Identifier("shelfDisplayGallery");
        case .Icon:
            return UIAction.Identifier("shelfDisplayIcon");
        case .List:
            return UIAction.Identifier("shelfDisplayList");
        }
    }
    
    var menuItem: UIKeyCommand {
        var command: UIKeyCommand;
        switch self {
        case .Gallery:
            command = UIKeyCommand(title: self.displayTitle,
                                    image: nil,
                                    action: #selector(FTMenuActionResponder.viewAsGallery(_:)),
                                    input: "1",
                                    modifierFlags: [.command],
                                    propertyList: nil)
        case .Icon:
            command = UIKeyCommand(title: self.displayTitle,
                                    image: nil,
                                    action: #selector(FTMenuActionResponder.viewAsIcon(_:)),
                                    input: "2",
                                    modifierFlags: [.command],
                                    propertyList: nil)
        case .List:
            command = UIKeyCommand(title: self.displayTitle,
                                    image: nil,
                                    action: #selector(FTMenuActionResponder.viewAsList(_:)),
                                    input: "3",
                                    modifierFlags: [.command],
                                    propertyList: nil)
        }
        return command;
    }
}
#endif
