//
//  FTPDFDownloadOperation.swift
//  Noteshelf3
//
//  Created by Fluid Touch on 19/06/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTPDFDownloadOperation: Operation, URLSessionDownloadDelegate {
    let fileUrl: URL
    weak var delegate: FTPDFDownLoadDelegate?
    private var _executing: Bool = false
    private var _finished: Bool = false
    var completion: (() -> Void)?
    override var isAsynchronous: Bool {
        return true
    }
    
    override var isExecuting: Bool {
        return _executing
    }
    
    override var isFinished: Bool {
        return _finished
    }
    
    init(fileUrl: URL) {
        self.fileUrl = fileUrl
    }
    
    override func start() {
        if isCancelled {
            finish()
            return
        }
        _executing = true
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        let task = session.downloadTask(with: fileUrl)
        task.resume()
    }
    
    func finish() {
        _executing = false
        _finished = true
        completion?()
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let tempDirURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let destinationURL = tempDirURL.appendingPathComponent(fileUrl.deletingPathExtension().lastPathComponent).appendingPathExtension("pdf")
        try? FileManager.default.removeItem(at: destinationURL)
        do {
            try FileManager.default.moveItem(at: location, to: destinationURL)
            self.delegate?.startPDFImport(url: destinationURL, completionHandler: { success, items in
                self.finish()
            })
        } catch {
            finish()
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if error != nil {
            finish()
        }
    }
}
