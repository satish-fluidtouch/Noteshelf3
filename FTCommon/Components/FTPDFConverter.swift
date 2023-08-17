//
//  FTPDFConverter.swift
//  FTPDFConverter
//
//  Created by Akshay on 23/04/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import WebKit

let kPaperA4 = CGSize(width: 595.2, height: 841.8)
let kMarginsBasic = UIEdgeInsets(top: 10, left: 5, bottom: 5, right: 10)

public typealias FTConvertSuccess = (_ filePath:String) -> Void
public typealias FTConvertProgress = (_ progress:Float) -> Void
public typealias FTConvertFailure = (_ error:Error) -> Void

public extension NSError {
    class var importFailError: NSError {
        return NSError(domain: "NSFileImport",
                       code: CocoaError.fileNoSuchFile.rawValue,
                       userInfo: [NSLocalizedDescriptionKey : "File does not exists"]);
    }
}

private struct FTPrintDimensions {
    let paperSize:CGSize
    let margins: UIEdgeInsets

    static func standard() -> FTPrintDimensions {
        return FTPrintDimensions(paperSize: kPaperA4, margins: kMarginsBasic)
    }
}

public class FTPDFConverter: NSObject {

    public static let shared = FTPDFConverter()

    fileprivate var webview: WKWebView!
    private var onSuccess:FTConvertSuccess?
    private var onFailure:FTConvertFailure?
    private var progressBlock:FTConvertProgress?

    private var observerProgress: NSKeyValueObservation?

    public func convertToPDF(filePath:String,
                      view: UIView,
                      onSuccess:@escaping FTConvertSuccess,
                      onFailure:@escaping FTConvertFailure,
                      progress:FTConvertProgress?) {
        let url = URL(fileURLWithPath: filePath)
        if(FileManager().fileExists(atPath: url.path)) {
            self.onSuccess = onSuccess
            self.onFailure = onFailure
            self.progressBlock = progress
            self.loadWebview(url: url, on: view)
        } else {
            onFailure(NSError.importFailError)
        }
    }

    public func convertToPDF(url:URL,
                      view: UIView,
                      onSuccess:@escaping FTConvertSuccess,
                      onFailure:@escaping FTConvertFailure,
                      progress:FTConvertProgress?) {
        self.onSuccess = onSuccess
        self.onFailure = onFailure
        self.progressBlock = progress

        loadWebview(url: url, on: view)
    }

    private func loadWebview(url: URL, on view: UIView) {
        DispatchQueue.main.async {
            self.webview = WKWebView(frame: UIScreen.main.bounds)
            self.webview.isHidden = true
            #if DEBUG
            //        self.webview.isHidden = false
            //        self.webview.frame = CGRect(origin: .zero, size: CGSize(width: 500, height: 500))
            #endif
            self.webview.navigationDelegate = self
            view.addSubview(self.webview)

            if url.isFileURL {
                self.webview.loadFileURL(url, allowingReadAccessTo: url);
            } else {
                let request = URLRequest(url: url)
                self.webview.load(request)
            }
            self.observerProgress = self.webview.observe(\.estimatedProgress, options: .new) { [weak self] (webview, change) in
                let progress = Float(webview.estimatedProgress)
                self?.progressBlock?(progress)
            }
        }
    }
}

extension FTPDFConverter: WKNavigationDelegate {

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {

        if webView.isLoading { return }
        log("Webview load Finished")
        #if DEBUG
        webView.evaluateJavaScript("document.documentElement.outerHTML.toString()",
                                   completionHandler: { (html: Any?, _: Error?) in
                                    print("HTML\n-----------------------\n",html ?? "","\n-----------------------\n")
        })
        #endif

        webView.evaluateJavaScript("document.readyState") { [weak self](_, error) in
            if let nsError = error {
                self?.invalidateWebView()
                self?.onFailure?(nsError)
                return
            }
            self?.processWebViewForDimensions(completion: { (dimensions) in
                self?.renderPDF(dimensions: dimensions)
            })
        }
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        logError("Webview_load_failed", attributes:["path":webView.url?.path ?? "none"])
        self.invalidateWebView()
        self.onFailure?(error)
    }

    private func invalidateWebView() {
        self.webview.removeFromSuperview()
        self.webview = nil
        self.observerProgress?.invalidate()
        self.observerProgress = nil
    }
}


private extension FTPDFConverter {

