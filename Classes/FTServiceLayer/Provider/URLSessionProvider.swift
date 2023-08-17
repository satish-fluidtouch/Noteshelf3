//
//  URLSessionProvider.swift
//  NoteShelf
//
//  Created by Siva Kumar Reddy Thimmareddy on 02/03/20.
//  Copyright © 2020 Siva Kumar Reddy Thimmareddy. All rights reserved.
//

import Foundation

final class URLSessionProvider: ProviderProtocol {

    private var session: URLSessionProtocol
    var task: URLSessionDataTask?
    init(session: URLSessionProtocol = URLSession.shared) {
        self.session = session
    }

    func request<T>(type: T.Type, service: ServiceProtocol, completion: @escaping (NetworkResponse<T>) -> Void) where T: Decodable {
        let request = URLRequest(service: service)

         task = session.dataTask(request: request, completionHandler: { [weak self] data, response, error in
            let httpResponse = response as? HTTPURLResponse
            self?.handleDataResponse(data: data, response: httpResponse, error: error, completion: completion)
        })
        task?.resume()
    }

    private func handleDataResponse<T: Decodable>(data: Data?, response: HTTPURLResponse?, error: Error?, completion: (NetworkResponse<T>) -> Void) {
        if let err = error as? URLError, err.code  == URLError.Code.notConnectedToInternet  {
                  // No internet
                completion(.failure(.noInternetConnection))
                return
              }
        if let err = error as? URLError, err.code  == URLError.Code.cancelled  {
                      completion(.failure(.requestCancelled))
                      return
                    }
//        guard error == nil else { return completion(.failure(.unknown)) }
        guard let response = response else { return completion(.failure(.noJSONData)) }

        switch response.statusCode {
        case 200...299:
            guard let data = data, let model = try? JSONDecoder().decode(T.self, from: data) else { return completion(.failure(.modelParsaingErroe)) }
            completion(.success(model))
        case 401...500:
            completion(.failure(.authenticationError))
        case 501...599:
            completion(.failure(.badRequest))
        case 600:
            completion(.failure(.outdated))
        default:
            completion(.failure(.failed))

        }        
    }
}
