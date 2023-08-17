//
//  FTGetInspiredViewModel.swift
//  Noteshelf3
//
//  Created by Rakesh on 16/05/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Combine
import FTCommon

class FTGetInspiredViewModel:ObservableObject{
    @Published var inspiredList: [FTInspireItem] = []

     func fetchInspireList() {
//         let dispatchGroup = DispatchGroup()
//         dispatchGroup.enter()
//
        let getInspiredResponse = GetInspiredDatasource.loadData()
        let plistItems = getInspiredResponse.getInspitedList
         if let url = Bundle.main.url(forResource: FTGetinspireDataTags.getInspiredThumbnail, withExtension: "bundle") {
             for listitem in plistItems {
                 listitem.imageName = url.appendingPathComponent(listitem.imageName.lastPathComponent).path
             }
             self.inspiredList = plistItems
         }

//         fetchODRGetInspiredData { error, url in
//             if let url = url ,error == nil{
//                 for listitem in plistItems {
//                     listitem.imageName = url.appendingPathComponent(listitem.imageName.lastPathComponent).path
//                 }
//                 dispatchGroup.leave()
//             }
//
//             dispatchGroup.notify(queue: .main) {
//                 self.inspiredList = plistItems
//             }
//
//         }
    }

//    private func fetchODRGetInspiredData(onCompletion: @escaping (Error?, URL?) -> Void) {
//        let inspiredDataFetcher = FTGetInspireThumbnailDataFetcher(tags: [FTGetinspireDataTags.getInspiredThumbnail])
//        inspiredDataFetcher.fetchResources { error in
//            if let error = error {
//                print("Error in fetching downloadable data - \(error.localizedDescription)")
//            }
//            onCompletion(error,Bundle.main.url(forResource: FTGetinspireDataTags.getInspiredThumbnail, withExtension: "bundle"))
//            inspiredDataFetcher.endAccessingResources()
//        }
//    }
}

class FTGetInspireThumbnailDataFetcher: FTResourceFetcher{

    override init(tags: Set<String>) {
        super.init(tags: tags)
    }
    override func fetchResources(onCompletion: @escaping (Error?) -> Void) {
        if self.checkUpdatesIfAny() {
            super.fetchResources(onCompletion: onCompletion)
        } else {
            //This block will excecute once we add version validation check.
            self.request?.conditionallyBeginAccessingResources(completionHandler: { available in
                if !available {
                    super.fetchResources(onCompletion: onCompletion)
                }
            })
        }
    }
    private func checkUpdatesIfAny() -> Bool {
        //Version Validation Logic here
        return true
    }
}

public struct FTGetinspireDataTags{
    static let getInspiredThumbnail = "GetInspiredThumbnail"
}

