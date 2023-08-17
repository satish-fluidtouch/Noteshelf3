//
//  FTSegmentedControl.swift
//  FTAddOperations
//
//  Created by Siva on 15/06/20.
//  Copyright © 2020 Siva. All rights reserved.
//

import UIKit
/// both image & text style
public enum HybridStyle {
    case normalWithSpace(CGFloat)
    case imageTopWithSpace(CGFloat)
    case imageBottomWithSpace(CGFloat)
}
/// slider podition
public enum SliderPositionStyle {
    case bottomWithHight(CGFloat)
    case topWidthHeight(CGFloat)
}
/// only text style,
public enum WidthStyle {
    case fixedWidth(CGFloat)
    case adaptiveSpace(CGFloat)
}

public protocol FTSegmentedControlDelegate: AnyObject {
    func segmentedControlSelectedIndex(_ index: Int, animated: Bool, segmentedControl: FTSegmentedControl)
    func didEndScrollOfSegments() // added just to track the event
    func didTapSegment(_ index: Int) // added just to track the event
}

// Default implementation of event tracking
extension FTSegmentedControlDelegate {
    func didEndScrollOfSegments() {
        print("added just to track the event")
    }
    func didTapSegment(_ index: Int) {
        print("added just to track the event")
    }
}

public class FTSegmentedControl: UIView, UIScrollViewDelegate {
    
    /// default `false`. if `true`, bounces past edge of content and back again
    public var bounces: Bool = true {
        didSet { scrollView.bounces = bounces }
    }
    /// selected index, default `0`
    public var selectedIndex: Int = 0 {
        didSet { updateScrollViewOffset() }
    }
    /// selectedScale, default `1.0`
    public var selectedScale: CGFloat = 1.0
    /// delegate
    public weak var delegate: FTSegmentedControlDelegate?
    
// MARK: - set items
    /// only text
    ///
    /// - Parameters:
    ///   - titles: text group
    ///   - style: The width style of the text is an enumeration, fixed width or adaptive
    public func setTitles(_ titles: [String], style: WidthStyle) {
        setTitleItems(titles: titles, style: style)
    }
    
    /// only image
    ///
    /// - Parameters:
    ///   - images: image group
    ///   - selectedImages: selected image group, Ideally the same number of images, if not, the selected will be the item in images
    ///   - fixedWidth: The width is fixed
    public func setImages(_ images: [UIImage], selectedImages: [UIImage?]? = nil, fixedWidth: CGFloat) {
        setImageItems(images: images, selectedImages: selectedImages, fixedWidth: fixedWidth)
    }
    
    /// both text image
    ///
    /// - Parameters:
    ///   - titles: title group
    ///   - images: image group
    ///   - selectedImages: selected image group
    ///   - style: image potision
    ///   - fixedWidth: The width is fixed
    public func setTitlesAndImages(_ titles: [String?], images: [UIImage?], selectedImages: [UIImage?]? = nil, style: WidthStyle, fixedWidth: CGFloat) {
        setTitleAndImageItems(titles, images: images,selectedImages:selectedImages,style:style, fixedWidth: fixedWidth)
    }
// MARK: - text
    /// textColor
    public var textColor: UIColor = UIColor.gray {
        didSet {
            if itemsArray.isEmpty { return }
            itemsArray.forEach { $0.setTitleColor(textColor, for: .normal) }
            let index = min(max(selectedIndex, 0), itemsArray.count-1)
            let button = itemsArray[index]
            button.setTitleColor(textSelectedColor, for: .normal)
        }
    }
    /// selected textColor
    public var textSelectedColor: UIColor = UIColor.blue {
        didSet {
            if itemsArray.isEmpty { return }
            itemsArray.forEach { $0.setTitleColor(textSelectedColor, for: .normal) }
            let index = min(max(selectedIndex, 0), itemsArray.count-1)
            let button = itemsArray[index]
            button.setTitleColor(textSelectedColor, for: .normal)
        }
    }
    public var disableTextColor: UIColor = UIColor.gray {
           didSet {
               if itemsArray.isEmpty { return }
               itemsArray.forEach { $0.setTitleColor(disableTextColor, for: .disabled) }
               let index = min(max(selectedIndex, 0), itemsArray.count-1)
               let button = itemsArray[index]
               button.setTitleColor(disableTextColor, for: .disabled)
           }
       }
    /// textFont
    public var textFont: UIFont = UIFont.systemFont(ofSize: 15) {
        didSet { itemsArray.forEach { $0.titleLabel?.font = textFont } }
    }

