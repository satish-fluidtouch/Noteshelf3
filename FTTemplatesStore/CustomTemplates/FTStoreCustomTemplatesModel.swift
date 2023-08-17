//
//  FTStoreCustomTemplatesModel.swift
//  TempletesStore
//
//  Created by Siva on 26/04/23.
//

import Foundation

struct FTStoreCustomTemplatesModel: Codable, Hashable {

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: FTStoreCustomTemplatesModel, rhs: FTStoreCustomTemplatesModel) -> Bool {
        return lhs.id == rhs.id
    }
    let id = UUID()
    var templates: [FTTemplateStyle]
    enum CodingKeys: String, CodingKey {
        case templates
    }
}
