//
//  FTPresenterShortcutViewModel.swift
//  Noteshelf3
//
//  Created by Narayana on 01/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTPresenterShortcutViewModel: ObservableObject {
    private let rackData: FTRackData
    private var currentPenset: FTPresenterSetProtocol = FTDefaultPresenterSet()

    private(set) var laserPenColors: [String] = []
    private(set) var laserPointerColor: String = "DC1206"

    @Published private(set) var selectedPresenterType: FTPresenterType = .pointer
    @Published private(set) var currentSelectedColor: String = ""

    private weak var delegate: FTPresenterShortcutDelegate?

    // MARK: Initialization
    init(rackData: FTRackData, delegate: FTPresenterShortcutDelegate?) {
        self.rackData = rackData
        self.delegate = delegate
        if let presenterset = self.rackData.currentPenset as? FTPresenterSetProtocol {
            self.currentPenset = presenterset
            self.currentSelectedColor = presenterset.color
        }
    }

    func fetchPresenterData() {
        self.laserPenColors = self.rackData.laserPenColors
        if let pointerColor = self.rackData.laserPointerColors.first {
            self.laserPointerColor = pointerColor
        }
        if self.currentPenset.type == .laser {
            self.selectedPresenterType = .pen
        } else {
            self.selectedPresenterType = .pointer
        }
    }

    func saveSelection(type: FTPresenterType, color: String) {
        self.currentSelectedColor = color
        if type == .pen {
            self.selectedPresenterType = .pen
            self.currentPenset.type = .laser
            self.currentPenset.penColor = color
        } else {
            self.selectedPresenterType = .pointer
            self.currentPenset.type = .laserPointer
            self.currentPenset.pointerColor = color
        }
        self.delegate?.didChangeCurrentPresenterSet(self.currentPenset)
    }

    func handlePresentationOptionTap(option: FTPresenterModeOption) {
        self.delegate?.didTapPresentationOption(option)
    }
}