    public var textCornerRadius: CGFloat = 0.0 {
        didSet {
            if itemsArray.isEmpty { return }
            itemsArray.forEach { button in
                button.layer.cornerRadius = textCornerRadius
            }
        }
    }

    public var segmentBgColor: UIColor = .clear
    public var selectedSegmentBgColor: UIColor = .clear
    public var textBorderWidth: CGFloat = 0.0

// MARK: - setup cover
    
    /// setup cover
    ///
    /// - Parameters:
    ///   - upDowmSpace: the distance of cover's up/down from item's up/down
    ///   - cornerRadius: radius
    public func setCover(upDowmSpace: CGFloat = 0, cornerRadius: CGFloat = 0) {
        coverView.isHidden = false
        coverView.layer.cornerRadius = cornerRadius
        coverUpDownSpace = upDowmSpace
        updateCoverAndSliderFrame(originFrame: coverView.frame, upSpace: upDowmSpace)
    }
    
    
    
// MARK: - contentView is scrollView
    
    /// use in contentScrollView `scrollViewDidScroll`
    ///
    /// - Parameter scrollView: content scrollView
    public func contentScrollViewDidScroll(_ scrollView: UIScrollView) {
        updataCoverAndSliderByContentScrollView(scrollView)
    }
    
    /// use in contentScroll `scrollViewWillBeginDragging`
    public func contentScrollViewWillBeginDragging() {
        contentScrollViewWillDragging = true
    }
    
// MARK: - slider
    
    /// set slider
    ///
    /// - Parameters:
    ///   - backgroundColor: slider backgroundColor
    ///   - position: Deciding on the slider position up or down, an enumeration
    ///   - widthStyle: The width of the slider is an enumeration, fixed width or adaptive
    public func setSilder(backgroundColor: UIColor,position: SliderPositionStyle, widthStyle: WidthStyle) {
        var sliderFrame = slider.frame
        switch position {
        case .bottomWithHight(let height):
            sliderFrame.origin.y = frame.size.height-height
            sliderFrame.size.height = height
        case .topWidthHeight(let height):
            sliderFrame.origin.y = 0
            sliderFrame.size.height = height
        }
        slider.frame = sliderFrame
        slider.isHidden = false
        slider.backgroundColor = backgroundColor
        sliderConfig = (position, widthStyle)
    }

    public var scrollView = UIScrollView()

