//
//  GetInspiredModel.swift
//  Noteshelf3
//
//  Created by Rakesh on 02/05/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import PDFKit

class FTGetInspiredResponseModel : Codable {
    var getInspitedList: [FTInspireItem]
}

class FTInspireItem: Codable,Hashable {

    var imageName: String
    var pdfName: String
    let titleLocalizationKey: String

    static func ==(lhs: FTInspireItem, rhs: FTInspireItem) -> Bool {
          return
              lhs.pdfName == rhs.pdfName &&
              lhs.titleLocalizationKey == rhs.titleLocalizationKey
      }

    func hash(into hasher: inout Hasher) {
          hasher.combine(pdfName)
      }
}

class GetInspiredDatasource: NSObject {
    class func loadData() -> FTGetInspiredResponseModel {
        guard let infoPlistPath = Bundle.main.url(forResource: "GetInspired", withExtension: "plist") else {
            fatalError("Plist URL Path not found")
        }
        do {
            let infoPlistData = try Data(contentsOf: infoPlistPath)
            return try PropertyListDecoder().decode(FTGetInspiredResponseModel.self, from: infoPlistData)
        } catch {
            fatalError("Error in data parsing")
        }
    }
}

extension FTInspireItem {
    var getinspireImage: UIImage {
        return UIImage(contentsOfFile: self.imageName) ?? UIImage()
    }
    func getPreviewUrl(fileName: String) -> URL? {
        return Bundle.main.url(forResource: fileName, withExtension: "bundle")
    }
}
