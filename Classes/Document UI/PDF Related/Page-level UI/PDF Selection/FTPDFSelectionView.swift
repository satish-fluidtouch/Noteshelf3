//
//  FTTestView.swift
//  PDFView
//
//  Created by Amar on 26/05/21.
//

import UIKit
import PDFKit

private let shouldLog = false;
private var supportsPDFSelection: Bool {
    return true;
};

enum FTPDFSelectionAction: Int {
    case highlight,strikeOut

    private func penSize(_ type: FTPenType,
                         thickness: CGFloat,
                         sizes: [FTPenSize]) -> FTPenSize? {
        var sizeToReturn: FTPenSize?;
        for eachSize in sizes {
            let attributes = FTBrushBuilder.penAttributesFor(penType: type,
                                                             brushWidth: CGFloat(eachSize.rawValue),
                                                             isShapeTool: true,
                                                             version: FTStroke.defaultAnnotationVersion());
            if attributes.brushWidth >= thickness {
                sizeToReturn = eachSize;
                break;
            }
        }
        return sizeToReturn;
    }

    func penSet(_ activity: NSUserActivity?,thickness: CGFloat) -> FTPenSetProtocol {
        let penSet: FTPenSetProtocol
        switch self {
        case .highlight:
            let rack = FTRackData(type: .highlighter, userActivity: activity);
            penSet = rack.getCurrentPenSet();
            let penSize = self.penSize(penSet.type,
                                       thickness: thickness,
                                       sizes: rack.penSizes) ?? .four;
            penSet.size = penSize;
        case .strikeOut:
            let rack = FTRackData(type: .pen, userActivity: activity);
            penSet = rack.getCurrentPenSet();
            penSet.size = .two;
        }
        return penSet;
    }
}


protocol FTPDFSelectionViewDelegate: FTTextInteractionDelegate {
    func pdfSelectionView(_ view:FTPDFSelectionView,
                          didTapOnAction action: FTPDFSelectionAction,
                          lineRects rects: [CGRect]);
    func pdfSelectionViewDisableGestures(_ view: FTPDFSelectionView);
    func requiredTapGestureToFail() -> UITapGestureRecognizer?;
}

@objc protocol FTTextInteractionDelegate: NSObjectProtocol {
    @objc optional func pdfInteractionShouldBegin(at point: CGPoint) -> Bool;
    @objc optional func pdfInteractionWillBegin();
    @objc optional func pdfInteractionDidEnd();
    @objc optional func pdfSelectionView(_ view: FTPDFSelectionView,performAIAction selectedString:String);
}

#if targetEnvironment(macCatalyst)
protocol FTPDFSelectionViewContextMenuDelegate: NSObjectProtocol {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration?
}
#endif

private class FTTextGrabHandle {
    private let floatWidth: CGFloat = 2;
    enum FTTextGrabType {
        case left,right
    }

    func draw(in context: CGContext?
              ,selectionRect : CGRect
              ,handleType : FTTextGrabType
              ,isVertical: Bool) {
        let rect = selectionRect;
        context?.saveGState();
//#if !DEBUG
        UIColor(hexString: "#2D6FFF").setFill();
//#endif
        var circleRect = rect;
        if(isVertical) {
            circleRect.size.width = rect.height;
            if(handleType == .left) {
                circleRect.origin.x = rect.maxX - circleRect.size.height;
            }
        }
        else {
            circleRect.size.height = rect.width;
            if(handleType == .right) {
                circleRect.origin.y = rect.maxY - circleRect.size.height;
            }
        }


        let circlePath = UIBezierPath(ovalIn: circleRect);
        circlePath.fill();

        var lineRect = rect;
        if(isVertical) {
            lineRect.size.height = floatWidth;
            lineRect.origin.y = rect.midY - floatWidth * 0.5;
        }
        else {
            lineRect.size.width = floatWidth;
            lineRect.origin.x = rect.midX - floatWidth * 0.5;
        }

        let linePath  = UIBezierPath(rect: lineRect);
        linePath.fill();
        context?.restoreGState();
    }
}

class FTPDFTextSelectionView: UIView {
    private let extraOffset: CGFloat = 5;
    private let floatWidth: CGFloat = 2;
    var selectionRects = [FTCustomTextSelectionRect]() {
        didSet {
            var rect = CGRect.null;
            selectionRects.forEach { eachRect in
                rect = rect.union(eachRect.rect);
            }
            self.frame = rect.isNull ? CGRect.zero : rect.insetBy(dx: -extraOffset, dy: -extraOffset);
            self.setNeedsDisplay()
        }
    }

