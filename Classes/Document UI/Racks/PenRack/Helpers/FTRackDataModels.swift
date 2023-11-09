//
//  FTRackDataProvider.swift
//  FTPenRack
//
//  Created by Siva on 08/04/17.
//  Copyright © 2017 Fluid Touch Pvt Ltd. All rights reserved.
//

import UIKit
import Foundation

@objc public enum FTRackType: Int {
    case pen
    case highlighter
    case eraser
    case text
    case shape
    case presenter

    public var displayName: String {

        switch self {
        case .pen:
            return "PEN"
        case .highlighter:
            return "Highlighter"
        case .eraser:
            return "Eraser"
        case .shape:
            return "SHAPES"
        default:
            return ""
        }
    }

   public var persistencekey: String {
        switch self {
        case .pen:
            return "FTDefaultPenRack";
        case .highlighter:
            return "FTDefaultHighlighterRack";
        case .eraser:
            return "FTDefaultEraserRack";
        case .text:
            return "Text"
        case .shape:
            return "FTDefaultShapeRack"
        case .presenter:
            return "FTDefaultPresenterRack"
        }
    }
    
    var penTypes : [FTPenType] {
        var pens = [FTPenType]();
        switch self {
        case .pen:
            pens = [.pen, .caligraphy, .pilotPen, .pencil];
        case .highlighter:
            pens = [.flatHighlighter, .highlighter];
        case .shape:
            pens = [.pen,.caligraphy,.pilotPen,.pencil,.flatHighlighter,.highlighter];
        case .presenter:
            pens = [.pen];
        default:
            break;
        }
        return pens;
    }
    
    var shapeTypes: [FTShapeType] {
        //.dashLine,
        return [.freeForm, .line, .arrow, .doubleArrow, .rectangle, /*.roundedRect,*/ .ellipse, .triangle, .rombus, .paralalleogram, .pentagon]
    }

    var favoriteShapeTypes: [FTShapeType] {
        var shapeTypes: [FTShapeType] = []
        if let userFavorites = FTUserDefaults.defaults().array(forKey: "favoriteShapes") as? [Int] {
            for fav in userFavorites {
                if let shapeType = FTShapeType(rawValue: fav) {
                    shapeTypes.append(shapeType)
                }
            }
        }
        if shapeTypes.isEmpty {
            shapeTypes = [FTShapeType.freeForm, FTShapeType.line, FTShapeType.rectangle]
            let rawValues = shapeTypes.map { type in
                type.rawValue
            }
            FTUserDefaults.defaults().set(rawValues, forKey: "favoriteShapes")
        }
        return shapeTypes
    }

    func saveFavoriteShapeTypes(shapes: [FTShapeType]) {
        let rawValues = shapes.map { type in
            type.rawValue
        }
        FTUserDefaults.defaults().set(rawValues, forKey: "favoriteShapes")
    }
}

extension FTRackType {
    var sizeRange: ClosedRange<CGFloat> {
        var range = CGFloat(0.0)...CGFloat(8.0)
        if self == .highlighter {
            range = CGFloat(1.0)...CGFloat(6.0)
        } else if self == .shape {
            range = CGFloat(1.0)...CGFloat(8.0)
        }
        return range
    }
}

 extension FTPenType {
    
    public var rackType : FTRackType
    {
        if(FTRackType.highlighter.penTypes.contains(self)) {
            return FTRackType.highlighter;
        }
        return FTRackType.pen;
    }

     var name: String {
         switch self {
             case .pilotPen:
             return "penRack.felt".localized
             case .caligraphy:
             return "penRack.fountain".localized
             case .pen:
             return "penRack.ballpoint".localized
             case .pencil:
             return "penRack.pencil".localized
             case .highlighter:
             return "highlighterRack.round".localized
             case .flatHighlighter:
             return "highlighterRack.flat".localized
             default:
                 return "Pen"
         }
     }
}

@objc public enum FTPenSize: Int, CaseIterable {
    case zero = 0
    case one = 1
    case two = 2
    case three = 3
    case four = 4
    case five = 5
    case six = 6
    case seven = 7
    case eight = 8

