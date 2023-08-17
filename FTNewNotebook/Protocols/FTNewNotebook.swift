//
//  FTNewNotebook.swift
//  FTNewNotebook
//
//  Created by Ramakrishna on 21/02/23.
//

import UIKit

public protocol FTPasswordDelegate: NSObject {
    func didTapSavePasswordWith(pin: String,hint: String, useBiometric: Bool)
    func didTapCancelPassword()
}
public protocol FTPaperThumbnailGenerator {
    func generateThumbnailFor(selectedVariantsAndTheme: FTSelectedPaperVariantsAndTheme,forPreview:Bool,completionhandler: @escaping (_ thumbImage : UIImage?)->())
    func generateThumbnail(theme: FTThemeable,completionhandler: @escaping (_ thumbImage : UIImage?)->());
    func generateThumbnail(theme: FTThemeable) async -> UIImage?
}