    /// private
    var itemsArray = [UIButton]()
    fileprivate var coverView = UIView()
    fileprivate var slider = UIView()
    fileprivate var totalItemsCount: Int = 0
    fileprivate var titleSources = [String]()
    fileprivate var imageSources: ([UIImage], [UIImage]) = ([], [])
    fileprivate var hybridSources: ([String?], [UIImage?], [UIImage?]) = ([], [], [])
    fileprivate var hybridStyle: HybridStyle = .normalWithSpace(0)
    fileprivate var resourceType: ResourceType = .text
    fileprivate var coverUpDownSpace: CGFloat = 0
    fileprivate var sliderConfig: (SliderPositionStyle, WidthStyle) = (.bottomWithHight(2),.adaptiveSpace(0))
    fileprivate var contentScrollViewWillDragging: Bool = false
    fileprivate var isTapItem: Bool = false
    enum ResourceType {
        case text
        case image
        case hybrid
    }
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupContentView()
    }
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupContentView()
    }
    override public func layoutSubviews() {
        super.layoutSubviews()
        scrollView.frame = bounds
        updateScrollViewOffset()
    }
    private func setTitleItems(titles: [String], style: WidthStyle) {
        resourceType = .text
        titleSources = titles
        totalItemsCount = titles.count
        switch style {
        case .fixedWidth(let width):
            setupItems(fixedWidth: width)
        case .adaptiveSpace(let space):
            setupItems(fixedWidth: 0, leading: space)
        }
    }
    private func setImageItems(images: [UIImage], selectedImages: [UIImage?]? = nil, fixedWidth: CGFloat) {
        resourceType = .image
        var sImages = [UIImage]()
        if selectedImages == nil {
            sImages = images
        } else {
            for i in 0..<images.count {
                let image = (i < selectedImages!.count && selectedImages![i] != nil) ? selectedImages![i]! : images[i]
                sImages.append(image)
            }
        }
        imageSources = (images, sImages)
        totalItemsCount = images.count
        setupItems(fixedWidth: fixedWidth)
    }
    private func setTitleAndImageItems(_ titles: [String?], images: [UIImage?], selectedImages: [UIImage?]? = nil, style: WidthStyle, fixedWidth: CGFloat) {
        resourceType = .hybrid
//        hybridStyle = style
        totalItemsCount = max(titles.count, images.count)
        var _titles = [String?]()
        var _images = [UIImage?]()
        var _sImages = [UIImage?]()
        let sTempImages = selectedImages == nil ? images : selectedImages!
        for i in 0..<totalItemsCount {
            let title = i<titles.count ? titles[i] : nil
            let image = i<images.count && images[i] != nil ? images[i] : UIImage()
            let sImage = i<sTempImages.count && sTempImages[i] != nil ? sTempImages[i] : image
            _titles.append(title)
            _images.append(image)
            _sImages.append(sImage)
        }
        hybridSources = (_titles, _images, _sImages)
        switch style {
        case .fixedWidth(let width):
            setupItems(fixedWidth: width)
        case .adaptiveSpace(let space):
            setupItems(fixedWidth: 0, leading: space)
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.delegate?.didEndScrollOfSegments()
    }
}
/// setup UI
extension FTSegmentedControl {
    fileprivate func setupContentView() {
        backgroundColor = UIColor.white
        scrollView.frame = bounds
        scrollView.scrollsToTop = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.bounces = true
        addSubview(scrollView)
        scrollView.addSubview(coverView)
        scrollView.addSubview(slider)
        scrollView.delegate = self
        slider.isHidden = true
        coverView.isHidden = true
    }
    
    fileprivate func setupItems(fixedWidth: CGFloat, leading: CGFloat? = nil) {
        itemsArray.forEach { $0.removeFromSuperview() }
        itemsArray.removeAll()
        var contentSizeWidth: CGFloat = 0
        /// height hardcoded to 36
        let height = 36.0
        let spacing = 8.0
        for i in 0..<totalItemsCount {
            var width = fixedWidth
            if let leading = leading {
                let text = titleSources[i] as NSString
                width = text.size(withAttributes: [.font: textFont]).width + leading * 2
            }
            let x = contentSizeWidth
//            let height = frame.size.height
            let button = UIButton(type: .custom)
            button.frame = CGRect(x: x, y: 0, width: width, height: height)
            
//            /// rounded corners
//            button.layer.cornerRadius = 10
//            button.layer.borderColor = CGColor(red: 0, green: 0, blue: 0, alpha: 0.7)
//            button.layer.borderWidth = 1
            
            button.clipsToBounds = true
            button.tag = i
            button.addTarget(self, action: #selector(selectedButton(sender:)), for: .touchUpInside)
            scrollView.addSubview(button)
            itemsArray.append(button)
            
            switch resourceType {
            case .text:
                button.setTitle(titleSources[i], for: .normal)
                button.setTitleColor(textColor, for: .normal)
                button.setTitleColor(disableTextColor, for: .disabled)
                button.titleLabel?.font = textFont
                button.backgroundColor = segmentBgColor
            case .image:
                button.setImage(imageSources.0[i], for: .normal)
                button.setImage(imageSources.1[i], for: .selected)
            case .hybrid:
                button.setTitleColor(textColor, for: .normal)
                button.setTitleColor(disableTextColor, for: .disabled)

                button.titleLabel?.font = textFont
                let text = hybridSources.0[i]
                let image = hybridSources.1[i]
                button.setTitle(text, for: .normal)
                button.setImage(image, for: .normal)
                button.setImage(hybridSources.2[i], for: .selected)
                switch hybridStyle {
                case .normalWithSpace(let space):
                    if text == nil || image == nil { break }
                    let distance = space/2
                    button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -distance, bottom: 0, right: distance)
                    button.titleEdgeInsets = UIEdgeInsets(top: 0, left: distance, bottom: 0, right: -distance)
                case .imageTopWithSpace(let space):
                    if text == nil || image == nil { break }
                    let distance = space/2
                    let titleWidth = text?.size(withAttributes: [.font: textFont]).width ?? 0
                    let titleHeight = text?.size(withAttributes: [.font: textFont]).height ?? 0
                    button.imageEdgeInsets = UIEdgeInsets(top: -titleHeight-distance, left: 0, bottom: 0, right: -titleWidth)
                    button.titleEdgeInsets = UIEdgeInsets(top: 0, left: -image!.size.width, bottom: -image!.size.height-distance, right: 0)
                case .imageBottomWithSpace(let space):
                    if text == nil || image == nil { break }
                    let distance = space/2
                    let titleWidth = text?.size(withAttributes: [.font: textFont]).width ?? 0
                    let titleHeight = text?.size(withAttributes: [.font: textFont]).height ?? 0
                    button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: -titleHeight-distance, right: -titleWidth)
                    button.titleEdgeInsets = UIEdgeInsets(top: -image!.size.height-distance, left: -image!.size.width, bottom: 0, right: 0)
                }
            }
            contentSizeWidth += width + spacing
            // To avoid extra space at the end of last item
            if i == totalItemsCount - 1 {
                contentSizeWidth -= spacing
            }
        }
        scrollView.contentSize = CGSize(width: contentSizeWidth, height: 0)
        let index = min(max(selectedIndex, 0), itemsArray.count-1)
        let selectedButton = itemsArray[index]
        selectedButton.isSelected = true
        updateCoverAndSliderFrame(originFrame: selectedButton.frame, upSpace: coverUpDownSpace)
    }
    @objc private func selectedButton(sender: UIButton) {
        contentScrollViewWillDragging = true
        isTapItem = true
        selectedIndex = sender.tag
        self.delegate?.didTapSegment(selectedIndex)
    }
}
/// update offset
extension FTSegmentedControl {
    public func hideCoverViewOnSearchStart() {
        if itemsArray.isEmpty { return }
        let index = min(max(selectedIndex, 0), itemsArray.count-1)
        let currentButton = self.itemsArray[index]
        isTapItem = false
        currentButton.setTitleColor(self.textColor, for: .normal)
        currentButton.setTitleColor(self.disableTextColor, for: .disabled)
        currentButton.isSelected = false
        currentButton.transform = CGAffineTransform(scaleX: 1, y: 1)
        currentButton.backgroundColor = segmentBgColor
        coverView.isHidden = true
    }
    
