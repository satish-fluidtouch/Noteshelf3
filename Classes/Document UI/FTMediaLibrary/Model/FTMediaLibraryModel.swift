//
//  FTMediaLibraryModel.swift
//  ClipartKit
//
//  Created by Akshay on 27/11/18.
//  Copyright © 2018 FluidTouch. All rights reserved.
//

import UIKit
import FTNewNotebook

class FTMediaLibrary: Codable {
    var id: String
    static func == (lhs: FTMediaLibrary, rhs: FTMediaLibrary) -> Bool {
        return lhs.id == rhs.id
    }
    init(id: String) {
        self.id = id
    }
    var hashValue: String {
        return id
    }
}
/// Main Clipart content
class FTMediaLibraryModel: FTMediaLibrary {

    var title: String = ""
    var clipartDescription: String = ""
    var tags: String = ""
    var urls: FTOpenClipartURL?
    var detail_link: String?
    var width, height: Int?
    var user: User?
    var isLocal: Bool = false
    var links: FTOpenClipartResultLinks?
    var unSplashTags: [Tag]?
    init(id: String, title: String, clipartDescription: String, user: User? = nil, tags: String = "", urls: FTOpenClipartURL? = nil, detail_link: String? = nil, width: Int?, height: Int?, links: FTOpenClipartResultLinks? = nil, unSplashTags: [Tag]? = nil ) {
        super.init(id: id)
        self.title = title
        self.clipartDescription = clipartDescription
        self.tags = tags
        self.urls = urls
        self.detail_link = detail_link
        self.width = width
        self.height = height
        self.user = user
        self.links = links
        self.unSplashTags = unSplashTags
    }

    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(String.self, forKey: .id)
        let title = try container.decode(String.self, forKey: .title)
        let clipartDescription = try container.decode(String.self, forKey: .clipartDescription)
        let tags = try container.decode(String.self, forKey: .tags)
        let urls = try container.decodeIfPresent(FTOpenClipartURL.self, forKey: .urls)
        let detail_link = try container.decodeIfPresent(String.self, forKey: .detail_link)
        let width = try container.decodeIfPresent(Int.self, forKey: .width)
        let height = try container.decodeIfPresent(Int.self, forKey: .height)
        let user = try container.decodeIfPresent(User.self, forKey: .user)
        let links = try container.decodeIfPresent(FTOpenClipartResultLinks.self, forKey: .links)
        let unSplashTags = try container.decodeIfPresent([Tag].self, forKey: .unSplashTags)

        self.init(id: id, title: title, clipartDescription: clipartDescription, user: user , tags: tags, urls: urls, detail_link: detail_link,width: width,height: height, links: links, unSplashTags: unSplashTags)
    }

    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(clipartDescription, forKey: .clipartDescription)
        try container.encode(tags, forKey: .tags)
        try container.encodeIfPresent(urls, forKey: .urls)
        try container.encodeIfPresent(detail_link, forKey: .detail_link)
        try container.encodeIfPresent(width, forKey: .width)
        try container.encodeIfPresent(height, forKey: .height)
        try container.encodeIfPresent(user, forKey: .user)
        try container.encodeIfPresent(links, forKey: .links)
        try container.encodeIfPresent(unSplashTags, forKey: .unSplashTags)

    }

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case title = "title"
        case clipartDescription = "description"
        case tags = "tags"
        case urls = "svg"
        case detail_link = "detail_link"
        case width = "width"
        case height = "height"
        case user = "user"
        case links = "links"
        case unSplashTags = "unSplashTag"
    }

}

/// Main Wrapper of Clipart Response
struct FTOpenClipartResponse: Decodable {
    var msg: String
    var payload: [FTMediaLibraryModel]
    var info: FTOpenClipartInfo
}

/// Metadata of Clipart Response
struct FTOpenClipartInfo: Decodable {
    var results: Int
    var pages: Int
    var current_page: Int
}

/// Clipart Image URLs for different sizes
public struct FTOpenClipartURL: Codable {
    var png_thumb: String
    var png_full_lossy: String
}
struct FTOpenClipartResultLinks: Codable {
    var download_location: String
}
