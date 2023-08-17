//
//  FTPHPickerViewController.swift
//  FTCommon
//
//  Created by Narayana on 08/11/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import PhotosUI
import Combine
import FTCommon

extension FTPHPicker {
     func processResultForImportItems(results: [PHPickerResult], _ completon: @escaping ([FTImportItem]) -> Void) {
        results
            .publisher
            .flatMap ({ phPickerResult in
                return self.parseResult(phPickerResult: phPickerResult)
            })
            .receive(on: RunLoop.main)
            .map { phItem -> FTImportItem in
                return FTImportItem(item: phItem.image)
            }
            .collect()
            .sink(receiveCompletion: { _ in
                debugPrint(" receiveCompletion " )
            }, receiveValue: { items in
                debugPrint(" receiveValue : \(items.count)")
                completon(items)
            }).store(in: &cancellable)
    }
}
