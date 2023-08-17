//
//  NetworkResponse.swift
//  NoteShelf
//
//  Created by Siva Kumar Reddy Thimmareddy on 02/03/20.
//  Copyright © 2020 Siva Kumar Reddy Thimmareddy. All rights reserved.
//

enum NetworkResponse<T> {
    case success(T)
    case failure(NetworkError)
}
