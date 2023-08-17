//  OneDriveDemo
//
//  Created by Simhachalam Naidu on 17/09/19.
//  Copyright © 2019 Simhachalam Naidu. All rights reserved.
//


import Foundation
struct FTOneDriveApp : Codable {
	let id : String?
	let displayName : String?

	enum CodingKeys: String, CodingKey {

		case id = "id"
		case displayName = "displayName"
	}

	init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		id = try values.decodeIfPresent(String.self, forKey: .id)
		displayName = try values.decodeIfPresent(String.self, forKey: .displayName)
	}

}