    private func commonInit() {
        self.layer.compositingFilter = "multiplyBlendMode";
        self.clipsToBounds = false;
    }

    override init(frame: CGRect) {
        super.init(frame: frame);
        commonInit();
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder);
        commonInit();
    }

    func leftGrabberRect() -> (rect:CGRect?,isVertical:Bool) {
        var isVertical = false;
        if let firstRect = selectionRects.first {
            isVertical = firstRect.isVertical

            var newRect = firstRect.rect;
            if let lastRect = selectionRects.last {
                if(isVertical && lastRect.rect.minY > newRect.minY) {
                    isVertical = lastRect.isVertical
                    newRect = lastRect.rect;
                }
                else if(!isVertical && lastRect.rect.minY < newRect.minY) {
                    isVertical = lastRect.isVertical
                    newRect = lastRect.rect;
                }
            }

            let offset = self.frame.origin;
            newRect.origin.x -= (offset.x);
            newRect.origin.y -= offset.y;

            let circleRect: CGRect;
            if(isVertical) {
                circleRect = CGRect(x: newRect.minX,
                                    y: newRect.minY - extraOffset,
                                    width: newRect.width + extraOffset,
                                    height: 2 * extraOffset);
            }
            else {
                circleRect = CGRect(x: newRect.minX - extraOffset,
                                    y: newRect.minY - extraOffset,
                                    width: 2 * extraOffset,
                                    height: newRect.height + extraOffset);
            }
            return (circleRect,isVertical);
        }
        return (nil,isVertical);
    }

    func rightGrabberRect() -> (rect:CGRect?,isVertical:Bool) {
        var isVertical = false;
        if let firstRect = selectionRects.last {
            isVertical = firstRect.isVertical

            var newRect = firstRect.rect;
            if let lastRect = selectionRects.first {
                if(isVertical && lastRect.rect.minY < newRect.minY) {
                    isVertical = lastRect.isVertical
                    newRect = lastRect.rect;
                }
                else if(!isVertical && lastRect.rect.minY > newRect.minY) {
                    isVertical = lastRect.isVertical
                    newRect = lastRect.rect;
                }
            }

            let offset = self.frame.origin;
            newRect.origin.x -= (offset.x);
            newRect.origin.y -= offset.y;

            let circleRect: CGRect;
            if(isVertical) {
                circleRect = CGRect(x: newRect.minX - extraOffset,
                                    y: newRect.maxY - extraOffset,
                                    width: newRect.width + extraOffset,
                                    height: 2 * extraOffset);
            }
            else {
                circleRect = CGRect(x: newRect.maxX - extraOffset,
                                    y: newRect.minY,
                                    width: 2 * extraOffset,
                                    height: newRect.height + extraOffset);
            }
            return (circleRect,isVertical);
        }
        return (nil,isVertical);
    }

    override func draw(_ rect: CGRect) {
        let offset = self.frame.origin;
        super.draw(rect);
        let context = UIGraphicsGetCurrentContext();
        #if DEBUG
        UIColor.red.setStroke();
        context?.setLineWidth(2);
        context?.stroke(rect);
        #endif

        context?.saveGState();
        context?.setBlendMode(.multiply);
        UIColor(hexString: "#E5E5FF").setFill();
        selectionRects.forEach { eachRect in
            var newRect = eachRect.rect;
            newRect.origin.x -= offset.x;
            newRect.origin.y -= offset.y;
            UIRectFill(newRect);
        }
        let handle = FTTextGrabHandle();

        let leftGrabberRect = leftGrabberRect();
        if  let rect = leftGrabberRect.rect {
#if DEBUG
            UIColor.blue.setFill();
#endif
            handle.draw(in: context,
                        selectionRect: rect,
                        handleType: .left,
                        isVertical: leftGrabberRect.isVertical);
        }
        let rightGrabberRect = rightGrabberRect();
#if DEBUG
        UIColor.red.setFill();
#endif
        if  let rect = rightGrabberRect.rect {
            handle.draw(in: context,
                        selectionRect: rect,
                        handleType: .right,
                        isVertical: rightGrabberRect.isVertical);
        }
        context?.restoreGState();
    }
}

private enum FTSelectionMode: Int {
    case none,word,resizeLeft,resizeRight;
}

private enum FTPDFPageStringState: Int {
    case noString,hasString;
}

class FTPDFSelectionView: UIView {

