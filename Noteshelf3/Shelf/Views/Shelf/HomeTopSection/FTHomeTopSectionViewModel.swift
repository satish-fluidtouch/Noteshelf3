//
//  FTHomeTopSectionViewModel.swift
//  DynamicGridView
//
//  Created by Rakesh on 12/04/23.
//

import Foundation

final class FTHomeTopSectionViewModel:ObservableObject{
    func didTapItem(_ item: FTShelfHomeTopSectionModel){
        print("Tapped", item.displayTitle)
    }
    
}
