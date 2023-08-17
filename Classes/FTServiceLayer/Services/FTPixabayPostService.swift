//
//  FTPixabayPostService.swift
//  NoteShelf
//
//  Created by Siva Kumar Reddy Thimmareddy on 03/03/20.
//  Copyright © 2020 Siva Kumar Reddy Thimmareddy. All rights reserved.
//

import Foundation

import Foundation

private let PixabayAPIKey = "12288010-dc965642562959af2a4f30221"

enum PixabaySortOrder: String {
    case popular
    case latest
    case mostDownloaded
}

enum FTPixabayPostService {
    case search(query:String, imageType: String, sort: PixabaySortOrder, amount:Int?, page:Int?)
    
}
extension FTPixabayPostService: ServiceProtocol {
    
    var baseURL: URL {
        return URL(string: "https://pixabay.com/")!
    }
    
    var path: String {
        switch self {
        case .search:
            return "api/"
        }
    }
    
    var method: HTTPMethod {
        return .get
    }
    
    var task: TaskRequest {
        switch self {
        case .search:
            return .requestParameters(parameters)
        }
    }
    
    var headers: Headers? {
        return nil
    }
    
    var parametersEncoding: ParametersEncoding {
        return .url
    }
    var cachePolicy: URLRequest.CachePolicy {
        return URLRequest.CachePolicy.reloadIgnoringLocalCacheData
    }
    
    var parameters: Parameters {
        switch self {
        case .search(let query, let imageType, let sortOrder, let amount, let page):
            
            var params: Parameters = ["key": PixabayAPIKey,
                                      "q": query,
                                      "safesearch": true,
                                      "order": sortOrder,
                                      "image_type": imageType]
            
            if let _amount = amount, _amount > 0 {
                params["per_page"] = _amount
            }
            
            if let _page = page, _page > 0 {
                params["page"] = _page
            }
            
            params["order"] = sortOrder
            return params
        }
    }
    
    var parameterEncoder: ParameterEncoding {
        switch self {
        case .search:
            return URLEncoding()
        }
    }
    
    var urlRequest: URLRequest {
        
        let url = baseURL.appendingPathComponent(path)
        
        var request = URLRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: 30)
        request.allHTTPHeaderFields = headers
        request.httpMethod = method.rawValue
        
        let encodedRequest = parameterEncoder.encode(request, with: parameters)
        
        return encodedRequest
    }
}
