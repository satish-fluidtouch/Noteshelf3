//
//  FTTextAttachmentTapGesture.swift
//  Noteshelf
//
//  Created by Sameer on 08/10/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit

enum FTActionSupport : Int {
    case all
    case textAttachment
    case url
}

class FTTextAttachmentTapGesture: UIGestureRecognizer {
    var actionAttribute: Any?
    var boundingRect = CGRect.zero
    var range: NSRange?
    var supportedActionType: FTActionSupport?

    private weak var _textView: UITextView?
    public weak var textView: UITextView? {
        get {
            if nil != _textView {
                return _textView
            }
            return view as? UITextView
        }
        set(textview) {
            _textView = textview
        }
    }
    
   override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)

        if state == .failed {
            return
        }

        let touch = touches.first
        let textView = self.textView
        let textContainer = textView?.textContainer
        let layoutManager = textView?.layoutManager

        var point = touch?.location(in: textView)
        point?.x -= textView?.textContainerInset.left ?? 0.0
        point?.y -= textView?.textContainerInset.top ?? 0.0

        var characterIndex: Int? = nil
        if let textContainer = textContainer {
            characterIndex = layoutManager?.characterIndex(for: point ?? CGPoint.zero, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil) ?? 0
        }

        if (characterIndex ?? 0) >= (textView?.text.count ?? 0) {
            state = UIGestureRecognizer.State.failed
            return
        }

        let glyphRange = layoutManager?.glyphRange(forCharacterRange: NSRange(location: characterIndex ?? 0, length: 1), actualCharacterRange: nil)
        var boundRect: CGRect? = nil
        if let glyphRange = glyphRange, let textContainer = textContainer {
            boundRect = layoutManager?.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        }
        if !(boundRect?.contains(point ?? CGPoint.zero) ?? false) {
            state = UIGestureRecognizer.State.failed
            return
        }

        var textAttachmentRange = NSRange()
        let attachment = textView?.attributedText.attribute(
            .attachment,
            at: characterIndex ?? 0,
            effectiveRange: &textAttachmentRange) as? NSTextAttachment

        var urlAttachmentRange = NSRange()
        let linkURL = textView?.attributedText.attribute(
            .link,
            at: characterIndex ?? 0,
            effectiveRange: &urlAttachmentRange) as? URL
        var supported = false
         if isTextAttachmentSupported() && attachment != nil {
              actionAttribute = attachment
              range = textAttachmentRange
              supported = true
          } else if isLinkSupported() && linkURL != nil {
              actionAttribute = linkURL
              range = urlAttachmentRange
              supported = true
          }

          if let range = range, supported {
              boundingRect = boundingRect(range)
              state = UIGestureRecognizer.State.recognized
              return
          }
          state = UIGestureRecognizer.State.failed
          actionAttribute = nil
    }
    
    override func reset() {
        super.reset()
        range = NSRange(location: NSNotFound, length: 0)
        actionAttribute = nil
    }

    func boundingRect(_ ramge: NSRange) -> CGRect {
        let textView = self.textView

        let glyphRange = textView?.layoutManager.glyphRange(forCharacterRange: ramge, actualCharacterRange: nil)
        var boundingRect: CGRect? = nil
        if let glyphRange = glyphRange, let textContainer = textView?.textContainer {
            boundingRect = textView?.layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        }

        boundingRect?.origin.x -= textView?.textContainerInset.left ?? 0.0
        boundingRect?.origin.y -= textView?.textContainerInset.top ?? 0.0
        return boundingRect ?? CGRect.zero
    }
    
    func isTextAttachmentSupported() -> Bool {
        return supportedActionType == FTActionSupport.all || supportedActionType == FTActionSupport.textAttachment
    }

    func isLinkSupported() -> Bool {
        return supportedActionType == FTActionSupport.all || supportedActionType == FTActionSupport.url
    }
}
