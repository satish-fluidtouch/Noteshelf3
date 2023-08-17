//  OneDriveDemo
//
//  Created by Simhachalam Naidu on 17/09/19.
//  Copyright © 2019 Simhachalam Naidu. All rights reserved.
//


import Foundation
struct ParentReference : Codable {
	let driveId : String?
	let driveType : String?
	let id : String?
	let path : String?

	enum CodingKeys: String, CodingKey {

		case driveId = "driveId"
		case driveType = "driveType"
		case id = "id"
		case path = "path"
	}

	init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		driveId = try values.decodeIfPresent(String.self, forKey: .driveId)
		driveType = try values.decodeIfPresent(String.self, forKey: .driveType)
		id = try values.decodeIfPresent(String.self, forKey: .id)
		path = try values.decodeIfPresent(String.self, forKey: .path)
	}

}