    private func highlighterDisplayPixel() -> CGFloat {
        switch self {
        case .zero:
            return 2.0
        case .one:
            return 4.0;
        case .two:
            return 10.0;
        case .three:
            return 16.0;
        case .four:
            return 20.0;
        case .five:
            return 24.0;
        case .six:
            return 28.0;
        default:
            return 28.0;
        }
    }
    
    func displayPixel(_ penType : FTPenType) -> CGFloat {
        
        if(penType == .highlighter || penType == .flatHighlighter) {
            return self.highlighterDisplayPixel();
        }
        
        switch self {
        case .zero:
            return 2.0
        case .one:
            return 4.0
        case .two:
            return 6.0
        case .three:
            return 8.0
        case .four:
            return 10.0
        case .five:
            return 12.0
        case .six:
            return 14.0
        case .seven:
            return 16.0
        case .eight:
            return 20.0
        }
    }
    
    func displayPixelSizeImageName(_ penType : FTPenType) -> String? {
        if(penType != .flatHighlighter) {
            return nil;
        }
        
        switch self {
        case .one, .zero:
            return "sizehighlighter1";
        case .two:
            return "sizehighlighter2";
        case .three:
            return "sizehighlighter3";
        case .four:
            return "sizehighlighter4";
        case .five:
            return "sizehighlighter5";
        case .six:
            return "sizehighlighter6";
        case .seven:
            return nil;
        case .eight:
            return nil;
        }
    }
    
    func imageName() -> String {
        switch self {
        //TODO: get zero size image
        case .one, .zero:
            return "1";
        case .two:
            return "2";
        case .three:
            return "3";
        case .four:
            return "4";
        case .five:
            return "5";
        case .six:
            return "6";
        case .seven:
            return "7";
        case .eight:
            return "8";
        }
    }
    
    func nibImage(forPenType penType: FTPenType) -> UIImage {
        let imageName = "PenRack/NibSize/" + penType.name + "/" + self.imageName();
        let image = UIImage(named: imageName);
        return image!;
    }
};

extension FTPenSize {

    func maxSizeForType(penType: FTPenType) -> Int {
        if penType == .highlighter || penType == .flatHighlighter {
          return FTPenSize.six.rawValue
        } else {
          return FTPenSize.eight.rawValue
        }
      }
    
    func maxDisplaySize(penType: FTPenType) -> CGFloat {
        if penType == .highlighter || penType == .flatHighlighter {
          return FTPenSize.six.highlighterDisplayPixel()
        } else {
          return FTPenSize.eight.displayPixel(penType)
        }
      }
    
    func imageFor(penType: FTPenType) -> UIImage {
        let size = maxSizeForType(penType: penType)
        return penType.imageForSize(size: size)
    }

    func scaleToApply(penType: FTPenType, preciseSize: CGFloat) -> CGFloat {
        let size = maxSizeForType(penType: penType)
        var scale = preciseSize/CGFloat(size)
        if preciseSize <= 0.2 {
            scale = 0.2/CGFloat(size)
        }
        return scale
    }
}

extension FTPenType {
    func imageForSize(size: Int) -> UIImage {
        let imagePrefix : String// = "PenSizes/Pen/pen"
        if self == .pen || self == .caligraphy || self == .pilotPen {
            imagePrefix = "PenSizes/Pen/pen"
        } else if self == .pencil {
            imagePrefix = "PenSizes/Pencil/pencil"
        } else if self == .highlighter {
            imagePrefix = "PenSizes/Highlighter/highlighter"
        } else if self == .flatHighlighter {
            imagePrefix = "PenSizes/FlatHighlighter/flathighlighter"
        } else {
            fatalError("There's no such pen")
        }
        //TODO: get zero size image
        let nameWithSize = "\(imagePrefix)_\(size == 0 ? 1 : size)"

        guard let image = UIImage(named: nameWithSize) else {
            fatalError("Appropriate image not found for this pen size")
        }
        return image
    }
}
