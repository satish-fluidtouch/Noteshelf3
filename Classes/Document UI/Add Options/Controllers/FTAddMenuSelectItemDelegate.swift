//
//  FTAddMenuSelectItemDelegate.swift
//  Noteshelf
//
//  Created by srinivas on 06/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTCommon

enum CameraType {
    case pageFromCamera
    case takePhoto
}

protocol FTAddMenuPHPickerDelegate: AnyObject {
    func didSelectPhotoLibrary(menuItem: PhotoType)
}

protocol FTAddMenuCameraDelegate: AnyObject {
    func didSelectCamera(_ cameraType: CameraType)
}


protocol Selectable {
    func didSelect()
}

protocol PHPickerProtocal {
    var cellPressed: ((String) -> Void)? { get set }
}

protocol AddMenuProtocal {
    var image: UIImage? { get }
    var name: String { get }
    var discloser: Bool { get set }
    func didSelect()
}

class PhotoTemplate: AddMenuProtocal, PHPickerProtocal {
    
    var cellPressed: ((String) -> Void)?
    
    var image: UIImage?
    let name: String
    var discloser: Bool
    
    init(image: UIImage, name: String, discloser: Bool = false) {
        self.image = image
        self.name = name
        self.discloser = discloser
    }
    
    func didSelect() {
       
    }
    
}
var cellPressed: (() -> Void)?


struct PhotoLibrary: AddMenuProtocal, PHPickerProtocal {
    
    var cellPressed: ((String) -> Void)?
    
    var image: UIImage?
    var name: String
    var discloser: Bool
    
    func didSelect() {
    }
}

struct Page: AddMenuProtocal {
    
    var image: UIImage?
    var name: String
    var discloser: Bool
    
    func didSelect() {
        debugPrint("didSelect")
    }
}

struct WebClip: AddMenuProtocal {
    
    var image: UIImage?
    var name: String
    var discloser: Bool
    
    func didSelect() {
        
    }
}
