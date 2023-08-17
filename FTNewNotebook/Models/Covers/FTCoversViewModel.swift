//
//  FTCoversViewModel.swift
//  FTNewNotebook
//
//  Created by Narayana on 28/02/23.
//

import UIKit

class FTCoversViewModel: NSObject {
    private(set) var coversSections: [FTCoverSectionModel] = []
    private(set) var variantsData: [FTCoverVariantModel] = []
    private(set) weak var delegate: FTCoversInfoDelegate?

    init(with delegate: FTCoversInfoDelegate?) {
        self.delegate = delegate
        super.init()
    }

    func prepareData() {
        if var noCoverSection = self.getNoCoverSection() {
            noCoverSection.sectionType = .noCover
            self.coversSections.append(noCoverSection)
        }
        var customCoverSection = self.getCustomCoverSection()
        customCoverSection.sectionType = .custom
        self.coversSections.append(customCoverSection)

        self.coversSections.removeAll { model in
            model.sectionType == .standard
        }
        if let sections = self.delegate?.fetchCoversData() {
            self.coversSections.append(contentsOf: sections)
            sections.forEach { sectionModel in
                variantsData.append(FTCoverVariantModel(name: sectionModel.name, imageName: sectionModel.variantImageName))
            }
        }
    }

    private func getNoCoverSection() -> FTCoverSectionModel? {
        if let theme = self.delegate?.fetchNoCoverTheme() {
            let noCoverSection = FTCoverSectionModel(name: "covers.category.noCover".localized, covers: [theme], imageName: "")
            return noCoverSection
        }
        return nil
    }

    private func getCustomCoverSection() -> FTCoverSectionModel {
        return FTCoverSectionModel(name: "covers.category.custom".localized, covers: [], imageName: "test_custom")
    }
}

class FTCurrentCoverSelection: NSObject {
    static let shared = FTCurrentCoverSelection()
    var selectedCover: FTThemeable?
    private override init() { // singleton, shared across many places
    }
}
