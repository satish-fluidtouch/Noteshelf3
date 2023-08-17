//
//  FTStoreLibraryModel.swift
//  TempletesStore
//
//  Created by Siva on 16/03/23.
//

import Foundation

struct FTStoreLibraryModel: Codable, Hashable {

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: FTStoreLibraryModel, rhs: FTStoreLibraryModel) -> Bool {
        return lhs.id == rhs.id
    }
    let id = UUID()
    var templates: [FTTemplateStyle]
    enum CodingKeys: String, CodingKey {
        case templates
    }
}