    func renderPDF(dimensions:FTPrintDimensions) {

        log("Imported Doc dimensions SIZE: \(dimensions.paperSize), MAARGINS: \(dimensions.margins)")

        let paperRect = CGRect(origin: .zero, size: dimensions.paperSize);

        let margins = dimensions.margins
        let printWidth = paperRect.size.width - margins.left - margins.right
        let printHeight = paperRect.size.height - margins.top - margins.bottom
        let printableRect = CGRect(x:margins.left, y:margins.right, width:printWidth, height:printHeight);

        let render = UIPrintPageRenderer()
        render.addPrintFormatter(webview.viewPrintFormatter(), startingAtPageAt: 0)
        render.setValue(paperRect, forKey: "paperRect")
        render.setValue(printableRect, forKey: "printableRect")
        let data = render.getPDFData()
        if let fileURL = webview.url {
            let filename : String
            if fileURL.isFileURL {
                filename = fileURL.deletingPathExtension().lastPathComponent
            } else {
                let webTitle = webview.title?.validateFileName();
                if let title = webTitle, !title.isEmpty {
                    filename = title;
                }
                else {
                    filename = UUID().uuidString;
                }
            }
            let path = ("~/tmp/\(filename).pdf" as NSString).expandingTildeInPath
            (data as NSData).write(toFile: path, atomically: true)
            self.onSuccess?(path)
            self.invalidateWebView()
        } else {
            self.invalidateWebView()
            let error = NSError(domain: "com.fluidtouch.convert", code: 100, userInfo: [NSLocalizedDescriptionKey:"Converted URL not found"])
            self.onFailure?(error)
            logError("Convert_web_URL_not_found")
            #if DEBUG
            print("Should not reach here Webview loaded URL not found")
            #endif
        }
    }


    func processWebViewForDimensions(completion:@escaping ((_ dimensions:FTPrintDimensions) -> Void)) {
        if let pathExtension = self.webview?.url?.pathExtension.lowercased() {
            switch pathExtension {
            case "doc", "docx":
                self.processDocFile(completion: completion)
            case "ppt","pptx":
                self.processPPTFile(completion: completion)
            case "xls":
                self.processLegacyExcelFile(completion: completion)
            case "xlsx":
                self.processExcelFile(completion: completion)
            default:
                completion(FTPrintDimensions.standard())
            }
        }
    }

    //Doc file
    func processDocFile(completion:@escaping ((_ dimensions:FTPrintDimensions) -> Void)) {

        guard webview != nil else {
            completion(FTPrintDimensions.standard())
            return
        }

        webview?.evaluateJavaScript("document.head.getElementsByTagName(\"style\")[2].innerText") { [weak self](text, _) in

            self?.log("DOCX style \(text ?? "Nil")")

            guard let styleText = text as? String else {
                completion(FTPrintDimensions.standard())
                self?.logImportError()
                return
            }

            var printableWidth: CGFloat = 0.0
            var minHeight: CGFloat = 0.0
            var margins: UIEdgeInsets = .zero

            let scanner = Scanner.init(string: styleText);
            if !(scanner.scanUpToString("width: ")?.isEmpty ?? true) {
                _ = scanner.scanString("width: ");
                let widthString = scanner.scanUpToString(";");
                if let width = widthString?.floatValue {
                    printableWidth = CGFloat(width)
                }
                
                _ = scanner.scanUpToString("padding-left: ");
                _ = scanner.scanString("padding-left: ");
                let leftPadding = scanner.scanUpToString(";")
                
                _ = scanner.scanUpToString("padding-right: ");
                _ = scanner.scanString("padding-right: ");
                let rightPadding = scanner.scanUpToString(";")

                _ = scanner.scanUpToString("min-height: ");
                _ = scanner.scanString("min-height: ");
                let minHeightString = scanner.scanUpToString(";")

                if let _minHeight = minHeightString?.floatValue {
                    minHeight = CGFloat(_minHeight)
                }

                _ = scanner.scanUpToString("padding-top: ");
                _ = scanner.scanString("padding-top: ");
                let topPadding = scanner.scanUpToString(";")

                _ = scanner.scanUpToString("padding-bottom: ");
                _ = scanner.scanString("padding-bottom: ");
                let bottomPadding = scanner.scanUpToString(";")
                
                if let left = leftPadding?.floatValue, let right = rightPadding?.floatValue, let top = topPadding?.floatValue, let bottom = bottomPadding?.floatValue {
                    margins = UIEdgeInsets(top: CGFloat(top), left: CGFloat(left), bottom: CGFloat(bottom), right: CGFloat(right))
                }

                #if DEBUG
                print("Width", printableWidth, "Insets", margins, "min height", minHeight)
                #endif
            }

            let paperWidth = printableWidth + margins.left + margins.right
            let paperHeight = minHeight

            let paperSize = FTPageSizeHelper.size(width: paperWidth, height: paperHeight).standardized
            let dimensions = FTPrintDimensions(paperSize: paperSize, margins: margins)
            completion(dimensions)
        }
    }

