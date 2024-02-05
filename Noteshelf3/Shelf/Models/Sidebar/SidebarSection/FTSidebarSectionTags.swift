//
//  FTSidebarSectionTags.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 12/01/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTSidebarSectionTags: FTSidebarSection {
    private var notificationObserver: NSObjectProtocol?;
    
    override var supportsRearrangeOfItems: Bool {
        get {
            return false
        }
        set {
        }
    }
    
    override var type: FTSidebarSectionType {
        get {
            .tags;
        }
        set {}
    }
    
    init() {
        super.init(type: .media, items: [], supportsRearrangeOfItems: false);
        self.prepareItems();
        notificationObserver =  NotificationCenter.default.addObserver(forName: .didUpdateTags, object: nil, queue: .main) { [weak self] notification in
            guard let strongSelf = self else {
                return
            }
            let tags = FTTagsProvider.shared.getTags(true, sort: true);
            let currentTags = (strongSelf.items as! [FTSideBarItemTag]).compactMap{$0.fttag};
            
            let tagsToDelete = Set(currentTags).subtracting(Set(tags));
            
            var itemsToRefresh = [FTSideBarItem]();
            itemsToRefresh.append(contentsOf: strongSelf.items);
            itemsToRefresh.removeAll(where: {tagsToDelete.contains(($0 as! FTSideBarItemTag).fttag)})
            
            for i in 0..<tags.count {
                let eachTag = tags[i];
                if let item = strongSelf.items.first(where: {$0.id == eachTag.id}) {
                    item.title = eachTag.tagDisplayName;
                }
                else {
                    let item = FTSideBarItemTag(tag: eachTag);
                    itemsToRefresh.insert(item, at: i)
                }
            }
            self?.items.removeAll();
            self?.items.append(contentsOf: itemsToRefresh);
        }
    }
    
    deinit {
        if let observer = self.notificationObserver {
            NotificationCenter.default.removeObserver(observer, name: .didUpdateTags, object: nil);
            self.notificationObserver = nil;
        }
    }
    
    required init(type: FTSidebarSectionType, items: [FTSideBarItem], supportsRearrangeOfItems: Bool) {
        fatalError("init(type:items:supportsRearrangeOfItems:) has not been implemented")
    }
}

private extension FTSidebarSectionTags {
    func prepareItems() {
        var sideBartags = [FTSideBarItem]();
        
        let tags = FTTagsProvider.shared.getTags(true, sort: true);
        tags.forEach { eachTag in
            let item = FTSideBarItemTag(tag: eachTag);
            sideBartags.append(item);
        }
        self.items = sideBartags;
    }
}

class FTSideBarItemTag: FTSideBarItem {
    private(set) var fttag: FTTag;
    override var title: String {
        get { return fttag.tagDisplayName; }
        set{}
    }
    override var icon: FTIcon {
        get {
            return .number;
        }
        set{}
    }
    
    override var type: FTSideBarItemType {
        get {
            return (fttag.tagType == .allTag) ? .allTags : .tag;
        }
        set {}
    }
    
    init(tag: FTTag) {
        fttag = tag;
        super.init();
        super.title = tag.tagDisplayName;
        self.id = tag.id;
    }
}
