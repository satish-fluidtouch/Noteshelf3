//
//  URLSessionProtocol.swift
//  NoteShelf
//
//  Created by Siva Kumar Reddy Thimmareddy on 03/03/20.
//  Copyright © 2020 Siva Kumar Reddy Thimmareddy. All rights reserved.
//

import Foundation

protocol URLSessionProtocol {
    typealias DataTaskResult = (Data?, URLResponse?, Error?) -> Void
    func dataTask(request: URLRequest, completionHandler: @escaping DataTaskResult) -> URLSessionDataTask
}

extension URLSession: URLSessionProtocol {
    func dataTask(request: URLRequest, completionHandler: @escaping DataTaskResult) -> URLSessionDataTask {
        let dataTask = self.dataTask(with: request, completionHandler: completionHandler);
        return dataTask;
    }
}
