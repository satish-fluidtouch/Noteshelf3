//
//  ilemanager+Addition.swift
//  FTTemplatesStore
//
//  Created by Siva on 05/06/23.
//

import Foundation

extension FileManager {
    func uniqueFileName(directoryURL: URL, fileName: String?) -> String {
        let baseName = fileName?.count ?? 0 > 0 ? fileName ?? "Untitled" : "Untitled"
           var suffix = 0

           while true {
               let uniqueName = suffix > 0 ? "\(baseName) \(suffix)" : baseName
               let fileURL = directoryURL.appendingPathComponent(uniqueName)

               if !fileExists(atPath: fileURL.path) {
                   return uniqueName
               }

               suffix += 1
           }
    }
}
