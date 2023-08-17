//
//  FTCustomCoversViewModel.swift
//  FTNewNotebook
//
//  Created by Narayana on 01/03/23.
//

import UIKit

enum FTDefaultCustomType: String, CaseIterable {
    case unsplash
    case camera
    case photoLibrary

    var displayName: String {
        let title: String
        switch self {
        case .unsplash:
            title = "Unsplash"
        case .camera:
            title = "Camera".localized
        case .photoLibrary:
            title = "PhotoLibrary".localized
        }
        return title
    }

    var image: UIImage? {
        let image: UIImage?
        switch self {
        case .unsplash:
            image = UIImage(named: "unsplash", in: currentBundle, with: nil)
        case .camera:
            image = UIImage(named: "camera", in: currentBundle, with: nil)
        case .photoLibrary:
            image = UIImage(named: "photoLibrary", in: currentBundle, with: nil)
        }
        return image
    }
}

struct FTDefaultCustomSection {
    let type: FTDefaultCustomType
}

class FTCustomCoversViewModel: NSObject {
    private(set) var defaultSections: [FTDefaultCustomSection] = []
    private(set) var recentCovers: [FTCoverThemeModel] = []

    private weak var delegate: FTCustomCoverInfoDelegate?
    private(set) var selectedImage: UIImage?

    init(with delegate: FTCustomCoverInfoDelegate?) {
        self.delegate = delegate

        super.init()
        FTDefaultCustomType.allCases.forEach { type in
            self.defaultSections.append(FTDefaultCustomSection(type: type))
        }
        if let recents = self.delegate?.fetchRecentCoversData() {
            self.recentCovers = recents
        }
    }

    func updateSelectedImage(_ image: UIImage) {
        self.selectedImage = image
    }

    @discardableResult
    func generateCoverTheme(image: UIImage, coverType: FTCoverSelectedType) -> FTThemeable? {
        return self.delegate?.generateCoverTheme(image: image, coverType: coverType)
    }
}
