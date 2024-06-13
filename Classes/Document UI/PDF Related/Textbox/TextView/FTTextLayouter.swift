//
//  FTTextLayouter.swift
//  Noteshelf
//
//  Created by Akshay on 27/07/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit


enum DrawingOption: CaseIterable {
   case disableBackgrounds
   case disableGlyphs
   case disableFlipping
}

class FTTextLayouter {
    private var _textStorage: NSTextStorage
    private var _textContainer: NSTextContainer
    private var _layoutManager: NSLayoutManager

    private var _layoutSize: CGSize
    private var _usedSize: CGSize = .zero

    var usedSize : CGSize {
        return _usedSize
    }

    init(attributedString: NSAttributedString, constraints: CGSize) {
        _textStorage = NSTextStorage(attributedString: attributedString)

        _layoutManager = NSLayoutManager()
        _textStorage.addLayoutManager(_layoutManager)

        _layoutSize = constraints
        if _layoutSize.width <= 0 {
            _layoutSize.width = CGFloat.greatestFiniteMagnitude
        }
        if _layoutSize.height <= 0 {
            _layoutSize.height = CGFloat.greatestFiniteMagnitude
        }

        _textContainer = NSTextContainer(size: _layoutSize)
        _textContainer.lineFragmentPadding = 0

        _layoutManager.addTextContainer(_textContainer)

        _usedSize = CGSize(width: widthOfLongestLine(), height: totalHeightUsed())
    }

    static func image(from attributedString: NSAttributedString) -> UIImage? {
        let transformedString = attributedString

        // Create an OUITextLayout
        let textLayout = FTTextLayouter(attributedString: transformedString, constraints: CGSize(width: 500.0, height: Double.greatestFiniteMagnitude))

        let drawingBounds = CGRect(origin: .zero, size: textLayout.usedSize)
        guard let ftcontext = FTImageContext.imageContext(drawingBounds.size, scale: 0) else {
            return nil;
        }
        textLayout.drawFlipped(in: ftcontext.cgContext, bounds: drawingBounds)
        let image = ftcontext.uiImage();
        return image
    }

    func draw(in context: CGContext) {
        let bounds = CGRect(origin: .zero, size: _usedSize)
        draw(in: context, bounds: bounds, options: [.disableFlipping])
    }

    func drawFlipped(in context: CGContext, bounds: CGRect) {
        draw(in: context, bounds: bounds, options:[])
    }

    func draw(in context: CGContext, bounds: CGRect, options: [DrawingOption]) {
        let characterLength = _textStorage.length
        if (characterLength == 0) {
            return;
        }

        UIGraphicsPushContext(context);
        let shouldFlip = !options.contains(.disableFlipping)
        let shouldDrawForeground = !options.contains(.disableGlyphs);
        let shouldDrawBackground = !options.contains(.disableBackgrounds);

        if (!shouldFlip) {
            context.saveGState();
            let transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 2 * bounds.origin.y + bounds.size.height)
            context.concatenate(transform)
        }

        let currentPoint = bounds.origin;
        let glyphRange = _layoutManager.glyphRange(for: _textContainer)

        if (shouldDrawBackground) {
            _layoutManager.drawBackground(forGlyphRange:glyphRange, at:currentPoint);
        }

        if (shouldDrawForeground) {
            _layoutManager.drawGlyphs(forGlyphRange:glyphRange, at:currentPoint);
        }

        if (!shouldFlip) {
            context.restoreGState();
        }
        UIGraphicsPopContext();
    }
}

private extension FTTextLayouter {
    func totalHeightUsed() -> CGFloat {
        let glyphCount = _layoutManager.numberOfGlyphs
        if glyphCount == 0 {
            return 0.0
        }
        _layoutManager.lineFragmentRect(forGlyphAt: glyphCount - 1, effectiveRange: nil)

        var textContainer: NSTextContainer?
        var totalHeight: CGFloat = 0
        let textContainers = _layoutManager.textContainers
        let tcCount = textContainers.count
        for tcIndex in 0..<tcCount - 1 {
            textContainer = textContainers[tcIndex]
            let containerSize = textContainer?.size
            totalHeight += containerSize?.height ?? 0.0
        }

        textContainer = textContainers.last
        var usedRect: CGRect?
        if let textContainer = textContainer {
            usedRect = _layoutManager.usedRect(for: textContainer)
        }
        totalHeight += usedRect?.size.height ?? 0.0

        return totalHeight
    }

    func widthOfLongestLine() -> CGFloat {
        let characterCount = _textStorage.length
        if characterCount == 0 {
            return 0.0
        }

        let glyphRange = _layoutManager.glyphRange(forCharacterRange: NSRange(location: 0, length: characterCount), actualCharacterRange: nil)
        if glyphRange.length == 0 {
            return 0.0
        }

        var glyphLocation = glyphRange.location
        let glyphEnd = glyphRange.location + glyphRange.length

        var maximumLineLength: CGFloat = 0.0
        while glyphLocation < glyphEnd {
            // The line fragment rect isn't what we want (if text is right aligned, it will span the width of the line from the left edge of the text container).  We want the glyph bounds...
            var lineGlyphRange = NSRange()
            _layoutManager.lineFragmentUsedRect(forGlyphAt: glyphLocation, effectiveRange: &lineGlyphRange)

            // Look at the last character of the given line.  If it is a line breaking character, don't include it in the measurements.  Otherwise, the glyph bounds will extend to the end of the text container.
                var lineCharRange = _layoutManager.characterRange(forGlyphRange:lineGlyphRange, actualGlyphRange:nil);
                var clippedGlyphRange = lineGlyphRange;
                if (lineCharRange.length != 0) {
                    let c = (_textStorage.string as NSString).character(at: lineCharRange.location + lineCharRange.length - 1)
                    if (c == ("\n" as NSString).character(at: 0) || c == ("\r" as NSString).character(at: 0)) { // Other Unicode newline characters?
                        // Shorten the character range and get the new glyph range
                        lineCharRange.length -= 1;
                        clippedGlyphRange = _layoutManager.glyphRange(forCharacterRange:lineCharRange, actualCharacterRange:nil);
                    }
                }
                if (clippedGlyphRange.length == 0) {
                    // Only a newline in this line; still need the update to glyphLocation below, though or we hang as in #20274
                } else {
                    if let container = _layoutManager.textContainer(forGlyphAt:glyphLocation, effectiveRange:nil) {
                        let glyphBounds = _layoutManager.boundingRect(forGlyphRange: clippedGlyphRange, in: container)

                        //NSLog(@"glyphRange = %@, lineFrag = %@, glyphBounds = %@", NSStringFromRange(clippedGlyphRange), NSStringFromRect(lineFrag), NSStringFromRect(glyphBounds));

                        maximumLineLength = max(glyphBounds.size.width, maximumLineLength);
                    }
                }

                // Step by the unclipped glyph range or we'll go into an infinite loop when we chop off a newline
                glyphLocation = lineGlyphRange.location + lineGlyphRange.length;
        }
        return maximumLineLength;
    }
}
