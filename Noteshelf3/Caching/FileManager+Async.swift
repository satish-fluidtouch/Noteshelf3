//
//  FileManager+Async.swift
//  Noteshelf
//
//  Created by Akshay on 20/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
extension FileManager {

    private func coordinatedCopy(fromURL: URL, toURL: URL, force: Bool = false, onCompletion: ((Error?)->())?) {
        let document = FTNoteshelfDocument(fileURL: fromURL);
        let fileCoorinator = NSFileCoordinator.init(filePresenter: document)
        let readIntent = NSFileAccessIntent.readingIntent(with: fromURL,options: .withoutChanges);
        let writeIntent = NSFileAccessIntent.writingIntent(with: toURL,options: .forReplacing);
        fileCoorinator.coordinate(with: [readIntent,writeIntent]
                                  , queue: OperationQueue()) { error in
            if error != nil {
                onCompletion?(error)
            }
            else {
                var catchError: Error?
                do {
                    if force {
                        _ = try? self.removeItem(at: writeIntent.url)
                    }
                    _ = try self.copyItem(at: readIntent.url, to: writeIntent.url)

                } catch {
                    catchError = error
                }
                onCompletion?(catchError)
            }
        }
    }

    @discardableResult
    func coordinatedCopy(fromURL: URL, toURL: URL, force: Bool = false) throws -> Bool {
        let fileCoorinator = NSFileCoordinator.init(filePresenter: nil)
        var copyError: NSError?
        var catchError: Error?
        fileCoorinator.coordinate(readingItemAt: fromURL,
                                  options: NSFileCoordinator.ReadingOptions.withoutChanges,
                                  writingItemAt: toURL,
                                  options: NSFileCoordinator.WritingOptions.forReplacing,
                                  error: &copyError,
                                  byAccessor:{ (readingURL, writingURL) in
            do {
                if force {
                    _ = try? removeItem(at: writingURL)
                }
                _ = try copyItem(at: readingURL, to: writingURL)

            } catch {
                catchError = error
            }
        })
        if let error = copyError {
            throw error
        }
        if let catchError = catchError {
            throw catchError
        }
        return true
    }

    @discardableResult
    func coordinatedMove(fromURL: URL, toURL: URL) throws -> Bool {
        let fileCoorinator = NSFileCoordinator.init(filePresenter: nil);
        var moveError: NSError?
        var catchError: Error?
        fileCoorinator.coordinate(writingItemAt: fromURL,
                                  options: NSFileCoordinator.WritingOptions.forMoving,
                                  writingItemAt: toURL,
                                  options: NSFileCoordinator.WritingOptions.forReplacing,
                                  error: &moveError,
                                  byAccessor: { (fromWritingURL, toWritingURL) in
            do {
                try moveItem(at: fromWritingURL, to: toWritingURL)
            }
            catch {
                catchError = error
            }
        })
        if let error = moveError {
            throw error
        }
        if let catchError = catchError {
            throw catchError
        }
        return true
    }
}