    private var textSelectionLayer: FTPDFTextSelectionView?;
    private var selectionMode = FTSelectionMode.none;
    private var pdfStringState: FTPDFPageStringState = .noString;

    private var canInitiateSelection = false;

    private var pdfPageReference: PDFPage? {
        return page?.pdfPageRef;
    }

    @objc weak var page: FTPageProtocol? {
        didSet {
            pdfStringState = .noString;
            self.scehdulePDStringRetrival();
        }
    }
    
    private func scehdulePDStringRetrival() {
        self.perform(#selector(self.startPorcessing), with: nil, afterDelay: 0.3);
    }
    
    @objc private func startPorcessing() {
        DispatchQueue.global().async { [weak self] in
            guard let strongSelf = self else {
                return;
            }
            if let _page = strongSelf.page, _page.hasPDFText() {
                strongSelf.pdfStringState = .hasString;
            }
        }
    }
    
    deinit {
        self.cancelScehduledPDStringRetrival();
    }
    
    private func cancelScehduledPDStringRetrival() {        
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.startPorcessing), object: nil);
    }
    
    func setDelegate(_ delegate: FTPDFSelectionViewDelegate) {
        self._delegate = delegate;
    }

    private weak var _delegate: AnyObject? {
        didSet {
            self.updateGestureCondition();
        }
    }

    private weak var longtextInteraction: UILongPressGestureRecognizer?;

    private var currentSize: CGSize = .zero;
    private var previousSelection: UITextRange?;
    #if targetEnvironment(macCatalyst)
    private weak var contextMenuInteraction: UIContextMenuInteraction?;
    #endif
    var allowsSelection = true {
        didSet {
            guard supportsPDFSelection else {
                if(allowsSelection) {
                    allowsSelection = supportsPDFSelection;
                }
                return;
            }
            if(allowsSelection) {
                self.longtextInteraction?.isEnabled = true;
            }
            else {
                self.longtextInteraction?.isEnabled = false;
            }
        }
    };

    override init(frame: CGRect) {
        super.init(frame: frame);
        allowsSelection = supportsPDFSelection;
        self.commonSetup();
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder);
        allowsSelection = supportsPDFSelection;
        self.commonSetup();
    }

    private func updateGestureCondition() {
        guard supportsPDFSelection else {
            return;
        }
        let gestureCondition = self.delegate?.requiredTapGestureToFail();
        if let gesture = gestureCondition {
            longtextInteraction?.require(toFail: gesture);
        }
        longtextInteraction?.allowedTouchTypes = [NSNumber(value: (UITouch.TouchType.direct.rawValue))];
    }

    private func commonSetup() {
        guard supportsPDFSelection,nil == self.longtextInteraction else {
            return;
        }
#if DEBUG || BETA
        guard FTDeveloperOption.enablePDFSelection else {
            return;
        }
#endif
        if(nil == self.textSelectionLayer) {
            let _view = FTPDFTextSelectionView.init(frame: self.bounds);
            _view.backgroundColor = UIColor.clear;
            self.addSubview(_view);
            _view.layer.zPosition = 2;
            self.textSelectionLayer = _view;
        }

        let interacton = UILongPressGestureRecognizer(target: self, action: #selector(self.didSelectLongPress(_:)));
        interacton.delegate = self;
        interacton.delaysTouchesBegan = false;
        interacton.cancelsTouchesInView = true;
        interacton.delaysTouchesEnded = false;
        self.longtextInteraction = interacton
        self.addGestureRecognizer(interacton);
        self.updateGestureCondition();

        #if targetEnvironment(macCatalyst)
        self.addContextMenuInteraction()
        #endif
    }

    override var canBecomeFirstResponder: Bool {
        true
    }

    override func becomeFirstResponder() -> Bool {
        let val = super.becomeFirstResponder();
        if val {
            self.addMenuItems();
        }
        return val;
    }

    override func layoutSubviews() {
        super.layoutSubviews();
        let boundsSize = self.bounds.size;
        if currentSize != boundsSize {
            currentSize = boundsSize;
            self.textSelectionLayer?.frame = self.bounds;

            if let pos = self.currentSelectedTextRange {
                self.selectedTextRange = nil;
                self.selectedTextRange = pos;
            }
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event);
        if selectionMode == .none, nil != self.selectedTextRange {
            if let point = touches.first?.location(in: self.contentView) {
                var angle = (self.page?.rotationAngle ?? 0) % 360;
                if(angle < 0) {
                    angle += 360;
                }
                if isOnLeftGrabber(point) {
                    selectionMode = .resizeLeft;
                    if(angle == 180) {
                        selectionMode = .resizeRight;
                    }
                }
                if isOnRightGrabber(point) {
                    selectionMode = .resizeRight;
                    if(angle == 180) {
                        selectionMode = .resizeLeft;
                    }
                }

                if(selectionMode != .none) {
                    self.delegate?.pdfSelectionViewDisableGestures(self);
                }
            }
        }
        hideMenu();
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event);
        if self.selectedTextRange != nil, let touchpoint = touches.first?.location(in: self.contentView) {
            guard let position = closestPosition(to: touchpoint) as? FTCustomTextPosition
                    ,let oldpos = selectedTextRange?.start as? FTCustomTextPosition
                    , let oldendpos = selectedTextRange?.end as? FTCustomTextPosition else {
                return;
            }

            if selectionMode == .resizeLeft || selectionMode == .resizeRight{
                if(position.offset < oldpos.offset) {
                    selectedTextRange = textRange(from: position, to: oldendpos);
                }
                else if(position.offset > oldpos.offset){
                    if(selectionMode == .resizeLeft && position.offset < oldendpos.offset) {
                        selectedTextRange = textRange(from: position, to: oldendpos);
                    }
                    else {
                        selectedTextRange = textRange(from: oldpos, to: position);
                    }
                }
            }
            else if selectionMode == .word {
                self.proceedPDFSelectionByWord(touchpoint);
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        self.endPDFSelectionEvent();
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        if(self.longtextInteraction?.state != .began) {
            self.selectedTextRange = nil
            selectionMode = .none
        }
    }

    @objc func didSelectLongPress(_ gesture: UILongPressGestureRecognizer) {
        switch(gesture.state) {
        case .began:
            if let _page = page,let pdfpage = self.pdfPageReference
            {
                let newPoint = gesture.location(in: self.contentView);
                let ptToCOnsider = pdfpage
                    .convertPoint(newPoint,
                                                        fromView: self.contentView,
                                                        rotationAngle: Int(_page.rotationAngle));
                if let sel = pdfpage.selectionForWord(at: ptToCOnsider)
                    ,sel.canSelectText(pdfpage) {
                    canInitiateSelection = true;
                }
            }
            else {
                gesture.isEnabled = false;
                gesture.isEnabled = true;
                canInitiateSelection = false;
            }
            
            if nil == self.selectedTextRange
                ,canInitiateSelection {
                let point = gesture.location(in: self.contentView);

                if let wordRange = self.pdfselectionWordRange(point) {
                    self.selectedTextRange = wordRange;
                    self.selectionMode = .word;
                }
                self.delegate?.pdfInteractionWillBegin?();
                logIfNeeded("PDFSelection : interactionWillBegin canInitiateSelection true")
            }
        case .changed:
            let point = gesture.location(in: self.contentView);
            proceedPDFSelectionByWord(point);
        case .recognized:
            endPDFSelectionEvent();
            logIfNeeded("PDFSelection : interactionDidEnd")
            self.delegate?.pdfInteractionDidEnd?();
        case .ended:
            logIfNeeded("PDFSelection : interactionDidEnd End Event")
        default:
            break;
        }
    }

    private var contentView: UIView {
        return self;
    }

    private var currentSelectedTextRange: UITextRange? {
        didSet {
            if(nil == currentSelectedTextRange) {
                logIfNeeded("PDFSelection : currentSelectedTextRange  canInitiateSelection false")
                canInitiateSelection = false;
            }
        }
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(self.highlightSelection(_:))
            || action == #selector(self.strikeOutSelection(_:))
            || action == #selector(self.copyAction(_:))
            || action == #selector(self.showDictionary(_:))
            || action == #selector(self.noteshelfAI(_:)) {
            guard let text = self.selectedText,!text.isEmpty else {
                return false;
            }
            return true;
        }
        return false;
    }

    private func logIfNeeded(_ log:String) {
        if(shouldLog) {
            debugLog(log);
        }
    }
}

