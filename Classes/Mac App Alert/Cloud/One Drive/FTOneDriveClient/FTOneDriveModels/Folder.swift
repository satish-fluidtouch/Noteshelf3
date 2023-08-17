//  OneDriveDemo
//
//  Created by Simhachalam Naidu on 17/09/19.
//  Copyright © 2019 Simhachalam Naidu. All rights reserved.
//

import Foundation
struct Folder : Codable {
	let childCount : Int?

	enum CodingKeys: String, CodingKey {

		case childCount = "childCount"
	}

	init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		childCount = try values.decodeIfPresent(Int.self, forKey: .childCount)
	}

}
