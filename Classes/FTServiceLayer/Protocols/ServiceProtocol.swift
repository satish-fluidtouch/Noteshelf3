//
//  ServiceProtocol.swift
//  NoteShelf
//
//  Created by Siva Kumar Reddy Thimmareddy on 03/03/20.
//  Copyright © 2020 Siva Kumar Reddy Thimmareddy. All rights reserved.
//

import Foundation

typealias Headers = [String: String]
typealias Parameters = [String: Any]

protocol ServiceProtocol {
    var baseURL: URL { get }
    var method: HTTPMethod { get }
    var path: String { get }
    var parameters: Parameters { get }
    var urlRequest: URLRequest { get }
    var headers: Headers? { get }
    var cachePolicy: URLRequest.CachePolicy { get }
    var parametersEncoding: ParametersEncoding { get }
    var task: TaskRequest { get }
}

extension ServiceProtocol {

    var headers: [String: String]? {
        return nil
    }

    var cachePolicy: URLRequest.CachePolicy {
        return URLRequest.CachePolicy.reloadIgnoringCacheData
    }
}

// MARK: - Parameter Encoding

protocol ParameterEncoding {
    func encode(_ urlRequest: URLRequest, with parameters: Parameters) -> URLRequest
}

struct URLEncoding: ParameterEncoding {

    func encode(_ urlRequest: URLRequest, with parameters: Parameters) -> URLRequest {
        var request = urlRequest
        if let url = request.url, var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            components.queryItems = queryItems(with: parameters)
            request.url = components.url
        }
        return request
    }

    private func queryItems(with params: Parameters) -> [URLQueryItem] {
        var queryItems = [URLQueryItem]()
        for param in params {
            if let value = param.value as? String {
                let item = URLQueryItem(name: param.key, value: value)
                queryItems.append(item)
            } else if let number = param.value as? NSNumber {
                let item = URLQueryItem(name: param.key, value: number.stringValue)
                queryItems.append(item)
            }
        }
        return queryItems
    }
}

struct JSONEncoding: ParameterEncoding {

    func encode(_ urlRequest: URLRequest, with parameters: Parameters) -> URLRequest {
        var request = urlRequest
        do {
            let data = try JSONSerialization.data(withJSONObject: parameters, options: JSONSerialization.WritingOptions.prettyPrinted)

            if request.value(forHTTPHeaderField: "Content-Type") == nil {
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }

            request.httpBody = data
        } catch {
            return request
        }
        return request
    }
}
