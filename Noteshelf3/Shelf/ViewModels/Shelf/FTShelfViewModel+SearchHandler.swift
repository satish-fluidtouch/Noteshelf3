//
//  FTShelfViewModel+SearchHandler.swift
//  Noteshelf3
//
//  Created by Narayana on 28/11/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

extension FTShelfViewModel {
    func searchTapped() {
        self.delegate?.showGlobalSearchController()
    }
}
