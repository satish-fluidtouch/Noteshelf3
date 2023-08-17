//
//  FTSidebarTopSectionViewModel.swift
//  NewShelfSidebar
//
//  Created by Ramakrishna on 13/04/23.
//

import Foundation
class FTSidebarTopSectionViewModel: ObservableObject {
    func didTapItem(_ item: SidebarTopSectionElement){
        print("Tapped", item.displayTitle)
    }
    func didTapTemplates(){
        print("Tapped Templates")
    }
}
