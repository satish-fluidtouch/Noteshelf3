//
//  ProviderProtocol.swift
//  NoteShelf
//
//  Created by Siva Kumar Reddy Thimmareddy on 03/03/20.
//  Copyright © 2020 Siva Kumar Reddy Thimmareddy. All rights reserved.
//

protocol ProviderProtocol {
    func request<T>(type: T.Type, service: ServiceProtocol, completion: @escaping (NetworkResponse<T>) -> Void) where T: Decodable
}
