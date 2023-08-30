//
//  FTTemplateStoreModel.swift
//  TempletesStore
//
//  Created by Siva on 13/02/23.
//

import Foundation
import FTCommon

let baseUrl = isInChinaRegion() ? "https://ops-dra.agcstorage.link/v0/noteshelf-data-hdmvw/store/v5/" :
"https://noteshelf3-public.s3.amazonaws.com/store/v1/"
//"https://noteshelf2-store-dev-env.s3.amazonaws.com/ns3/store/v5/"

let previewImageExtention = "/preview.jpg"

enum FTDiscoveryItemType: String {
    case category
    case templates
    case template
    case sticker
    case diary
    case diaries
}
// MARK: - FTStoreModel
struct FTStoreModel: Decodable, Hashable {
    let discover: [Discover]
}

// MARK: - Discover
struct Discover: Decodable, Hashable {

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: Discover, rhs: Discover) -> Bool {
        return lhs.id == rhs.id
    }
    let id = UUID()
    let displayTitle: String
    let sectionType, rowsCount: Int
    let type: String
    var items: [DiscoveryItem]
    enum CodingKeys: String, CodingKey {
        case displayTitle
        case sectionType
        case type
        case rowsCount
        case items
    }
}

// MARK: - DiscoveryItem
struct DiscoveryItem: Codable, Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: DiscoveryItem, rhs: DiscoveryItem) -> Bool {
        return lhs.id == rhs.id
    }
    let id = UUID()
    let displayTitle: String
    let fileName: String
    let displaySubTitle: String?
    var items: [DiscoveryItem]?
    var styles: [FTTemplateStyle]?
    let type: String
    var author: String?
    var link: String?
    var previewToken: String?
    var fileToken: String?

    enum CodingKeys: String, CodingKey {
        case displayTitle
        case displaySubTitle
        case fileName
        case items
        case styles
        case type
        case author
        case link
        case previewToken
        case fileToken
    }

    var templateUrl: URL {
        let templateName = fileName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
        return URL(string: baseUrl + "Templates/" + templateName!)!
    }

    var bannerAndCategoryThumbnailUrl: URL? {
        let thumbPath = baseUrl + "Banners_Categories/" + "en/" + "banners/" + self.fileName + ".jpg"
        var outputURL = thumbPath.properUrlForPath()
        if isInChinaRegion() {
            outputURL.append(queryItems: [URLQueryItem(name: "token", value: self.previewToken)])
        }
        return outputURL
    }

    var stickersThumbnailUrl: URL? {
        let thumbPath = baseUrl + "Banners_Categories/" + "en/" + "sticker/" + self.fileName + ".jpg"
        var outputURL = thumbPath.properUrlForPath()
        if isInChinaRegion() {
            outputURL.append(queryItems: [URLQueryItem(name: "token", value: self.previewToken)])
        }
        return outputURL
    }

    var stickersPackUrl: URL? {
        let stickersPackPath = baseUrl + "Stickers/" + self.fileName + "/stickers.zip"
        var outputURL = stickersPackPath.properUrlForPath()
        if isInChinaRegion() {
            outputURL.append(queryItems: [URLQueryItem(name: "token", value: self.fileToken)])
        }
        return outputURL
    }

}


