//
//  URLComponentsExtension.swift
//  NoteShelf
//
//  Created by Siva Kumar Reddy Thimmareddy on 02/03/20.
//  Copyright © 2020 Siva Kumar Reddy Thimmareddy. All rights reserved.
//

import Foundation

extension URLComponents {

    init(service: ServiceProtocol) {
        var requestUrl: URL! //service.baseURL.appendingPathComponent(service.path)
        if  let url = service.urlRequest.url {
            requestUrl = url
        }
        self.init(url: requestUrl, resolvingAgainstBaseURL: false)!

        guard case let .requestParameters(parameters) = service.task, service.parametersEncoding == .url else { return }

        queryItems = parameters.map { key, value in
            return URLQueryItem(name: key, value: String(describing: value))
        }
    }
}
