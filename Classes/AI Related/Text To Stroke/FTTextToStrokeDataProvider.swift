//
//  FTTextToStrokeDataProvider.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 12/07/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

typealias FTStrokeHashMap = [String: FTStrokeGlyphInfo]

class FTTextToStrokeDataProvider: NSObject {
    private(set) var referenePageSize = CGSize(width: 1347, height: 2448);
    private(set) var actualPageSize = CGSize(width: 10809, height: 19634);
    
     lazy var scale: CGFloat = {
        return self.referenePageSize.width/self.actualPageSize.width;
    }();
    
    private let onexGlyphHeight: CGFloat = 1358;
    var glyphHeight: CGFloat {
        return onexGlyphHeight * scale;
    }
    
    private var annotationFileName: String = "";
    private lazy var sqliteFileItem: FTNSqliteAnnotationFileItem? = {
        let annotationsPath = self.glyphFileURL.appending(component: "Annotations/\(self.annotationFileName)");
        let fileItem = FTNSqliteAnnotationFileItem(url: annotationsPath, isDirectory: false);
        return fileItem;
    }();
    
    private var strokeMapper = [String: [FTStroke]]();
    
    static let sharedInstance: FTTextToStrokeDataProvider = FTTextToStrokeDataProvider();
    private var strokeHashMap = FTStrokeHashMap();
    override init() {
        super.init();
        
        loadPageInfo();
        loadItems();
    }

    private let USE_UNICODE = true;
    func strokeInfoForWord(_ word:String) -> FTWordStrokeInfo {
        let info = FTWordStrokeInfo(with: word);
        word.forEach { eachChar in
            if let strokeInfo = self.strokeInfo(for: eachChar) {
                info.addStrokeInfo(strokeInfo);
            }
        }
        return info;
    }
    
    func strokeInfo(for char:Character) -> FTCharStrokeInfo? {
        let key: String
        if(USE_UNICODE) {
            let UTFCode = char.unicodeScalars.map{$0.value}.reduce(0, +);
            key = "\(UTFCode)";
        }
        else {
            key = String(char)
        }
        guard let strokeInfo = strokeHashMap[key] else {
            return nil;
        }
        
        var strokesToreturn = [FTStroke]();
        if let strokes = strokeMapper[key] {
            strokes.forEach { eachStroke in
                let stroke = eachStroke.duplicate();
                strokesToreturn.append(stroke);
            }
        }
        else  {
            let strokeBound = CGRect(x: strokeInfo.x
                                     , y: strokeInfo.y
                                     , width: strokeInfo.fontWidth
                                     , height: onexGlyphHeight);
            let scaledBound = CGRectScale(strokeBound, scale);

            self.sqliteFileItem?.annotations.forEach({ eachAnnotation in
                if let stroke = eachAnnotation as? FTStroke
                    ,eachAnnotation.boundingRect.intersects(scaledBound) {
                    strokesToreturn.append(stroke)
                }
            })
            strokeMapper[key] = strokesToreturn;
            return self.strokeInfo(for: char);
        }
        return FTCharStrokeInfo(char: String(char)
                                ,strokes: strokesToreturn
                                ,glyphInfo: strokeInfo
                                ,scale: scale);
    }
}

private extension FTTextToStrokeDataProvider {
    private func loadPageInfo() {
        do {
            let documentPlist = glyphFileURL.appending(component: DOCUMENT_INFO_FILE_NAME);
            let dictionray = try NSDictionary(contentsOf: documentPlist, error: ());
            if let pagesArray = dictionray.object(forKey: "pages") as? [[String:Any]],let firstPageInfo = pagesArray.first {
                let page = FTNoteshelfPage();
                page.updatePageAttributesWithDictionary(firstPageInfo);
                self.referenePageSize = page.pdfPageRect.size;
                self.annotationFileName = page.uuid;
                
                if let template = page.associatedPDFFileName {
                    let templatePath = glyphFileURL.appending(component: TEMPLATES_FOLDER_NAME).appending(component: template);
                    if let pdfFile = FTPDFKitFileItemPDF(url: templatePath, isDirectory: false) {
                        self.actualPageSize = pdfFile.pageRectOfPage(atNumber: page.associatedPDFKitPageIndex).size;
                    }
                }
            }
            else {
                fatalError("glyphs_font.ns: pagesArray not found");
            }
        }
        catch {
            fatalError("glyphs_font.ns: \(error)");
        }
    }
    
    private var glyphFileURL: URL {
        guard let packname = Bundle.main.url(forResource: "glyphs_font", withExtension: "ns") else {
            fatalError("glyphs_font.ns: File missing from bundle");
        }
        return packname;
    }
    
    private func loadItems() {
        if strokeHashMap.isEmpty
            ,let dataURL = Bundle.main.url(forResource: "stroke_text_map", withExtension: "json") {
            do {
                let jsonData = try Data(contentsOf: dataURL) ;
                strokeHashMap = try JSONDecoder().decode(FTStrokeHashMap.self, from: jsonData)
            }
            catch let error {
                debugLog("error: \(error)");
            }
        }
    }
}

private extension FTStroke {
    func duplicate() -> FTStroke {
        let stroke = FTStroke();
        stroke.isReadonly = self.isReadonly;
        stroke.version = self.version;
        stroke.strokeColor = self.strokeColor;
        stroke.strokeWidth = self.strokeWidth;
        stroke.penType = self.penType;
        stroke.boundingRect = self.boundingRect;
        
        stroke.segmentCount = self.segmentCount;

        stroke.segmentsTransientArray = self.segmentsTransientArray;
        stroke.segmentArray = self.segmentArray;

        return stroke;
    }
}