//MAR:- PDF Text Selection -
private extension FTPDFSelectionView {
    func endPDFSelectionEvent() {
        hideMenu();
        if(nil != self.selectedTextRange) {
            showMenu();
        }
        selectionMode = .none
    }

    func pdfselectionWordRange( _ point: CGPoint) -> UITextRange? {
        guard let page = self.page
                ,let pdfpage = self.pdfPageReference else {
            return nil;
        }

        let newPoint = self.convert(point, to: self.contentView);
        let ptToCOnsider = pdfpage.convertPoint(newPoint,
                                                fromView: self.contentView,
                                                rotationAngle: Int(page.rotationAngle));
        if let sel = pdfpage.selectionForWord(at: ptToCOnsider)
            ,sel.canSelectText(pdfpage) {
            let range = sel.range(at: 0, on: pdfpage);
            let fromPosition = FTCustomTextPosition(offset: range.location);
            let toPosition = FTCustomTextPosition(offset: NSMaxRange(range));

            let range1 = textRange(from: fromPosition, to: toPosition);
            return range1;
        }
        return nil;
    }

    func proceedPDFSelectionByWord(_ touchpoint: CGPoint) {
        guard let oldpos = selectedTextRange?.start as? FTCustomTextPosition
                , let oldendpos = selectedTextRange?.end as? FTCustomTextPosition else {
            return;
        }
        if let wordRange = self.pdfselectionWordRange(touchpoint)
            , let wordRangeStart = wordRange.start as? FTCustomTextPosition
            , let wordRangeEnd = wordRange.end as? FTCustomTextPosition {
            var start = oldpos;
            var end = oldendpos
            if wordRangeStart.offset <= oldpos.offset {
                start = wordRangeStart;
            }
            else {
                end = wordRangeEnd
            }
            self.selectedTextRange = textRange(from: start, to: end);
        }
    }
}

