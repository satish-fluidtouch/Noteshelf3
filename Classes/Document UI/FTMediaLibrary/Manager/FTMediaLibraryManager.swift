//
//  MoviesViewModel.swift
//  Movies
//
//  Created by Siva Kumar Reddy Thimmareddy on 04/03/20.
//  Copyright © 2020 Siva Kumar Reddy Thimmareddy. All rights reserved.
//

import Foundation

enum PostResponse<T> {
    case successWith(T)
    case failureWith(NetworkError)
}

protocol FTClipartProviderProtocol {
    func searchPixabay<T>(type: T.Type, service: ServiceProtocol, completion: @escaping (PostResponse<T>) -> Void) where T: Decodable
    func searchUnSplash<T>(type: T.Type, service: ServiceProtocol, completion: @escaping (PostResponse<T>) -> Void) where T: Decodable
}

class FTMediaLibraryManager: FTClipartProviderProtocol {
    func cancelPreviousRequest()  {
        if self.sessionProvider.task != nil {
        self.sessionProvider.task?.cancel()
        }
    }
    private let sessionProvider = URLSessionProvider()
    
    func searchPixabay<T>(type: T.Type, service: ServiceProtocol, completion: @escaping (PostResponse<T>) -> Void) where T: Decodable {
        cancelPreviousRequest()
        DispatchQueue.global(qos: .background).async {
            self.sessionProvider.request(type: type, service: service) { response in
                switch response {
                case let .success(posts):
                    print(posts)
                    completion(.successWith(posts))
                case let .failure(error):
                    print(error)
                    completion(.failureWith(error))
                }
            }
        }
        
    }
    
    func searchUnSplash<T>(type: T.Type, service: ServiceProtocol, completion: @escaping (PostResponse<T>) -> Void) where T: Decodable {
        cancelPreviousRequest()
        DispatchQueue.global(qos: .background).async {
            self.sessionProvider.request(type: type, service: service) { response in
                switch response {
                case let .success(posts ):
                    print(posts)
                    completion(.successWith(posts))
                case let .failure(error):
                    print(error)
                    completion(.failureWith(error))
                }
            }
        }
        
    }
    func downloadImage()  {
        let todoEndpoint: String = "https://api.unsplash.com/photos/6q2DEwka9Uc/download?client_id=FO6oGpiGw3ZTAHXAzHiltt611d45PO2FnIdIef0pKX0"
        guard let url = URL(string: todoEndpoint) else {
            debugLog("Error: cannot create URL")
          return
        }
        let urlRequest = URLRequest(url: url)
        let session = URLSession.shared
        let task = session.dataTask(with: urlRequest) {
          (data, response, error) in
          // check for any errors
          guard error == nil else {
            #if DEBUG
            debugLog("error calling GET on /todos/1")
            print(error!)
            #endif
            return
          }
          // make sure we got data
          guard let responseData = data else {
            debugLog("Error: did not receive data")
            return
          }
          // parse the result as JSON, since that's what the API provides
          do {
            guard let todo = try JSONSerialization.jsonObject(with: responseData, options: [])
              as? [String: Any] else {
                debugLog("error trying to convert data to JSON")
              return
            }
            // now we have the todo
            // let's just print it to prove we can access it
            #if DEBUG
            print("The todo is: " + todo.description)
            #endif
            
            // the todo object is a dictionary
            // so we just access the title using the "title" key
            // so check for a title and print it if we have one
            guard let todoTitle = todo["title"] as? String else {
                debugLog("Could not get todo title from JSON")
              return
            }
            #if DEBUG
            print("The title is: " + todoTitle)
            #endif
          } catch  {
            debugLog("error trying to convert data to JSON")
            return
          }
        }
        task.resume()
    }
}
