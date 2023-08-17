//
//  FTShelfItemContextualMenuViewModel.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 07/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
class FTShelfItemContextualMenuViewModel: ObservableObject {
    @Published var performAction: FTShelfItemContexualOption?
    @Published var shelfItem: FTShelfItemViewModel?
}
