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
    
    override var type: FTSidebarSectionType {
        return .tags;
    }
    
    required init() {
        super.init();
        self.prepareItems();
        notificationObserver =  NotificationCenter.default.addObserver(forName: .didUpdateTags, object: nil, queue: .main) { [weak self] notification in
            guard let strongSelf = self else {
                return
            }
            let tags = FTTagsProvider.shared.getTags(true, sort: true);
            var itemsToRefresh = [FTSideBarItem]();
            for i in 0..<tags.count {
                let eachTag = tags[i];
                if let item = strongSelf.items.first(where: {$0.id == eachTag.id}) {
                    item.title = eachTag.tagDisplayName;
                    itemsToRefresh.insert(item, at: i)
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
//        super.title = tag.tagDisplayName;
        self.id = tag.id;
    }
}
