//  OneDriveDemo
//
//  Created by Simhachalam Naidu on 17/09/19.
//  Copyright © 2019 Simhachalam Naidu. All rights reserved.
//


import Foundation
struct FTOneDriveUser : Codable {
    let email : String?
    let id : String?
    let displayName : String?
    
    enum CodingKeys: String, CodingKey {
        
        case email = "email"
        case id = "id"
        case displayName = "displayName"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        email = try values.decodeIfPresent(String.self, forKey: .email)
        id = try values.decodeIfPresent(String.self, forKey: .id)
        displayName = try values.decodeIfPresent(String.self, forKey: .displayName)
    }
    
}