//MAR:- PDF Grabber Check -
private extension FTPDFSelectionView {
    func isOnLeftGrabber(_ point: CGPoint) -> Bool {
        var poinInside = false;
        if let grabberInfo = self.textSelectionLayer?.leftGrabberRect()
            ,var grabberRect = grabberInfo.rect {
            if grabberInfo.isVertical {
                grabberRect = grabberRect.insetBy(dx: 0, dy: -20);
            }
            else {
                grabberRect = grabberRect.insetBy(dx: -20, dy: 0);
            }
            grabberRect = self.contentView.convert(grabberRect,from:self.textSelectionLayer);
            if grabberRect.contains(point) {
                poinInside = true;
            }
        }
        return poinInside;
    }

    func isOnRightGrabber(_ point: CGPoint) -> Bool {
        var poinInside = false;
        if let grabberInfo = self.textSelectionLayer?.rightGrabberRect()
            ,var grabberRect = grabberInfo.rect {
            if grabberInfo.isVertical {
                grabberRect = grabberRect.insetBy(dx: 0, dy: -20);
            }
            else {
                grabberRect = grabberRect.insetBy(dx: -20, dy: 0);
            }
            grabberRect = self.contentView.convert(grabberRect,from:self.textSelectionLayer);
            if grabberRect.contains(point) {
                poinInside = true;
            }
        }
        return poinInside;
    }
}
extension FTPDFSelectionView {
    var delegate: FTPDFSelectionViewDelegate? {
        return self._delegate as? FTPDFSelectionViewDelegate;
    }

    func text(in range: UITextRange) -> String? {
        guard allowsPDFTextSelection else {
                logIfNeeded("PDFSelection : text(in:) NA")
            return nil;
        }
        guard let customRange = range as? FTCustomTextRange else {
            return nil;
        }
        logIfNeeded("PDFSelection : text(in:)")
        if let sel = self.pdfPageReference?.selection(for: customRange.range) {
            return sel.string;
        }
        return nil;
    }

    var selectedTextRange: UITextRange? {
        get {
            return currentSelectedTextRange;
        }
        set(selectedTextRange) {
            var shouldUpdate = true;
            if let val1 = self.currentSelectedTextRange,let val2 = selectedTextRange,
               self.compare(val1.start, to: val2.start) == .orderedSame,
               self.compare(val1.end, to: val2.end) == .orderedSame {
                shouldUpdate = false;
            }
            if shouldUpdate {
                if(!(selectedTextRange?.isEmpty ?? true)) {
                    self.delegate?.pdfSelectionViewDisableGestures(self);
                }
                self.previousSelection = self.currentSelectedTextRange;
                currentSelectedTextRange = selectedTextRange
                if let selection = selectedTextRange {
                    self.textSelectionLayer?.selectionRects = self.selectionRects(for: selection);
                }
                else {
                    self.textSelectionLayer?.selectionRects = [FTCustomTextSelectionRect]();
                    hideMenu();
                }
            }
        }
    }

