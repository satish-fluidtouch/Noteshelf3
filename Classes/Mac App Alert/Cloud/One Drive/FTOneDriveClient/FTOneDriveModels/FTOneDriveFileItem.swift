//  OneDriveDemo
//
//  Created by Simhachalam Naidu on 17/09/19.
//  Copyright © 2019 Simhachalam Naidu. All rights reserved.
//

import Foundation
@objc class FTOneDriveFileItem : NSObject, Codable {
	let createdDateTime : String?
	let eTag : String?
	let id : String?
	let lastModifiedDateTime : String?
	let name : String?
	let webUrl : String?
	let cTag : String?
	let size : Int?
	let createdBy : CreatedBy?
	let lastModifiedBy : LastModifiedBy?
	let parentReference : ParentReference?
	let fileSystemInfo : FileSystemInfo?
	let folder : Folder?

	enum CodingKeys: String, CodingKey {

		case createdDateTime = "createdDateTime"
		case eTag = "eTag"
		case id = "id"
		case lastModifiedDateTime = "lastModifiedDateTime"
		case name = "name"
		case webUrl = "webUrl"
		case cTag = "cTag"
		case size = "size"
		case createdBy = "createdBy"
		case lastModifiedBy = "lastModifiedBy"
		case parentReference = "parentReference"
		case fileSystemInfo = "fileSystemInfo"
		case folder = "folder"
	}
    required init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		createdDateTime = try values.decodeIfPresent(String.self, forKey: .createdDateTime)
		eTag = try values.decodeIfPresent(String.self, forKey: .eTag)
		id = try values.decodeIfPresent(String.self, forKey: .id)
		lastModifiedDateTime = try values.decodeIfPresent(String.self, forKey: .lastModifiedDateTime)
		name = try values.decodeIfPresent(String.self, forKey: .name)
		webUrl = try values.decodeIfPresent(String.self, forKey: .webUrl)
		cTag = try values.decodeIfPresent(String.self, forKey: .cTag)
		size = try values.decodeIfPresent(Int.self, forKey: .size)
		createdBy = try values.decodeIfPresent(CreatedBy.self, forKey: .createdBy)
		lastModifiedBy = try values.decodeIfPresent(LastModifiedBy.self, forKey: .lastModifiedBy)
		parentReference = try values.decodeIfPresent(ParentReference.self, forKey: .parentReference)
		fileSystemInfo = try values.decodeIfPresent(FileSystemInfo.self, forKey: .fileSystemInfo)
		folder = try values.decodeIfPresent(Folder.self, forKey: .folder)
	}
}
