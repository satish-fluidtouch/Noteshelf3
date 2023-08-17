//
//  FTUnsplashModel.swift
//  Noteshelf3
//
//  Created by srinivas on 14/07/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import SwiftUI

struct FTUnsplashModel: Codable {
    let total: Int
    let totalPages: Int
    let results: [FTUnSplashItem]?

    enum CodingKeys: String, CodingKey {
        case total = "total"
        case totalPages = "total_pages"
        case results = "results"
    }
}

public struct User: Codable {
    public var id, username, name, firstName: String?
    public var lastName, instagramUsername, twitterUsername: String?
    public var portfolioURL: String?
    public var profileImage: ProfileImage?
    public var links: UserLinks?

    enum CodingKeys: String, CodingKey {
        case id, username, name
        case firstName = "first_name"
        case lastName = "last_name"
        case instagramUsername = "instagram_username"
        case twitterUsername = "twitter_username"
        case portfolioURL = "portfolio_url"
        case profileImage = "profile_image"
        case links

    }
}
// MARK: - ProfileImage
public struct ProfileImage: Codable {
    public var small, medium, large: String?
}

// MARK: - UserLinks
public struct UserLinks: Codable {
    public var linksSelf: String?
    public var html: String?
    public var photos, likes: String?

    enum CodingKeys: String, CodingKey {
        case linksSelf = "self"
        case html, photos, likes
    }
}

//// MARK: - Urls
public struct Urls: Codable {
    public var raw, full, regular, small: String?
    public var thumb: String?
}

// MARK: - ResultLinks
public struct ResultLinks: Codable {
    public var linksSelf: String?
    public var html, download: String?
    public var downloadLocation: String?

    enum CodingKeys: String, CodingKey {
        case linksSelf = "self"
        case html, download
        case downloadLocation = "download_location"
    }
}
// MARK: - Tag
public struct Tag: Codable {
    public var title: String?
}

public struct FTUnSplashItem: Codable {
    public let id: String
    public var width, height: Int?
    public var urls: Urls?
    public var user: User?
    public var links: ResultLinks?
    public var tags: [Tag]?
}

public struct FTUnSplashResponse: Decodable {
    public var total, totalPages: Int
    public var results: [FTUnSplashItem]

    enum CodingKeys: String, CodingKey {
        case total = "total"
        case totalPages = "total_pages"
        case results = "results"
    }
}
// MARK: - UnSplashDownloadModel
public struct UnSplashDownloadModel: Codable {
    public let url: String
}
