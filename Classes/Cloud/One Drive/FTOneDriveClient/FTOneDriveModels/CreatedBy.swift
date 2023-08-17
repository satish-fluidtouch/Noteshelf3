//  OneDriveDemo
//
//  Created by Simhachalam Naidu on 17/09/19.
//  Copyright © 2019 Simhachalam Naidu. All rights reserved.
//


import Foundation
struct CreatedBy : Codable {
	let application : FTOneDriveApp?
	let user : FTOneDriveUser?

	enum CodingKeys: String, CodingKey {

		case application = "application"
		case user = "user"
	}

	init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		application = try values.decodeIfPresent(FTOneDriveApp.self, forKey: .application)
		user = try values.decodeIfPresent(FTOneDriveUser.self, forKey: .user)
	}

}
