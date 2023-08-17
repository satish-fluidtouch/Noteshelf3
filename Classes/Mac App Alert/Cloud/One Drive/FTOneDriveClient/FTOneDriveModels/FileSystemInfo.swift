//  OneDriveDemo
//
//  Created by Simhachalam Naidu on 17/09/19.
//  Copyright © 2019 Simhachalam Naidu. All rights reserved.
//


import Foundation
struct FileSystemInfo : Codable {
	let createdDateTime : String?
	let lastModifiedDateTime : String?

	enum CodingKeys: String, CodingKey {

		case createdDateTime = "createdDateTime"
		case lastModifiedDateTime = "lastModifiedDateTime"
	}

	init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		createdDateTime = try values.decodeIfPresent(String.self, forKey: .createdDateTime)
		lastModifiedDateTime = try values.decodeIfPresent(String.self, forKey: .lastModifiedDateTime)
	}

}
