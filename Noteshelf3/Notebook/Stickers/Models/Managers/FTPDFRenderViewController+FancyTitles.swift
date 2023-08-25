//
//  FTPDFRenderViewController_FancyTitles.swift
//  Noteshelf3
//
//  Created by Sameer on 06/03/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import SVGKit

struct FTFancyItem {
    var selectedFont: UIFont
    var selectedFontStyle: FTFancyFonts
    var selectedStyle: FTFancyStyles
    var selectedColor: String
    var size: CGFloat
    var selectedGradient: FTStyledGradient
    var plainText: String

    init(selectedFont: UIFont, selectedStyle: FTFancyStyles, selectedColor: String, size: CGFloat, selectedGradient: FTStyledGradient, selectedFontStyle: FTFancyFonts, plainText: String) {
        self.selectedFont = selectedFont
        self.selectedStyle = selectedStyle
        self.selectedColor = selectedColor
        self.size = size
        self.selectedGradient = selectedGradient
        self.selectedFontStyle = selectedFontStyle
        self.plainText = plainText
    }
}

enum FTStyledGradient: String, CaseIterable {
    case blue
    case green
    case mint
}

enum FTFancyStyles: String {
    case style1 = "Style 1"
    case style2 = "Style 2"
    case style3 = "Style 3"
}

enum FTBistroStyledFonts: String {
    case BistroSansLine = "BistroSans-Line"
    case BistroSansFill = "BistroSans-Fill"
    case BistroSansSlant = "BistroSans-Slant"
    case BistroSansBold = "BistroSans-Bold"
}


enum FTFancyFonts: String, CaseIterable {
    case Tortilla = "Tortilla"
    case HighLow = "High & Low"
    case memorita = "memorita"
    case AlonaManhatan = "Alona Manhatan"
    case Chiprush = "Chiprush"
    case Garfolk = "Garfolk"
    case CatalinaAvalonSans = "Catalina Avalon Sans"
    case Bistro = "Bistro Sans"
    case BistroSansBold = "BistroSans-Bold"
    case BistroSansLine = "BistroSans-Line"

    func maxFontSize() -> CGFloat {
        var maxSize = CGFloat.zero
        switch self {
        case .HighLow, .Chiprush, .Garfolk:
            maxSize = 100
        case .Tortilla:
            maxSize = 120
        case .memorita, .AlonaManhatan, .Bistro, .CatalinaAvalonSans,.BistroSansBold,.BistroSansLine:
            maxSize = 140
        }
        return maxSize
    }

    func minFontSize() -> CGFloat {
        var minSize = CGFloat.zero
        switch self {
        case .HighLow, .Chiprush, .Garfolk:
            minSize = 70
        case .Tortilla:
            minSize = 90
        case .memorita, .AlonaManhatan, .Bistro, .CatalinaAvalonSans,.BistroSansBold,.BistroSansLine:
            minSize = 110
        }
        return minSize
    }
}

struct TextPath {
    let cgPath: CGPath
    let font: UIFont
    let maxHeight: CGFloat

    init(cgPath: CGPath, font: UIFont, maxHeight: CGFloat) {
        self.cgPath = cgPath
        self.font = font
        self.maxHeight = maxHeight
    }
}

struct SVGData {
    let svg: String
    let size: CGSize

    init(svg: String, size: CGSize) {
        self.svg = svg
        self.size = size
    }
}

class FTFancyTitleGenerator: NSObject {
    var fancyItem : FTFancyItem?
    var finalText = ""
    var maxFontSize :CGFloat = .zero
    var selectedFontStyle = FTFancyFonts.Tortilla

