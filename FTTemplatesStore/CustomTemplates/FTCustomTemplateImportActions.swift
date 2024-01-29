//
//  FTCustomTemplateObserver.swift
//  TempletesStore
//
//  Created by Siva on 21/03/23.
//

import Foundation
import Combine
import UIKit

enum FTCustomTemplateImportActions {
    case photoLibrary
    case takePhoto
    case files
}

enum FTCustomTemplateImportConverter {
    case convertToPDF(filePath: String)
    case generatePDF(images: [UIImage])
}

enum FTCustomTemplateImportConverterOutput {
    case importedFileUrl(url: URL?, error: Error?)
    case createNootbookOutput(url: URL?, error: Error?)
}

final class FTCustomTemplateImportManager {
    var actionStream = PassthroughSubject<FTCustomTemplateImportActions, Never>()
    var importConverterInput = PassthroughSubject<FTCustomTemplateImportConverter, Never>()
    var importConverterOutput = PassthroughSubject<FTCustomTemplateImportConverterOutput, Never>()

    var cancellables = Set<AnyCancellable>()

}