    //PPT file
    func processPPTFile(completion:@escaping ((_ dimensions:FTPrintDimensions) -> Void)) {

        guard webview != nil else {
            completion(FTPrintDimensions.standard())
            return
        }

        webview?.evaluateJavaScript("document.head.getElementsByTagName(\"style\")[1].innerText") { [weak self](text, _) in
            self?.log("ppt style \(text ?? "Nil")")
            guard let styleText = text as? String else {
                completion(FTPrintDimensions.standard())
                self?.logImportError()
                return
            }

            var width: CGFloat = 0.0
            var height: CGFloat = 0.0

            let scanner = Scanner.init(string: styleText);
            if (!(scanner.scanUpToString("width: ")?.isEmpty ?? true)) {
                _ = scanner.scanString("width: ");
                let widthString = scanner.scanUpToString(";");
                if let _width = widthString?.floatValue {
                    width = CGFloat(_width)
                }

                _ = scanner.scanUpToString("height: ");
                _ = scanner.scanString("height: ");
                let heightString = scanner.scanUpToString(";");
                if let _height = heightString?.floatValue {
                    height = CGFloat(_height)
                }

                #if DEBUG
                print("PPT: Width", width, "Height", height)
                #endif
            }

            let dimensions = FTPrintDimensions(paperSize: CGSize(width:width, height:height), margins: .zero)
            completion(dimensions)
        }
    }

    //Excel
    func processExcelFile(completion:@escaping ((_ dimensions:FTPrintDimensions) -> Void)) {

        guard webview != nil else {
            completion(FTPrintDimensions.standard())
            return
        }

        webview?.evaluateJavaScript("document.body.getElementsByTagName(\"table\")[0].style.width") { [weak self](value, _) in

            self?.log("XLSX style \(value ?? "Nil")")

            guard let widthString = (value as? NSString)?.replacingOccurrences(of: "px", with: "") else {
                completion(FTPrintDimensions.standard())
                self?.logImportError()
                return
            }
            let width: CGFloat = CGFloat((widthString as NSString).floatValue)
            let height: CGFloat = kPaperA4.height

            let dimensions = FTPrintDimensions(paperSize: CGSize(width:width, height:height), margins: kMarginsBasic)
            completion(dimensions)
        }
    }

    func processLegacyExcelFile(completion:@escaping ((_ dimensions:FTPrintDimensions) -> Void)) {

        guard webview != nil else {
            completion(FTPrintDimensions.standard())
            return
        }

        webview?.evaluateJavaScript("document.body.scrollWidth") { [weak self](value, _) in

            self?.log("XLS style \(value ?? "Nil")")

            guard let widthValue = (value as? NSNumber) else {
                completion(FTPrintDimensions.standard())
                self?.logImportError()
                return
            }
            let width: CGFloat = CGFloat(widthValue.floatValue)
            let widthRatio = width/kPaperA4.width
            let height: CGFloat = kPaperA4.height*widthRatio
            #if DEBUG
            print("Excel: Width", width, "Height", height)
            #endif
            let dimensions = FTPrintDimensions(paperSize: CGSize(width:width, height:height), margins: kMarginsBasic)
            completion(dimensions)
        }
    }

    func logImportError() {
        let pathExtension = self.webview?.url?.pathExtension.lowercased() ?? "None"
        logError("IMPORT_WEB_JS_ERROR", attributes: ["type":pathExtension])
    }
}


extension FTPDFConverter {
    func logError(_ name: String, attributes: [String: Any]? = nil) {
        #if !NOTESHELF_ACTION
        //TODO: By Siva
//        FTLogError("IMPORT_WEB_JS_ERROR", attributes: attributes)
        #endif
    }

    func log(_ string: String) {
        #if !NOTESHELF_ACTION
        //TODO: By Siva
//        FTCLSLog(string)
        #endif
    }
}