    convenience init(fancyItem: FTFancyItem? = nil, finalText: String = "", maxFontSize: CGFloat, selectedFontStyle: FTFancyFonts = FTFancyFonts.Tortilla) {
        self.init()
        self.fancyItem = fancyItem
        self.finalText = finalText
        self.maxFontSize = maxFontSize
        self.selectedFontStyle = selectedFontStyle
    }
    private func getExceedCharactersFromGivenString(attributedString: NSAttributedString, maxWidth: CGFloat) -> Int {
        var minValue = 0
        var maxValue = attributedString.length - 1

        while minValue <= maxValue {
            let mid = (minValue + maxValue) / 2
            let subString = attributedString.attributedSubstring(from: NSMakeRange(0, mid + 1))
            let subStringWidth = subString.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil).width
            if subStringWidth <= maxWidth {
                minValue = mid + 1
            } else {
                maxValue = mid - 1
            }
        }
        return maxValue
    }
    func generateImage(for fancytitlestring: NSAttributedString, with item: FTFancyItem,viewwidth:Double) -> UIImage? {

        let attributedString = NSAttributedString(string: fancytitlestring.string, attributes: [.font: UIFont.systemFont(ofSize: 18)])
        let size = CGSize(width: CGFloat.infinity, height: CGFloat.infinity)
        let boundingRect = attributedString.boundingRect(with: size, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)

//
//       let stringWidth = fancytitlestring.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil).width
        let stringWidth = boundingRect.width
        var mutableAttributedString = NSMutableAttributedString()
        if stringWidth > viewwidth {
            let charactersToKeep = getExceedCharactersFromGivenString(attributedString: fancytitlestring, maxWidth: viewwidth)
            mutableAttributedString = NSMutableAttributedString(attributedString: fancytitlestring)
            mutableAttributedString.deleteCharacters(in: NSMakeRange(charactersToKeep, fancytitlestring.length - charactersToKeep))
            mutableAttributedString.append(NSAttributedString("..."))
            mutableAttributedString.addAttributes([.font: item.selectedFont], range: NSMakeRange(charactersToKeep,mutableAttributedString.length - charactersToKeep))
        }

        let outPut = svgPathsForAttributedString(string: stringWidth > viewwidth ? mutableAttributedString : fancytitlestring)
        let rawPath = outPut.0
        fancyItem = item
        let svg_path = svg(fromPath: rawPath)
        let pathBounds = rawPath.boundingBoxOfPath
        var  matrix = CGAffineTransform(scaleX: 1, y: -1)
        matrix = matrix.translatedBy(x: 0, y: -pathBounds.size.height)
        let color = item.selectedColor
        let _formattedPath = constructFormattedPath(with: outPut.1, item: item)
        let newPathWithNewOffset = _formattedPath.1
        let formattedPath = _formattedPath.0

        //Single Color
        var path = """
                      <path id="textPath" d="\(svg_path)" fill="\(color)"></path>
                   """
        if item.selectedStyle == .style2 {
            //Mutiple colors
            path = formattedPath
        } else if item.selectedStyle == .style3 && shouldApplyGradient(for: item) {
            //Gradient Colors
            if item.selectedFontStyle == .Bistro {
                path = formattedPath
            } else {
                let colors = colorsForGradient(selectedGradient: item.selectedGradient)
//                    path = applyGradient(for: outPut.1)
                path = """
                          <path id="textPath" d="\(svg_path)" fill="url(#Graident)"
                          ></path>
                           <defs>
                           <linearGradient id="Graident" x1="0%" y1="0%" x2="0%" y2="100%">
                           <stop offset="0" stop-color="\(colors.0)"/>
                           <stop offset="0.505208" stop-color="\(colors.0)"/>
                           <stop offset="0.645833" stop-color="\(colors.1)"/>
                           <stop offset="1" stop-color="\(colors.1)"/>
                           </linearGradient>
                           </defs>
                        """
            }
        }
        var xOffset = rawPath.boundingBoxOfPath.origin.x
        var yOffset = rawPath.boundingBoxOfPath.origin.y
        var frameMaxSize = maxSizeFor(string: stringWidth > viewwidth ? mutableAttributedString : fancytitlestring)
        if item.selectedFontStyle == .Bistro {
            frameMaxSize = sizeForBistro(string: NSAttributedString(string: ""), size: item.size)
        }
        let width = frameMaxSize.width + 20
        let height = frameMaxSize.height
        if item.selectedStyle == .style2 {
            xOffset = newPathWithNewOffset.boundingBoxOfPath.origin.x
            yOffset = newPathWithNewOffset.boundingBoxOfPath.origin.y
        }
        if item.selectedFontStyle == .Bistro && item.selectedStyle == .style3 {
            xOffset = newPathWithNewOffset.boundingBoxOfPath.origin.x
            yOffset = newPathWithNewOffset.boundingBoxOfPath.origin.y
        }
        let svg = """
                    <svg width="\(width)" height="\(height)" viewBox="\(xOffset) \(yOffset) \(width) \(height)" xmlns="http://www.w3.org/2000/svg">
                \(path)
                </svg>
                """
        let svgData = SVGData(svg: svg, size: CGSize(width: width, height: height))
        return imageFromSvg(data: svgData)
    }

    private func imageFromSvg(data: SVGData) -> UIImage? {
        var imageToReturn: UIImage?
        let path = data.svg
        if let data = path.data(using: .utf8) {
            if let svg = SVGKImage(data: data) {
                if let image = svg.uiImage {
                    imageToReturn = image
                    print(image)
                }
            }
        }
        return imageToReturn
    }

    private func shouldApplyGradient(for item: FTFancyItem) -> Bool {
        if item.selectedStyle == .style3 {
            if item.selectedFontStyle == .HighLow {
                return false
            }
        }
        return true
    }

    private func colorsForGradient(selectedGradient: FTStyledGradient) -> (String, String) {
        var color1 = ""
        var color2 = ""
        if selectedGradient == .blue {
            color1 = "#151F5C"
            color2 = "#1FA9EC"
        } else if selectedGradient == .green {
            color1 = "#1A5B14"
            color2 = "#349810"
        }else if selectedGradient == .mint {
            color1 = "#4ED1DA"
            color2 = "#1A868D"
        }
        return (color1, color2)
    }

    private func constructFormattedPath(with paths: [TextPath], item: FTFancyItem) -> (String, CGMutablePath)  {
        var path = ""
        let newMutablePath = CGMutablePath()
        let maxHeight: CGFloat = getMaxHeight(for: paths)
        let colors = ["#BB4AD8", "#4454CC", "#5FB3DA","#ABD65E", "#E9C955", "#CB3A2D"]
        for (index, eachPath) in paths.enumerated() {
            let finalPath = eachPath.cgPath
            let transformedPath = applyTransformationfor(cgPath: finalPath, with: maxHeight)
            newMutablePath.addPath(transformedPath)
            let nevSvgPath = svg(fromPath: transformedPath)
            var color = colors[index % 6];
            var svg = ""
            if item.selectedFontStyle == .Bistro {
                    let font = eachPath.font
                    if font == UIFont(name: FTBistroStyledFonts.BistroSansBold.rawValue, size: font.pointSize) {
                        color = "#000000"
                    } else {
                        color = "#26C8A1"
                    }
                    svg = """
                            <path id="textPath" d="\(nevSvgPath)"  fill="\(color)"
                            ></path>
                            """
            } else {
                 svg = """
                             <path id="textPath" d="\(nevSvgPath)"  fill="\(color)"
                             ></path>
                          """
            }
            path.append(svg)
        }

        return (path, newMutablePath)
    }

    private func getMaxHeight(for textPaths: [TextPath]) -> CGFloat {
        var maxHeight: CGFloat = 0
        textPaths.forEach { eachTextPath in
            if maxHeight < eachTextPath.maxHeight {
                maxHeight = eachTextPath.maxHeight
            }
        }
        return maxHeight
    }

    private func svg(fromPath path: CGPath) -> String {
        var data = Data()
        path.apply(info: &data) { userData, elementPtr in
            var data = userData!.assumingMemoryBound(to: Data.self).pointee
            let element = elementPtr.pointee
            switch element.type {
            case .moveToPoint:
                let point = element.points.pointee
                data.append(String(format: "M%.2f,%.2f", point.x, point.y).data(using: .utf8)!)
                break;
            case .addLineToPoint:
                let point = element.points.pointee
                data.append(String(format: "L%.2f,%.2f", point.x, point.y).data(using: .utf8)!)
                break;
            case .addQuadCurveToPoint:
                let ctrl = element.points.pointee
                let point = element.points.advanced(by: 1).pointee

                data.append(String(format: "Q%.2f,%.2f,%.2f,%.2f", ctrl.x, ctrl.y, point.x, point.y).data(using: .utf8)!)
                break
            case .addCurveToPoint:
                let ctrl1 = element.points.pointee
                let ctrl2 = element.points.advanced(by: 1).pointee
                let point = element.points.advanced(by: 2).pointee
                data.append(String(format: "C%.2f,%.2f,%.2f,%.2f,%.2f,%.2f", ctrl1.x, ctrl1.y, ctrl2.x, ctrl2.y, point.x, point.y).data(using: .utf8)!)
                break
            case .closeSubpath:
                data.append("Z".data(using: .utf8)!)
                break
            @unknown default:
                break
            }
            userData!.assumingMemoryBound(to: Data.self).pointee = data
        }

        return String(bytes: data, encoding: .utf8)!
    }

    private func svgPathsForAttributedString(string: NSAttributedString) -> (CGPath, [TextPath]) {
        var individualPaths = [TextPath]()
        let mutablePath = CGMutablePath()
        let framesetter = CTFramesetterCreateWithAttributedString(string)
        let textRange = CFRangeMake(0, string.length)
        let frameSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, textRange, nil, .zero, nil)
        let path = CGPath(rect: CGRect(origin: .zero, size: frameSize), transform: nil)
        let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, string.length), path, nil)
        let lines = CTFrameGetLines(frame) as! [CTLine]
        var origins = [CGPoint](repeating: CGPoint.zero, count: lines.count)
        CTFrameGetLineOrigins(frame, CFRangeMake(0, lines.count), &origins)
        var originItr = origins.makeIterator()
        for line in lines {
            let lineRef = line
            var ascent: CGFloat = 0
            var descent: CGFloat = 0
            var leading: CGFloat = 0
            let runs = CTLineGetGlyphRuns(lineRef) as! [CTRun]
            CTLineGetTypographicBounds(line, &ascent, &descent, &leading)
            for run in runs {
                //individualPaths.removeAll()
                let attributes = CTRunGetAttributes(run) as! [NSAttributedString.Key: Any]
                let font = attributes[.font] as! UIFont
                let glyphCount = CTRunGetGlyphCount(run)
                let positions = CTRunGetPositionsPtr(run)
                var rt_ascent = CGFloat(0.0)
                var rt_descent = CGFloat(0.0)
                var rt_leading = CGFloat(0.0)
                let _ = CTRunGetTypographicBounds(run, CFRangeMake(0, glyphCount), &rt_ascent, &rt_descent, &rt_leading)
                for i in 0 ..< glyphCount {
                    let range = CFRangeMake(i, 1)
                    var glyphs = [CGGlyph](repeating: 0, count: 1)
                    CTRunGetGlyphs(run, range, &glyphs)
                    let cgPath = CTFontCreatePathForGlyph(font, glyphs[0], nil)
                    var position = CGPoint.zero
                    if positions == nil {
                        CTRunGetPositions(run, range, &position)
                    } else {
                        position = positions?[i] ?? .zero
                    }
                    if let path = cgPath {
                        let pathBounds = path.boundingBoxOfPath
                        //Adjust the path to (0,0)
                        let xCorrection = -path.boundingBoxOfPath.origin.x
                        let yCorrection = -path.boundingBoxOfPath.origin.y
                        var transform = CGAffineTransform(translationX: xCorrection, y: yCorrection)
                        if let cgPath = path.copy(using: &transform) {
                            //Offset based on glyph position
                            let offset = CGPoint(x:   position.x + pathBounds.origin.x, y: pathBounds.origin.y)
                            var glyphTransform = CGAffineTransform(translationX: offset.x, y: offset.y)
                            if let tranformedPath = cgPath.copy(using: &glyphTransform) {
                                let textPath = TextPath(cgPath: tranformedPath, font: font, maxHeight: tranformedPath.boundingBoxOfPath.height)
                                individualPaths.append(textPath)
                                mutablePath.addPath(tranformedPath)
                            }
                        }
                    }
                }
            }
        }
        let flippedPath = applyTransformationfor(cgPath: mutablePath, with: mutablePath.boundingBoxOfPath.height)
        return (flippedPath, individualPaths)
    }

    private func applyTransformationfor(cgPath: CGPath, with maxHeight: CGFloat) -> CGPath {
        var finalPath = cgPath
        var  matrix = CGAffineTransform(scaleX: 1, y: -1)
        matrix = matrix.translatedBy(x: 0, y: -maxHeight)
        if let copyPath = cgPath.copy(using: &matrix) {
            finalPath = copyPath
        }
        return finalPath
    }

    internal func maxSizeFor(string: NSAttributedString) -> CGSize {
        let framesetter = CTFramesetterCreateWithAttributedString(string)
        let textRange = CFRangeMake(0, string.length)
        let frameSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, textRange, nil, .zero, nil)
        return frameSize
    }

    private func sizeForBistro(string: NSAttributedString, size: CGFloat) -> CGSize {
        let font = UIFont(name: FTBistroStyledFonts.BistroSansLine.rawValue, size: fancyItem?.size ??  size)!
        let string = NSAttributedString(string: fancyItem?.plainText ?? "Fancy Title", attributes: [.font: font])
        return maxSizeFor(string: string)
    }

    func formatString(for attrString: NSAttributedString, item: FTFancyFonts, font: UIFont) -> NSAttributedString {
        let fontType = FTFancyFonts(rawValue: font.fontName)
        let minFontSize = item.minFontSize()
        var maxFontSize = item.maxFontSize()
        var maxWidth = UIScreen.main.bounds.width
        var string = attrString
        if item == .Bistro {
            string = NSAttributedString(string: attrString.string, attributes: [.font: UIFont(name: FTBistroStyledFonts.BistroSansLine.rawValue, size: font.pointSize)])
        }
        maxWidth -= 40
        guard  let font = UIFont(name: font.fontName, size: maxFontSize) else{
            return attrString
        }
        var _fontSizeToApply : CGFloat = maxFontSize
        let newString = NSAttributedString(string: string.string, attributes: [NSAttributedString.Key.font : font])
        let size = newString.size()
        let textSize = newString.requiredSizeForAttributedStringConStraint(to: CGSize(width:maxWidth, height: CGFloat.greatestFiniteMagnitude))
        if size.width < maxWidth {
            _fontSizeToApply = maxFontSize
        } else {
            while true {
                if maxFontSize >= minFontSize {
                    let newString = stringWithFontSize(str: string.string, size: maxFontSize, font: font)
                    let size = newString.size()
                    if size.width <= maxWidth {
                        _fontSizeToApply = maxFontSize
                        return newString
                    } else {
                        maxFontSize -= 1
                    }
                } else {
                    func truncateStringIfNeeded(attrString: NSAttributedString) -> NSAttributedString {
                        let truncationRange = NSRange(location: 0, length: attrString.length - 1)
                        let truncationString = attrString.attributedSubstring(from: truncationRange)
                        let newFont = UIFont(name: font.fontName, size: CGFloat(minFontSize))
                        var attrs = [NSAttributedString.Key.font : newFont] as [NSAttributedString.Key : Any]
                        let newString = stringWithFontSize(str: truncationString.string, size: minFontSize, font: font)
                        let size = newString.size()
                        if size.width > maxWidth {
                            return truncateStringIfNeeded(attrString: newString)
                        } else {
                            let newString = newStringWithFont(attr: newString, font: newFont!)
                            if selectedFontStyle != .Bistro {
                                let ellipses = NSAttributedString(string: "...", attributes: attrs)
                                let truncationRange = NSRange(location: 0, length: newString.length - 2)
                                var truncationString = NSMutableAttributedString(attributedString:  newString.attributedSubstring(from: truncationRange))
                                truncationString.append(ellipses)
                                return truncationString
                            } else {
                                return newString
                            }
                        }
                    }
                    let newString = stringWithFontSize(str: string.string, size: minFontSize, font: font)
                    return truncateStringIfNeeded(attrString: newString)
                }
            }
        }
        let validFont = UIFont(name: font.fontName, size: _fontSizeToApply) ?? font
        return newStringWithFont(attr: string, font: validFont)
    }

    private func stringWithFontSize(str: String, size: CGFloat, font: UIFont) -> NSAttributedString {
        let font = UIFont(name: font.fontName, size: size)
        var attrs = [NSAttributedString.Key.font : font] as [NSAttributedString.Key : Any]
        return NSAttributedString(string: str, attributes: attrs)
    }

    private func newStringWithFont(attr: NSAttributedString, font: UIFont) -> NSAttributedString {
        let attrs = [NSAttributedString.Key.font : font] as [NSAttributedString.Key : Any]
        var attrString = NSAttributedString(string: attr.string, attributes: attrs)
        finalText = attrString.string
        if selectedFontStyle == .Bistro {
            attrString = newStringForBistroFontForSize(size: font.pointSize, string: attr)
        }
        maxFontSize = font.pointSize
        return attrString
    }

     func newStringForBistroFontForSize(size: CGFloat, string: NSAttributedString) -> NSAttributedString {
        var fontName = FTBistroStyledFonts.BistroSansLine.rawValue
        if fancyItem?.selectedStyle == .style3 {
            fontName = FTBistroStyledFonts.BistroSansSlant.rawValue
        }
        var selectedFont = UIFont(name: fontName, size: size)
        if fancyItem?.selectedStyle == .style2 {
            selectedFont = UIFont(name: FTBistroStyledFonts.BistroSansFill.rawValue, size: size)
        }
        let font = UIFont(name: selectedFontStyle.rawValue, size: size)
        let attrs1 = [NSAttributedString.Key.font : selectedFont]
        let attrs = [NSAttributedString.Key.font : UIFont(name: FTBistroStyledFonts.BistroSansBold.rawValue, size: size), NSAttributedString.Key.foregroundColor : UIColor.black]
        let attr = NSAttributedString(string: string.string, attributes: attrs as [NSAttributedString.Key : Any])
        let ellipses = NSAttributedString(string: "...", attributes: attrs as [NSAttributedString.Key : Any])
        let truncationRange = NSRange(location: 0, length: attr.length - 2)
         let truncationString = NSMutableAttributedString(attributedString:  attr.attributedSubstring(from: truncationRange))
        truncationString.append(ellipses)
        finalText = truncationString.string
        let mutableAttr = NSMutableAttributedString(attributedString: NSAttributedString(string: truncationString.string, attributes: attrs1 as [NSAttributedString.Key : Any]))
        mutableAttr.append(NSAttributedString(string: "\n"))
        mutableAttr.append(truncationString)
        return mutableAttr
    }
}