    fileprivate func updateScrollViewOffset() {
        if itemsArray.isEmpty { return }
        let index = min(max(selectedIndex, 0), itemsArray.count-1)
        delegate?.segmentedControlSelectedIndex(index, animated: isTapItem, segmentedControl: self)
        
        let currentButton = self.itemsArray[index]
        let offset = getScrollViewCorrectOffset(by: currentButton)
        let duration = isTapItem || contentScrollViewWillDragging
            ? 0.1 : 0
        isTapItem = false
            self.itemsArray.forEach({ (button) in
                button.backgroundColor = segmentBgColor
                button.setTitleColor(self.textColor, for: .normal)
                button.setTitleColor(self.disableTextColor, for: .disabled)
                button.isSelected = false
                button.layer.borderWidth = self.textBorderWidth
                button.transform = CGAffineTransform(scaleX: 1, y: 1)
            })
     
            coverView.isHidden = false
            self.updateCoverAndSliderFrame(originFrame: currentButton.frame, upSpace: self.coverUpDownSpace)
            currentButton.setTitleColor(textSelectedColor, for: .normal)
            currentButton.backgroundColor = selectedSegmentBgColor
            currentButton.isSelected = true
            currentButton.layer.borderWidth = 0
        
            let scale = self.selectedScale
            currentButton.transform = CGAffineTransform(scaleX: scale, y: scale)
            let animated = duration == 0 ? false:true
            self.scrollView.setContentOffset(offset, animated: animated)
    }
    fileprivate func getScrollViewCorrectOffset(by item: UIButton) -> CGPoint {
        if scrollView.contentSize.width < scrollView.frame.size.width {
            return CGPoint.zero
        }
        var offsetx = item.center.x - frame.size.width/2
        let offsetMax = scrollView.contentSize.width - frame.size.width
        if offsetx < 0 {
            offsetx = 0
        }else if offsetx > offsetMax {
            offsetx = offsetMax
        }
        let offset = CGPoint(x: offsetx, y: 0)
        return offset
    }
}
extension FTSegmentedControl {
    fileprivate func updataCoverAndSliderByContentScrollView(_ scrollView: UIScrollView) {
        if !contentScrollViewWillDragging { return }
        let offset = scrollView.contentOffset.x / scrollView.frame.size.width
        let percent = offset-CGFloat(Int(offset))
        let currentIndex = Int(offset)
        var targetIndex = currentIndex
        if percent < 0 && currentIndex > 0 {
            targetIndex = currentIndex-1
        } else if percent > 0 && currentIndex < itemsArray.count-1 {
            targetIndex = currentIndex+1
        } else {
            return
        }
        let currentButton = itemsArray[currentIndex]
        let targentButton = itemsArray[targetIndex]
        currentButton.transform = CGAffineTransform(scaleX: 1, y: 1)
        targentButton.transform = CGAffineTransform(scaleX: 1, y: 1)
        
        let centerXChange = (targentButton.center.x-currentButton.center.x)*abs(percent)
        let widthChange = (targentButton.frame.size.width-currentButton.frame.size.width)*abs(percent)
        var frame = currentButton.frame
        frame.size.width += widthChange
        updateCoverAndSliderFrame(originFrame: frame, upSpace: coverUpDownSpace)
        var center = currentButton.center
        center.x += centerXChange
        coverView.center = center
        
        var sliderCenter = slider.center
        sliderCenter.x = coverView.center.x
        slider.center = sliderCenter
        
        /// scale
        let scale = (selectedScale-1)*abs(percent)
        let targetTx = 1 + scale
        let currentTx = selectedScale - scale
        currentButton.transform = CGAffineTransform(scaleX: currentTx, y: currentTx)
        targentButton.transform = CGAffineTransform(scaleX: targetTx, y: targetTx)
        
        let currentColor = averageColor(fromColor: textSelectedColor, toColor: textColor, percent: abs(percent))
        let targetColor = averageColor(fromColor: textColor, toColor: textSelectedColor, percent: abs(percent))
        currentButton.setTitleColor(currentColor, for: .normal)
        targentButton.setTitleColor(targetColor, for: .normal)

        currentButton.backgroundColor = .red
        targentButton.backgroundColor = .blue
    }
    
