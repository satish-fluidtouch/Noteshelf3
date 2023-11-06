//
//  FTCachedSqliteAnnotationFileItem.swift
//  Noteshelf3
//
//  Created by Akshay on 30/11/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTDocumentFramework
import FTRenderKit

final class FTCachedSqliteAnnotationFileItem: FTFileItemSqlite {
    weak var documentItem: FTDocumentItemProtocol?
    convenience init(url: URL, isDirectory: Bool, documentItem: FTDocumentItemProtocol?) {
        self.init(url: url, isDirectory: isDirectory)
        self.documentItem = documentItem
    }

    func annotataionsWithResources() -> [FTShelfMedia]
    {
        var mediaToReturn = [FTShelfMedia]();
        let typesOfAnnotation: [Int] = [FTAnnotationType.image.rawValue];

        if (false == self.schemaExists()) {
            return mediaToReturn;
        }

        self.databaseQueue.inDatabase({ [weak self] (db) in
            guard let self = self else { return }
            let index = getPageIndex()

            db.open();
            let keywordSelQuery = "SELECT id, annotationType from annotation WHERE annotationType IN (?)";
            let set = db.executeQuery(keywordSelQuery, withArgumentsIn: typesOfAnnotation);
            if let _set = set , _set.columnCount > 0 {
                while(_set.next()) {
                    guard let uuid = _set.string(forColumn: "id"),
                          let annotationType = FTAnnotationType(rawValue: Int(_set.int(forColumn: "annotationType"))) else {
                        continue
                    }

                    if annotationType == .image {
                        let url = imageURL(uuid: uuid)
                        let media = FTShelfMedia(imageURL: url,
                                                 page: index,
                                                 document: self.documentItem)
                        mediaToReturn.append(media)
                    }
                }
            }
            set?.close();
            db.close();
        });
        return mediaToReturn;
    }


    func audioAnnotataions() -> [FTShelfAudio] {
        var mediaToReturn = [FTShelfAudio]();
        let typesOfAnnotation: [Int] = [FTAnnotationType.audio.rawValue];

        if (false == self.schemaExists()) {
            return mediaToReturn;
        }

        self.databaseQueue.inDatabase({ [weak self] (db) in
            guard let self = self else { return }
            let index = getPageIndex()

            db.open();
            let keywordSelQuery = "SELECT id, annotationType, modifiedTime, boundingRect_x, boundingRect_y, boundingRect_w, boundingRect_h, screenScale, createdTime, isReadonly, version, isLocked from annotation WHERE annotationType IN (?)";
            let set = db.executeQuery(keywordSelQuery, withArgumentsIn: typesOfAnnotation);
            if let _set = set , _set.columnCount > 0 {
                while(_set.next()) {
                    guard let uuid = _set.string(forColumn: "id"),
                        let annotationType = FTAnnotationType(rawValue: Int(_set.int(forColumn: "annotationType"))) else {
                        continue
                    }
                    if annotationType == .audio {
                    if let annotation = FTAnnotation.annotation(forSet: _set) as? FTAudioAnnotation, let recording = audioRecording(uuid: uuid), let model = recording.1 {
                            let name = recording.0 ?? "Recording"
                            let dateAndTime = DateFormatter.localizedString(from: Date(timeIntervalSinceReferenceDate: annotation.modifiedTimeInterval), dateStyle: .short, timeStyle: .short)
                            let duration =  FTUtils.timeFormatted(UInt(model.audioDurationWithoutCheckingFileExistance()))
                            let media = FTShelfAudio(audioTitle: name,
                                                     duration: duration,
                                                     page: index,
                                                     document: self.documentItem,
                                                     dateAndTime: dateAndTime)
                            mediaToReturn.append(media)
                        }
                    }
                }
            }
            set?.close();
            db.close();
        });
        return mediaToReturn;
    }

    fileprivate func schemaExists() -> Bool
    {
        guard let fileURL = self.fileItemURL else {
            return false;
        }

        if (!FileManager.default.fileExists(atPath: fileURL.path)) {
            return false;
        }
        var success : Bool = false;

        self.databaseQueue.inDatabase { (db) in
            db.open();
            let checkForTavleQuery = "SELECT name FROM sqlite_master WHERE type='table' AND name='annotation'";
            let set = db.executeQuery(checkForTavleQuery, withParameterDictionary: nil);
            if(nil != set) {
                success = set!.next();
                set!.close();
            }
            db.close();
        }
        return success;
    }
}

private extension FTCachedSqliteAnnotationFileItem {
    var pageID: String {
        self.fileItemURL.lastPathComponent.deletingPathExtension
    }

    func imageURL(uuid: String) -> URL {
        let annotationsFolder = self.fileItemURL.deletingLastPathComponent()
        let rootFolder = annotationsFolder.deletingLastPathComponent()
        let imageAssetPath = rootFolder.path.appending("/Resources/\(uuid.appending(".png"))")
        return URL(fileURLWithPath: imageAssetPath)
    }

    func audioRecording(uuid: String) -> (String?, FTAudioRecordingModel?)? {
        let annotationsFolder = self.fileItemURL.deletingLastPathComponent()
        let rootFolder = annotationsFolder.deletingLastPathComponent()
        let audioAssetPath = rootFolder.path.appending("/Resources/\(uuid.appending(".plist"))")
        do {
            let url = URL(fileURLWithPath: audioAssetPath)
            let dict = try NSDictionary(contentsOf: url, error: ())
            let model = FTAudioRecordingModel.init(dict: dict["recordingModel"] as? Dictionary<String,Any>)
            let name = dict["audioName"] as? String
            return (name, model)
                
        } catch {
            return  (nil, nil)
        }
    }

    func getPageIndex() -> Int {
        let annotationsFolder = self.fileItemURL.deletingLastPathComponent()
        let rootFolder = annotationsFolder.deletingLastPathComponent()
        let docPlist = rootFolder.path.appending("/Document.plist")
        do {
            let url = URL(fileURLWithPath: docPlist)
            let dict = try NSDictionary(contentsOf: url, error: ())
            let pagesArray = dict["pages"] as? [NSDictionary]
            let index = pagesArray?.firstIndex(where: { ($0["uuid"] as? String) == pageID }) ?? 0
            return index
        } catch {
            return 0
        }
    }
}

