//
//  FTNewNotebookModel.swift
//  FTNewNotebook
//
//  Created by Ramakrishna on 23/02/23.
//

import Foundation
import UIKit

public struct FTNewNotebookModel {
    public var selectedCoverTheme: FTThemeable?
    public var selectedPaperWithVariants: FTSelectedPaperVariantsAndTheme
    public var passwordDetails: FTPasswordModel?
    public var title:String = ""
    public init(coverTheme: FTThemeable?,
                selectedPaperWithVariants: FTSelectedPaperVariantsAndTheme,
                passwordDetails: FTPasswordModel? = nil,
                title: String = "") {
        self.selectedCoverTheme = coverTheme
        self.selectedPaperWithVariants = selectedPaperWithVariants
        self.passwordDetails = passwordDetails
        self.title = title
    }
}

public enum FTThemeType {
    case cover
    case paper
}

public protocol FTThemeable {
    var displayName: String {get}
    var canDelete: Bool {get}
    var isCustom: Bool {get}
    var isRecent: Bool {get}
    var isFavorite: Bool {get}
    var themeFileURL: URL {get}
    var dynamicId: Int {get}
    var restrictsChangeTemplate: Bool {get}
    var hasCover: Bool{get}

    var eventTrackName: String {get}

    var id: String { get }

    func themeThumbnail() -> UIImage
    func preview() -> UIImage?
    func themeTemplateURL() -> URL
    func deleteThumbnailFromCache()
}
