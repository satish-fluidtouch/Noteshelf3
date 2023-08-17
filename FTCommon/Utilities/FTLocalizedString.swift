//
//  File.swift
//  
//
//  Created by Narayana on 16/05/22.
//

import Foundation

public func FTDiaryGeneratorLocalizedString(_ key: String, comment: String?) -> String {
    return NSLocalizedString(key,
                             tableName: "DiaryGeneratorLocalizable",
                             bundle: Bundle.main,
                             value: "", comment: comment ?? "")
}
