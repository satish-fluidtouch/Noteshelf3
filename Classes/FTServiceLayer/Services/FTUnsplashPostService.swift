//
//  FTUnsplashPostService.swift
//  NoteShelf
//
//  Created by Siva Kumar Reddy Thimmareddy on 03/03/20.
//  Copyright © 2020 Siva Kumar Reddy Thimmareddy. All rights reserved.
//

import Foundation

import Foundation

private let UnSplashKeyAccessKey = "Client-ID rFcWJYJTU766J7Wz2inSOAjBNuSFbXnHHAlkivtzEXs"

enum UnSplashSortOrder: String {
    case relevant
    case latest
    case revelance
}

enum FTUnsplashPostService {
    case search(query:String, sort: UnSplashSortOrder = .revelance , amount:Int?, page:Int?)
    case downloadImage(downloadUrl: String? = "")

}
extension FTUnsplashPostService: ServiceProtocol {
    
    var baseURL: URL {
        return URL(string: "https://api.unsplash.com/")!
    }
    var downloadBaseURL: URL {
           return URL(string: "")!
       }
    var path: String {
        switch self {
        case .search:
            return "search/photos"
        case .downloadImage(downloadUrl: let path):
            return path as! String
        }
    }
    
    var method: HTTPMethod {
        return .get
    }
    
    var task: TaskRequest {
        switch self {
        case .search:
            return .requestParameters(parameters)
        case .downloadImage:
            return .requestParameters(parameters)
        }
    }
    
    var headers: Headers? {
        return ["Authorization" : UnSplashKeyAccessKey,
                "Content-Type" : "application/json"
        ]
    }
    
    var parametersEncoding: ParametersEncoding {
        return .url
    }
    var cachePolicy: URLRequest.CachePolicy {
        return URLRequest.CachePolicy.returnCacheDataElseLoad
    }
    
    var parameters: Parameters {
        switch self {
        case .search(let query, let sortOrder, let amount, let page):
            
            var params: Parameters = [
                                      "query": query]
            
            if let _amount = amount, _amount > 0 {
                params["per_page"] = _amount
            }
            
            if let _page = page, _page > 0 {
                params["page"] = _page
            }
            
//            params["order_by"] = sortOrder
            return params
        case .downloadImage:
            let params: Parameters = [:]
            return params
        }
    }
    
    var parameterEncoder: ParameterEncoding {
        switch self {
        case .search:
            return URLEncoding()
        case .downloadImage:
            return URLEncoding()
        }
    }
    
    var urlRequest: URLRequest {
        var url = baseURL.appendingPathComponent(path)

        switch self {
        case .search:
            url = baseURL.appendingPathComponent(path)
        case .downloadImage:
            url = URL(string: path)!
        }
        
        var request = URLRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: 30)
        request.allHTTPHeaderFields = headers
        request.httpMethod = method.rawValue
        
        let encodedRequest = parameterEncoder.encode(request, with: parameters)
        
        return encodedRequest
    }
}