    fileprivate func updateCoverAndSliderFrame(originFrame: CGRect, upSpace: CGFloat) {
        var newFrame = originFrame
        newFrame.origin.y = upSpace
        newFrame.size.height -= upSpace * 2
        
        
        coverView.frame = newFrame
        
        switch sliderConfig.0 {
        case .topWidthHeight(let height):
            newFrame.origin.y = 0
            newFrame.size.height = height
        case .bottomWithHight(let height):
            newFrame.origin.y = originFrame.size.height-height
            newFrame.size.height = height
        }
        switch sliderConfig.1 {
        case .fixedWidth(let width):
            newFrame.size.width = width
        case .adaptiveSpace(let space):
            newFrame.size.width = originFrame.size.width-2*space
        }
        slider.frame = newFrame
        
        var sliderCenter = slider.center
        sliderCenter.x = coverView.center.x
        slider.center = sliderCenter
    }
}

/// average
extension FTSegmentedControl {
    fileprivate func averageColor(fromColor: UIColor, toColor: UIColor, percent: CGFloat) -> UIColor {
        var fromRed: CGFloat = 0
        var fromGreen: CGFloat = 0
        var fromBlue: CGFloat = 0
        var fromAlpha: CGFloat = 0
        fromColor.getRed(&fromRed, green: &fromGreen, blue: &fromBlue, alpha: &fromAlpha)
        
        var toRed: CGFloat = 0
        var toGreen: CGFloat = 0
        var toBlue: CGFloat = 0
        var toAlpha: CGFloat = 0
        toColor.getRed(&toRed, green: &toGreen, blue: &toBlue, alpha: &toAlpha)
        
        let nowRed = fromRed + (toRed - fromRed) * percent
        let nowGreen = fromGreen + (toGreen - fromGreen) * percent
        let nowBlue = fromBlue + (toBlue - fromBlue) * percent
        let nowAlpha = fromAlpha + (toAlpha - fromAlpha) * percent
        
        return UIColor(red: nowRed, green: nowGreen, blue: nowBlue, alpha: nowAlpha)
    }
}
