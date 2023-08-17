//
//  NetworkManager.swift
//  Noteshelf3
//
//  Created by srinivas on 14/07/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

public class FTUnsplashAPI {
    let accessToken = "Client-ID rFcWJYJTU766J7Wz2inSOAjBNuSFbXnHHAlkivtzEXs"
    let api = "https://api.unsplash.com"
    let limit = 20
    let fakeKey: String = "Technology"

    public init() {
    }
    
    private func requestForUnsplash(for key: String, page: Int) -> URLRequest? {
        guard let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            fatalError("Failed to encode key")
        }
        let endpoint = "/search/photos?query=\(encodedKey)&per_page=\(limit)&page=\(page)"
        let url = URL(string: api + endpoint)
        var request = URLRequest(url: url!)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField:"Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField:"Authorization")
        request.cachePolicy = .reloadIgnoringLocalCacheData
        return request
    }
    
    public func fetchUnsplashData(with key: String, page: Int = 1) async throws -> [FTUnSplashItem]? {
        guard let request = requestForUnsplash(for: key, page: page) else {
            throw APIError.badURL
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw APIError.badRequest(statusCode: 0)
        }
        do {
            let unsplash = try JSONDecoder().decode(FTUnsplashModel.self, from: data)
            return unsplash.results
        } catch(let error) {
            debugPrint("error : \(error)")
            throw APIError.parsing(error as! DecodingError)
        }
    }
    
   public func downloadImage(with url: String) async throws -> UIImage? {
        guard let url = URL(string: url) else { throw APIError.badURL }
        let (data, _) = try await URLSession.shared.data(from: url)
        return UIImage(data: data)
    }
}

public enum APIError: Error {
    case badURL
    case badRequest(statusCode: Int)
    case parsing(DecodingError)
    case unknown
}

extension APIError: LocalizedError {
    public var errorDescription: String? {
        switch self {
            case .badURL:
                return "invalid URL"
            case .badRequest(let statusCode):
                return "bad request with status code \(statusCode)"
            case .parsing(let error):
                return "parsing error \(error)"
            case .unknown:
                return "unknown error"
        }
    }
}