    func textRange(from fromPosition: UITextPosition, to toPosition: UITextPosition) -> UITextRange? {
        guard allowsPDFTextSelection else {
            logIfNeeded("PDFSelection : textRange(from:to:) NA")
            return nil;
        }

        guard let fromPosition = fromPosition as? FTCustomTextPosition, let toPosition = toPosition as? FTCustomTextPosition else {
            return nil
        }
        logIfNeeded("PDFSelection : textRange(from:to:)")
        return FTCustomTextRange(startOffset: fromPosition.offset, endOffset: toPosition.offset)
    }

    func compare(_ position: UITextPosition, to other: UITextPosition) -> ComparisonResult {
        guard allowsPDFTextSelection else {
            logIfNeeded("PDFSelection : compare(position:to:) NA")
            return .orderedSame;
        }
        guard let position = position as? FTCustomTextPosition,
              let other = other as? FTCustomTextPosition else {
            return .orderedSame
        }
        logIfNeeded("PDFSelection : compare(position:to:)")

        if position < other {
            return .orderedAscending
        } else if position > other {
            return .orderedDescending
        }
        return .orderedSame
    }

    func selectionRects(for range: UITextRange) -> [FTCustomTextSelectionRect] {
        guard allowsPDFTextSelection else {
            logIfNeeded("PDFSelection : selectionRects(for:) NA")
            return [FTCustomTextSelectionRect]();
        }

        guard let customRange = range as? FTCustomTextRange else {
            return [FTCustomTextSelectionRect]();
        }
        logIfNeeded("PDFSelection : selectionRects(for:)")

        let _range = customRange.range
        var selectionRect = [FTCustomTextSelectionRect]();
        if let page = self.page,
           let pdfPage = self.pdfPageReference,
           _range.length > 0 {
            if let sel = pdfPage.selection(for: _range) {
                let selections = sel.selectionsByLine();
                selections.forEach { selection in
                    var rect = selection.bounds(for: pdfPage);
                    rect = pdfPage.convertRect(rect,
                                            toViewBounds: self.contentView.bounds,
                                            rotationAngle: Int(page.rotationAngle));
                    rect = self.convert(rect, from: self.contentView);
                    let rect1 = FTCustomTextSelectionRect(rect: rect,
                                                          writingDirection: .natural,
                                                          containsStart: false,
                                                          containsEnd: false,
                                                          isVertical: self.isVerticalLayout());
                    selectionRect.append(rect1)
                }
            }
        }
        return selectionRect;
    }

    func closestPosition(to point: CGPoint) -> UITextPosition? {
        guard allowsPDFTextSelection else {
            logIfNeeded("PDFSelection : closestPosition(to:) NA")
            return nil;
        }
        guard let page = self.page,
              let pdfpage = self.pdfPageReference,
              canInitiateSelection else {
            return nil;
        }
        logIfNeeded("PDFSelection : closestPosition(to:)")
        let newPoint = self.convert(point, to: self.contentView);
        let ptToCOnsider = pdfpage.convertPoint(newPoint,
                                                fromView: contentView,
                                                rotationAngle: Int(page.rotationAngle));
        if let sel = pdfpage.selectionForWord(at: ptToCOnsider),
           sel.canSelectText(pdfpage) {
            let range = sel.range(at: 0, on: pdfpage);
            if let singleSel = pdfpage.selection(for: NSRange(location: range.location, length: 1)) {
                let bounds = singleSel.bounds(for: pdfpage);
                let center = CGPoint(x: bounds.origin.x, y: bounds.midY);
                let toPOint = CGPoint(x: ptToCOnsider.x, y: center.y)
                if let rectSelection = pdfpage.selection(from: center, to: toPOint),
                   rectSelection.numberOfTextRanges(on: pdfpage) > 0 {
                    let range = rectSelection.range(at: 0, on: pdfpage);
                    return FTCustomTextPosition(offset: max(NSMaxRange(range),0))
                }
            }
        }
        if let sel = pdfpage.selectionForLine(at: ptToCOnsider),
           sel.canSelectText(pdfpage) {
            let range = sel.range(at: 0, on: pdfpage);
            let vounds = sel.bounds(for: pdfpage);
            if vounds.origin.x > ptToCOnsider.x {
                return FTCustomTextPosition(offset: range.location)
            }
            else if vounds.maxX < ptToCOnsider.x {
                return FTCustomTextPosition(offset: max(NSMaxRange(range),0))
            }
        }
        if let curPos = self.currentSelectedTextRange as? FTCustomTextRange,
           let prev = self.previousSelection as? FTCustomTextRange {
            if prev.endOffset == curPos.endOffset {
                return self.currentSelectedTextRange?.start;
            }
            else {
                return self.currentSelectedTextRange?.end;
            }
        }
        return nil;
    }

