//
//  NetworkError.swift
//  NoteShelf
//
//  Created by Siva Kumar Reddy Thimmareddy on 02/03/20.
//  Copyright © 2020 Siva Kumar Reddy Thimmareddy. All rights reserved.
//

enum NetworkError: String {
    case unknown
    case noJSONData
    case success
    case authenticationError = "You need to be authenticated first."
    case badRequest = "Bad request"
    case outdated = "The url you requested is outdated."
    case failed = "Network request failed."
    case noData = "Response returned with no data to decode."
    case unableToDecode = "We could not decode the response."
    case modelParsaingErroe = "Model Parsing Error."
    case noInternetConnection = "No Internet Connection"
    case requestCancelled = "request Cancelled"

}
