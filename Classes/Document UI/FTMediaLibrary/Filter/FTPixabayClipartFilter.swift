//
//  FTPixabayClipartFilter.swift
//  Noteshelf
//
//  Created by Akshay on 09/04/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTCommon

private let ClipartFilterFilename = "ClipartTagFilter"
private let localFilterFileURL = FTUtils.mediaLibraryDirectoryURL.appendingPathComponent(ClipartFilterFilename).appendingPathExtension("plist")

private struct FTPixabayClipartFilterContent:Encodable, Decodable {
    let version:Int
    let tags:[String]

    static var defaultContent : FTPixabayClipartFilterContent {
        return FTPixabayClipartFilterContent(version: 1, tags: [String]())
    }
}

@objcMembers class FTPixabayClipartFilter: NSObject {

    fileprivate var filteringContent = FTPixabayClipartFilterContent.defaultContent

    override init() {
        super.init()
        filteringContent = getClipartFilteringContent()
    }

    func filterClipart(_ clipart:[FTMediaLibraryModel]) -> [FTMediaLibraryModel] {

        guard !filteringContent.tags.isEmpty else {
            return clipart
        }

        let filteredClipart = clipart.filter({ item in
            var contains = false
            for tag in filteringContent.tags {
                if item.tags.lowercased().contains(tag.lowercased()) {
                    contains = true
                    break
                }
            }
            return !contains
        })
        return filteredClipart
    }
    
    func filterUnSplash(_ clipart:[FTMediaLibraryModel]) -> [FTMediaLibraryModel] {

        guard !filteringContent.tags.isEmpty else {
            return clipart
        }

        let filteredClipart = clipart.filter({ item in
            var contains = false
            for tag in filteringContent.tags {
                if let tags =  item.unSplashTags {
                    for unSplashTag in tags {
                        if let tagTitle = unSplashTag.title {
                            if tagTitle.lowercased().contains(tag.lowercased()) {
                                  contains = true
                                  break
                              }
                        }
                      }
                }
            }
            return !contains
        })
        return filteredClipart
    }
    class func downloadClipartFilterIfNeeded() {
        if isInChinaRegion() {
            downloadForChinaRegion()
        } else {
            downloadForNonChinaRegion()
        }
    }

   private class func downloadForNonChinaRegion() {
        let remoteVersion = FTAppConfigHelper.sharedAppConfig().clipartFilterVersion()
        if FTUserDefaults.currentClipartFilterVersion() < remoteVersion {
            var success = false
            DispatchQueue.global().async {
                let remoteURL = FTServerConfig.clipartTagFilterURL()
                let data = NSData.init(contentsOf: remoteURL);
                if let _data = data {
                    success = _data.write(to: localFilterFileURL, atomically: true);
                    if success {
                        FTUserDefaults.updateClipartFilterVersion(remoteVersion)
                    }
                }
            };
        }
    }

    private class func downloadForChinaRegion() {
        let lastDownloadClipartTimeInterval = UserDefaults.standard.double(forKey: "lastDownloadClipartTimeInterval")
        let currentTimeInterval = Date().timeIntervalSinceNow

        if currentTimeInterval - lastDownloadClipartTimeInterval >= 24*60*60 {
             var success = false
             DispatchQueue.global().async {
                 let remoteURL = FTServerConfig.clipartTagFilterURL()
                 let data = NSData.init(contentsOf: remoteURL);
                 if let _data = data {
                     success = _data.write(to: localFilterFileURL, atomically: true);
                     if success {
                         UserDefaults.standard.set(currentTimeInterval, forKey: "lastDownloadClipartTimeInterval")
                     }
                 }
             };
         }
     }
}

//MARK:- Private
private extension FTPixabayClipartFilter {
    func getClipartFilteringContent() -> FTPixabayClipartFilterContent {
        copyClipartFilterFileToLibraryIfRequired()
        do {
            let data = try Data(contentsOf: localFilterFileURL)
            let decoder = PropertyListDecoder()
            let filterContents = try decoder.decode(FTPixabayClipartFilterContent.self, from: data)
            return filterContents
        } catch {
            #if DEBUG
            print("Local Filtering File Read Error::",error.localizedDescription)
            #endif
        }
        return FTPixabayClipartFilterContent.defaultContent
    }

    func copyClipartFilterFileToLibraryIfRequired() {
        let localURL = localFilterFileURL
        if let bundleFileURL = Bundle.main.url(forResource: ClipartFilterFilename, withExtension: "plist") {
            do {
                let data = try Data(contentsOf: bundleFileURL)
                let decoder = PropertyListDecoder()
                let bundleContents = try decoder.decode(FTPixabayClipartFilterContent.self, from: data)

                if !FileManager.default.fileExists(atPath: localURL.path) {
                    do {
                        try FileManager.default.copyItem(at: bundleFileURL, to: localURL)
                        FTUserDefaults.updateClipartFilterVersion(bundleContents.version)
                    } catch {
                        #if DEBUG
                        print("Error in initial local filter file:",error.localizedDescription)
                        #endif
                    }
                } else {
                    do{
                        if bundleContents.version > FTUserDefaults.currentClipartFilterVersion() {
                            try FileManager.default.removeItem(at: localURL);
                            try FileManager.default.copyItem(at: bundleFileURL, to: localURL)
                            FTUserDefaults.updateClipartFilterVersion(bundleContents.version)
                        }
                    } catch {
                        #if DEBUG
                        print("Error in copying bundle filter file:",error.localizedDescription)
                        #endif
                    }
                }
            } catch {
                #if DEBUG
                print("Error in Reading bundle filter file:",error.localizedDescription)
                #endif
            }
        }
    }
}