// MARK: - FTTemplateStyle
struct FTTemplateStyle: Codable, Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: FTTemplateStyle, rhs: FTTemplateStyle) -> Bool {
        return lhs.id == rhs.id
    }
    let id = UUID()
    var title: String
    let type: String
    var templateName: String
    let version: Int
    var orientation: ThumbnailOrientation? = .potrait
    var stylePath: String?
    var stylePortToken: String?
    var styleLandToken: String?
    var templatePortToken: String?
    var templateLandToken: String?
    var previewToken: String?

    enum CodingKeys: String, CodingKey {
        case title = "displayTitle"
        case type
        case templateName
        case orientation
        case version
        case stylePath
        case stylePortToken
        case styleLandToken
        case templatePortToken
        case templateLandToken
        case previewToken
    }

    func styleThumbnailFor(template: TemplateInfo) -> URL {
        guard let template = template as? DiscoveryItem else {
            fatalError("Invalid protocol conformation")
        }

        let baseURL = template.templateUrl
        var outputURL = baseURL.appendingPathComponent("styles")
        var token: String? = self.stylePortToken
        var fileName = self.templateName
        if self.type == FTDiscoveryItemType.diary.rawValue {
            if self.orientation == .potrait {
                fileName += "_port"
                token = self.stylePortToken
            } else {
                fileName += "_land"
                token = self.styleLandToken
            }
        }
        outputURL = outputURL.appendingPathComponent(fileName).appendingPathExtension("jpg")

        if isInChinaRegion() {
            outputURL.append(queryItems: [URLQueryItem(name: "token", value: token)])
        }
        return outputURL
    }

    func pdfDownloadUrl(template: TemplateInfo) -> URL {
        guard let template = template as? DiscoveryItem else {
            fatalError("Invalid protocol conformation")
        }

        let baseURL = template.templateUrl
        var outputURL = baseURL.appendingPathComponent("/ios/templates/en/")
        var token: String? = self.templatePortToken
        var fileName = self.templateName

        if self.orientation == .potrait {
            fileName += "_port"
            token = self.templatePortToken
        } else {
            fileName += "_land"
            token = self.templateLandToken
        }
        outputURL = outputURL.appendingPathComponent(fileName).appendingPathExtension("pdf")

        if isInChinaRegion() {
            outputURL.append(queryItems: [URLQueryItem(name: "token", value: token)])
        }
        return outputURL
    }

    func pdfPath() -> URL {
        var pdfUrl = FTTemplatesCache().templatesFolder
        var fileName = self.templateName
        if self.orientation == .potrait {
            fileName += "_port"
        } else {
            fileName += "_land"
        }
        pdfUrl = pdfUrl.appendingPathComponent(fileName).appendingPathExtension("pdf")
        return pdfUrl
    }

    func thumbnailPath() -> URL {
        var pdfUrl = FTTemplatesCache().templatesFolder
        var fileName = self.templateName
        if self.type == FTDiscoveryItemType.diary.rawValue {
            fileName = self.stylePath ?? self.templateName
        }
        if self.orientation == .potrait {
            fileName += "_port"
        } else {
            fileName += "_land"
        }
        pdfUrl = pdfUrl.appendingPathComponent(fileName).appendingPathExtension("png")
        return pdfUrl
    }

    var thumbnailUrl: URL? {
        let thumbPath = baseUrl + "Templates/" + templateName + previewImageExtention
        if let filePath = thumbPath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), var fileUrl = URL(string: filePath) {
            if isInChinaRegion() {
                fileUrl.append(queryItems: [URLQueryItem(name: "token", value: self.previewToken)])
            }
            return fileUrl
        }
        return nil
    }


}

//MARK: - Templates Protocols
protocol StoreInfo {
    var title: String { get }
    var rowsCount: Int { get }
    var discoveryItems: [DiscoveryItem] { get }
    var fileName: String { get }
    var type: String { get }
    var sectionType: Int { get }

}

protocol TemplateInfo {
    var title: String { get }
    var fileName: String { get }
    var subTitle: String { get }
    var author: String? { get }
    var items: [DiscoveryItem]? { get }
    var thumbnailUrl: URL? { get }
    var styles: [FTTemplateStyle]? { get }
    var type: String { get }
    var link: String? { get }
    var previewToken: String? { get }
    var fileToken: String? { get }
}

// MARK: - Extentions

extension Discover: StoreInfo {
    var discoveryItems: [DiscoveryItem] {
        return items
    }
    var title: String {
        return displayTitle
    }
    var fileName: String {
        return ""
    }

}

extension DiscoveryItem: TemplateInfo {
    var title: String {
        return displayTitle
    }

    var subTitle: String {
        return displaySubTitle ?? ""
    }
    var thumbnailUrl: URL? {
        var thumbUrl = self.templateUrl.appendingPathComponent(previewImageExtention)
        if isInChinaRegion() {
            thumbUrl.append(queryItems: [URLQueryItem(name: "token", value: self.previewToken)])
        }
        return thumbUrl
    }

}

// TODO: Rename
protocol ThumbnailURLProvider {
    func thumbnail(with baseurl: URL, pathComponent: String) -> String
}


extension String {
    func properUrlForPath() -> URL {
        if let filePath = self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let fileUrl = URL(string: filePath) {
            return fileUrl
        }
        return URL(filePath: "")
    }
}
