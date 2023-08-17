 //
//  FTShelfToolbarAppearance.swift
//  Noteshelf
//
//  Created by Amar on 11/5/16.
//
//

import Foundation
import UIKit

@objc enum FTToolbarStyle : Int
{
    case normal
    case group
    case trash
}

@objc enum FTToolbarMode : Int
{
    case normal
    case edit
}

@objc enum FTToolbarActionType : Int
{
    case addNotebook
    case options
    case share
    case edit
    case evernoteError
    case dropboxError
    case moveDocuments
    case deleteDocuments
    case changeCover
    case duplicateDocuments
    case showCategories
    case emptyTrash
    case watchRecordings
    case search
    case selectAll
    case rename
    case group
    case restore
    case more
}

@objc protocol FTShelfToolbarActionDelegate : NSObjectProtocol
{
    func toolbarPerformAction(_ actionType : FTToolbarActionType,
                                actionView : UIView);
}
 
@objc protocol FTShelfToolbarAppearance:  NSObjectProtocol {
    var delegate: FTShelfToolbarActionDelegate? {get set}
    
    var titleLabel: ActionLabel? {get}
    var sceneTitle: String? {get set}
    var toolbarMode : FTToolbarMode {get}
    var toolbarStyle : FTToolbarStyle {get set}
    var categoryActionLabel : ActionLabel? {get set}

    func didTappedOnAction(_ actionType : FTToolbarActionType,sender : UIView)
    func updateNumberOfItemsSelected(_ itemsCount : Int, totalItems: Int)
    func enterMode(_ mode : FTToolbarMode)
    func exitCurrentMode()
    func enableEmptyTrashButton(status: Bool)
    func validateButtons()
}
 
extension UISearchBar {
    
    private func getViewElement<T>(type: T.Type) -> T? {
        
        let svs = subviews.flatMap { $0.subviews }
        guard let element = svs.first(where: { $0 is T }) as? T else { return nil }
        return element
    }
    
    func setTextFieldColor(color: UIColor) {
        
        if let textField = getViewElement(type: UITextField.self) {
            switch searchBarStyle {
            case .minimal:
                textField.layer.backgroundColor = color.cgColor
                textField.layer.cornerRadius = 10
                
            case .prominent, .default:
                textField.backgroundColor = color
            }
        }
    }
}
