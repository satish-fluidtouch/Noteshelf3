//
//  FTStoryBoard.swift
//  Noteshelf3
//
//  Created by Sameer on 21/07/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit

enum FTStoryboard : String {
    case finder = "FTFinderUI"
    case documentEntity = "FTDocumentEntity"
    case notebookSettings = "FTNoteBookSettings"
    
    var instance: UIStoryboard {
        
        return UIStoryboard(name: self.rawValue, bundle: Bundle.main)
    }
    
    func viewController<T: UIViewController>(viewControllerClass: T.Type, function: String = #function, line: Int = #line, file: String = #file) -> T {
        
        let storyboardID = (viewControllerClass as UIViewController.Type).storyboardID
         
        guard let scene = instance.instantiateViewController(withIdentifier: storyboardID) as? T else {
            
            fatalError("ViewController with identifier \(storyboardID), not found in \(self.rawValue) Storyboard.\nFile : \(file) \nLine Number : \(line) \nFunction : \(function)")
        }
        
        return scene
    }
    
    func initialViewController() -> UIViewController? {
        
        return instance.instantiateInitialViewController()
    }
}

extension UIViewController {
    
    // Not using static as it wont be possible to override to provide custom storyboardID then
    class var storyboardID: String {
        
        return "\(self)"
    }
    
    static func instantiate(fromStoryboard storyboard: FTStoryboard) -> Self {
        
        return storyboard.viewController(viewControllerClass: self)
    }
}
