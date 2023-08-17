//  OneDriveDemo
//
//  Created by Simhachalam Naidu on 17/09/19.
//  Copyright © 2019 Simhachalam Naidu. All rights reserved.
//

import Foundation
struct FTOneDriveFiles_Base : Codable {
	let context : String?
	let value : [FTOneDriveFileItem]?

	enum CodingKeys: String, CodingKey {

		case context = "@odata.context"
		case value = "value"
	}

	init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		context = try values.decodeIfPresent(String.self, forKey: .context)
		value = try values.decodeIfPresent([FTOneDriveFileItem].self, forKey: .value)
	}

}