    var hasText: Bool {
        var val = false;
        if allowsPDFTextSelection {
            val = _hasText;
        }
        logIfNeeded("PDFSelection : \(val)")
        return false;
    }
}


private extension FTPDFSelectionView {
    var _hasText: Bool {
        return (pdfStringState == .hasString);
    }

    var canSupportSelection: Bool {
        guard supportsPDFSelection,
              self.allowsSelection,
              _hasText else {
            return false;
        }
        return true;
    }

    var allowsPDFTextSelection: Bool {
        if supportsPDFSelection,
           allowsSelection,
           (canInitiateSelection || (nil != self.currentSelectedTextRange)) {
            return true;
        }
        return false;
    }

    var selectedText: String? {
        guard allowsPDFTextSelection else {
            return nil;
        }
        if let range = self.selectedTextRange, let text = self.text(in: range) {
            return text
        }
        return nil
    }
}


extension FTPDFSelectionView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool
    {
        let point = touch.location(in: self.contentView);
#if DEBUG || BETA
        guard FTDeveloperOption.enablePDFSelection else {
            logIfNeeded("PDFSelection : interactionShouldBegin level1 false")
            canInitiateSelection = false;
            return false;
        }
#endif
        guard let page = self.page,
              let pdfpage = self.pdfPageReference,
              self.canSupportSelection else {
            logIfNeeded("PDFSelection : interactionShouldBegin level2 false")
            canInitiateSelection = false;
            return false;
        }

        if let currentTextSelection = self.selectedTextRange {
            var poinInside = false;
            if isOnLeftGrabber(point) || isOnRightGrabber(point) {
                poinInside = true;
            }
            else {
                let selectionRects = selectionRects(for: currentTextSelection);
                for rect in selectionRects {
                    let path = UIBezierPath(rect: rect.rect);
                    if(path.contains(point)) {
                        poinInside = true;
                        break;
                    }
                }
            }
            if(!poinInside) {
                self.selectedTextRange = nil;
            }
            else {
                self.delegate?.pdfSelectionViewDisableGestures(self);
            }
            return false;
        }

        let newPoint = self.convert(point, to: self.contentView);
        let shouldInteract = self.delegate?.pdfInteractionShouldBegin?(at: newPoint) ?? false;
        if shouldInteract {
            return true;
        }
        logIfNeeded("PDFSelection : interactionShouldBegin final false")
        canInitiateSelection = false;
        self.selectedTextRange = nil;
        return false;
    }
}


@objc private extension FTPDFSelectionView {
    func showMenu() {
#if !targetEnvironment(macCatalyst)
        if let selctionView = self.textSelectionLayer,self.becomeFirstResponder() {
            UIMenuController.shared.showMenu(from: selctionView, rect: selctionView.bounds)
        }
#endif
    }

    func hideMenu() {
#if !targetEnvironment(macCatalyst)
        if let selctionView = self.textSelectionLayer {
            UIMenuController.shared.hideMenu(from: selctionView);
            self.resignFirstResponder();
        }
#endif
    }


