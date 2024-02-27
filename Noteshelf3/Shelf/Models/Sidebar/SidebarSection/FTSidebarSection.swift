//
//  FTSidebarSection.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 09/05/22.
//

import Foundation
class FTSidebarSection: FTSectionDisplayable, Identifiable, ObservableObject {
    
    var type: FTSidebarSectionType {
        return .all;
    }
    
    var id = UUID().uuidString
    
    var title: String {
        type.displayTitle ?? ""
    }
    
    @Published var isExpanded = true {
        didSet {
            if isExpanded != oldValue {
                FTUserDefaults.defaults().set(isExpanded, forKey: self.isExpandedKey);
            }
        }
    }
    
    private var isExpandedKey: String {
        return "isExpanded_\(type.rawValue)";
    }
    var supportsRearrangeOfItems: Bool {
        return false;
    }
    
    @Published var items: [FTSideBarItem] = [];
        
    required init() {
        self.items = items
        if type != .all {
            FTUserDefaults.defaults().register(defaults: [self.isExpandedKey : NSNumber(booleanLiteral: true)])
            self.isExpanded = FTUserDefaults.defaults().bool(forKey: self.isExpandedKey)
        }
    }
    
    func addObservers() {
        
    }
    
    func removeObservers() {
        
    }
    
    func fetchItems() {
        
    }
    
    func finaliseEdit() {
        for index in 0..<self.items.count {
            self.items[index].isEditing = false
        }
    }

    func finaliseHightlight() {
        for index in 0..<self.items.count {
            self.items[index].highlighted = false
        }
    }
        
    func moveItem(fromOrder: Int, toOrder: Int) -> Bool {
        if !self.items.isEmpty {
            let movePos = min(max(toOrder,0),self.items.count-1);
            self.items.move(fromOffsets: IndexSet(integer: fromOrder), toOffset: movePos);
            return true;
        }
        return false;
    }
    
    func removeItem(at index: Int) {
        self.items.remove(at: index);
    }
    
    func addItem(_ item: FTSideBarItem) {
        self.items.append(item);
    }
}