    func addMenuItems() {
        guard supportsPDFSelection else {
            return;
        }
        var items = [UIMenuItem]();
        let highlight = UIMenuItem(title: NSLocalizedString("Highlight", comment: "Highlight"), action: #selector(self.highlightSelection(_:)))
        items.append(highlight);

        let strike = UIMenuItem(title: NSLocalizedString("Strikeout", comment: "Strikeout"), action: #selector(self.strikeOutSelection(_:)));
        items.append(strike);

        let lookupAction = UIMenuItem(title: NSLocalizedString("LookUp", comment: "LookUp"), action: #selector(self.showDictionary(_:)));
        items.append(lookupAction);

        let copyAction = UIMenuItem(title: NSLocalizedString("Copy", comment: "Copy"), action: #selector(self.copyAction(_:)));
        items.append(copyAction);

        if FTNoteshelfAI.supportsNoteshelfAI {
            let aiActionAction = UIMenuItem(title: "noteshelf.ai.noteshelfAI".aiLocalizedString, action: #selector(self.noteshelfAI(_:)));
            items.append(aiActionAction);
        }
        UIMenuController.shared.menuItems = items;
    }

    func highlightSelection(_ sender:AnyObject?) {
        if let rects = self.lineSelectionRects() {
            self.delegate?.pdfSelectionView(self,
                                            didTapOnAction: .highlight,
                                            lineRects: rects);
        }
    }

    func strikeOutSelection(_ sender: AnyObject?) {
        if let rects = self.lineSelectionRects() {
            self.delegate?.pdfSelectionView(self,
                                            didTapOnAction: .strikeOut,
                                            lineRects: rects);
        }
    }

    func showDictionary(_ sender: AnyObject?) {
    #if !targetEnvironment(macCatalyst)
        if let text = self.selectedText,!text.isEmpty {
            let controller = UIReferenceLibraryViewController(term: text);
            controller.modalPresentationStyle = .formSheet;

            self.window?.visibleViewController?.present(controller, animated: true, completion: nil);
        }
    #endif
    }

    func copyAction(_ sender: Any?) {
        if let text = self.selectedText,!text.isEmpty {
            UIPasteboard.general.string = text;
        }
    }
    
    func noteshelfAI(_ sender: Any?) {
        if let text = self.selectedText?.openAITrim(),!text.isEmpty {
            self.delegate?.pdfSelectionView?(self, performAIAction: text);
        }
    }
}


private extension FTPDFSelectionView {
    func isVerticalLayout() -> Bool {
        return self.page?.isVerticalLayout() ?? false;
    }

    func lineSelectionRects() -> [CGRect]? {
        guard let page = self.page,
              let pdfPage = self.pdfPageReference,
              let range = self.selectedTextRange as? FTCustomTextRange else {
            return nil;
        }

        guard let selection = pdfPage.selection(for: range.range) else {
            return nil;
        }
        var lineRect = [CGRect]();
        let lineSelections = selection.selectionsByLine();
        lineSelections.forEach { eachSelection in
            let eachLineRect = eachSelection.bounds(for: pdfPage);
            let convertedRect = pdfPage.convertRect(eachLineRect,
                                                    toViewBounds: self.contentView.bounds,
                                                    rotationAngle: Int(page.rotationAngle));
            lineRect.append(convertedRect);
        }
        return lineRect;
    }
}


extension FTPageProtocol {
    func isVerticalLayout() -> Bool {
        let pageRotatiion = Int(self.rotationAngle);
        let reminder = pageRotatiion%360;
        if reminder == 270 || reminder == 90 {
            return true;
        }
        return false;
    }
}


private extension PDFSelection {
    func canSelectText(_ pdfpage:PDFPage) -> Bool {
        if let str = self.string?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
            !str.isEmpty,
            self.numberOfTextRanges(on: pdfpage) > 0 {
            return true;
        }
        return false;
    }
}

#if targetEnvironment(macCatalyst)
extension FTPDFSelectionView: UIContextMenuInteractionDelegate {
    func addContextMenuInteraction()
    {
        let contextInteraction = UIContextMenuInteraction(delegate: self);
        self.addInteraction(contextInteraction);
        self.contextMenuInteraction = contextInteraction;
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        guard let range = self.selectedTextRange,
              let text = self.text(in: range),
              !text.isEmpty else {
            if let del = self.delegate as? FTPDFSelectionViewContextMenuDelegate,
               let menu = del.contextMenuInteraction(interaction, configurationForMenuAtLocation: location) {
                return menu;
            }
            return UIContextMenuConfiguration();
        }

        var menuItems = [UIAction]()

        let actionProvider : ([UIMenuElement]) -> UIMenu? = { _ in

            let highlight = UIAction(title: NSLocalizedString("Highlight", comment: "Highlight")) { [weak self] _ in
                self?.highlightSelection(nil);
            }
            menuItems.append(highlight)

            let strike = UIAction(title: NSLocalizedString("Strikeout", comment: "Strikeout")) { [weak self] _ in
                self?.strikeOutSelection(nil);
            }
            menuItems.append(strike)

            let copyAction = UIAction(title: NSLocalizedString("Copy", comment: "Copy")) { [weak self] _ in
                self?.copyAction(nil);
            }
            menuItems.append(copyAction)
            
            if FTNoteshelfAI.supportsNoteshelfAI {
                let noteshelfAIAction = UIAction(title: "noteshelf.ai.noteshelfAI".aiLocalizedString) { [weak self] _ in
                    self?.noteshelfAI(nil);
                }
                menuItems.append(noteshelfAIAction)
            }

            return UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: menuItems)
        }
        let config = UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: actionProvider)
        return config
    }
}
#endif
