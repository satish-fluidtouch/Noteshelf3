//
//  FTColorsPaletteViewController.swift
//  Noteshelf
//
//  Created by Narayana on 21/10/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

let kColorPickerDidUpdateNotification = "FTColorPickerDidUpdateNotification"

protocol FTColorsPaletteControllerDelegate: class {
    func colorsPaletteViewController(_ cp: FTColorsPaletteViewController, didSelectColor selectedColor: String)
    func colorsPaletteViewController(_ cp: FTColorsPaletteViewController, didReplaceCurrentColors colors: [String])
    func colorsPaletteViewController(_cp: FTColorsPaletteViewController, didGetCurrentcolor color: String)
    func colorsPaletteViewControllerDidResetAllColors(_ cp: FTColorsPaletteViewController)
    func openColorPicker(viewController: FTCustomColorPickerViewController, editIndexPath: IndexPath?)
    func didColorPickerDisappear(_ cp: FTColorsPaletteViewController)
}

class FTColorsPaletteViewController: UIViewController {

    @IBOutlet private weak var colorCollectionView: UICollectionView!
    @IBOutlet weak var pageControl: UIPageControl?
    
    var type: FTRackType = .pen
    var isTextMode: Bool = false
    var isFavoritebarEditMode: Bool = false
    
    private var selectedIndexPath: IndexPath!
    private var colorProvider : FTColorProvider!

    let customTransitioningDelegate = FTSlideInPresentationManager(mode: .topToBottom)
    weak var delegate: FTColorsPaletteControllerDelegate?

    var colors: [String] = []
    var selectedColor: String = ""
    private var customLastAddedColor: String = ""
    private var lastEditedColor: String = ""
        
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureColorcollectionView()
        self.configureDragAndDropForColors()
        self.scrollColorsToSelectedPosition()
        self.configurePageControl()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // to fix the layout issue in split mode
        self.reloadColorCollection()
        self.updatePageCount()
        self.updateCurrentPage()
    }
    
    private func configureColorcollectionView() {
        self.colorCollectionView.register(UINib(nibName: "FTPenColorCollectionViewCell", bundle: Bundle(for: FTPenRackViewController.self)), forCellWithReuseIdentifier: "PenColor")
        colorCollectionView.dataSource = self
        colorCollectionView.delegate = self
    }

    private func configureDragAndDropForColors() {
        colorProvider = FTColorProvider(existingColors: self.colors, selectedColor: self.selectedColor, isEditing: false)
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongGesture(_:)))
        self.colorCollectionView?.addGestureRecognizer(longPressGesture)
    }

    @objc func handleLongGesture(_ gesture: UILongPressGestureRecognizer) {
        
        switch(gesture.state) {
            
        case UIGestureRecognizer.State.began:
            self.colorCollectionView?.collectionViewLayout.invalidateLayout()
            let selectedIndexPath = self.colorCollectionView?.indexPathForItem(at: gesture.location(in: self.colorCollectionView))
            if let indexPath = selectedIndexPath, indexPath.item < self.colorProvider.existingColors.count {
                colorCollectionView?.beginInteractiveMovementForItem(at: indexPath)
                let selectedCell = self.colorCollectionView?.cellForItem(at: indexPath)
                UIView.animate(withDuration: 0.3, animations: {
                    let position = CGAffineTransform.init(translationX: 0, y: -10)
                    let zoom = CGAffineTransform(scaleX: 1.5, y: 1.5);
                    selectedCell?.transform = position.concatenating(zoom)
                });
                colorCollectionView?.updateInteractiveMovementTargetPosition(gesture.location(in: gesture.view!))
                self.handleAnalyticTagForDragColor()
            }
        case UIGestureRecognizer.State.changed:
            colorCollectionView?.updateInteractiveMovementTargetPosition(gesture.location(in: gesture.view!))
        case UIGestureRecognizer.State.ended:
            colorCollectionView?.endInteractiveMovement()
            self.colorCollectionView?.collectionViewLayout.invalidateLayout()
        default:
            colorCollectionView?.cancelInteractiveMovement()
        }
    }
                
    func scrollColorsToSelectedPosition() {
        if !self.isTextMode {
            if let indexOfSelectedColor = self.colors.index(of: self.selectedColor) {
                self.colorCollectionView.layoutIfNeeded()
                if self.isRegularClass() {
                self.scrollToRequiredColorPalette(index: indexOfSelectedColor)
                } else {
                    self.colorCollectionView.scrollToItem(at: IndexPath(item: indexOfSelectedColor, section: 0), at: UICollectionView.ScrollPosition(), animated: false)
                }
            }
        } else {
            // Is handled in updateLastSelection method(for text mode)
        }
    }
    
    // MARK: - EditColors, Color picker handlers
    @objc func addColorButtonClicked(_ sender:UIButton) {
        self.openColorPicker(withDefaultColor: self.selectedColor, isEditing: false, colorPickerFlow: .add)
        self.handleAddNewTapEvent()
    }

    private func openColorPicker(withDefaultColor colorHexString: String, isEditing: Bool, colorPickerFlow: FTColorPickerFlow) {
        
        colorProvider = FTColorProvider(existingColors: self.colors, selectedColor: colorHexString, isEditing: isEditing, colorPickerFlow: colorPickerFlow)
        colorProvider.currentActiveColor = self.selectedColor
        let colorPickerViewController = FTCustomColorPickerViewController.viewController(delegate: self,
                                                                                         colorProvider: colorProvider,
                                                                                         rackType: self.type)
        // edit indexpath is for text mode handling purpose because of formsheet presentation
        if colorPickerFlow == .add {
            self.delegate?.openColorPicker(viewController: colorPickerViewController, editIndexPath: nil)
        } else {
            self.delegate?.openColorPicker(viewController: colorPickerViewController, editIndexPath: self.selectedIndexPath)
        }
        self.handleAnaylyticTagForColorPickerFlow(flow: colorPickerFlow)
    }
    
    private func replaceCurrentColors(colors: [String]) {
        self.colors = colors
        self.reloadColorCollection()
        self.scrollToRequiredPositionOnColorPicked()
        self.colorCollectionView.layoutIfNeeded()
        self.delegate?.colorsPaletteViewController(self, didReplaceCurrentColors: self.colors)
     }

    private func dismissColorPicker() {
        if let navVc = self.navigationController {
            navVc.popViewController(animated: true)
        }
        else
        {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func reloadColorCollection() {
        self.colorCollectionView?.reloadData()
    }
    
    private func notifyColorPickerCurrentColorUpdate() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: kColorPickerDidUpdateNotification), object: nil, userInfo: nil)
    }
    
    private func scrollToRequiredColorPalette(index: Int) {
        let pageNum = CGFloat(index / 7) // page zero means - first page
        let pageWidth = colorCollectionView.frame.size.width
        var newTargetOffset: CGFloat = 0
        
        newTargetOffset =  (pageNum * pageWidth) - (pageNum * self.getMinimumInterItemSpacingForSection())
        if newTargetOffset <= self.getMinimumInterItemSpacingForSection()  {
            newTargetOffset = 0
        }
        else if (newTargetOffset >= colorCollectionView.contentSize.width - pageWidth){
            newTargetOffset = colorCollectionView.contentSize.width - pageWidth
        }
        
        self.colorCollectionView.setContentOffset(CGPoint(x: newTargetOffset, y: self.colorCollectionView.contentOffset.y), animated: false)
        self.updateCurrentPage()
    }
    
    private func scrollToRequiredPositionOnColorPicked() {
        if let index = self.colors.indexes(of: self.colorProvider.currentActiveColor).first {
            if(self.isRegularClass()) {
                self.scrollToRequiredColorPalette(index: index)
            } else {
                self.colorCollectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: UICollectionView.ScrollPosition(), animated: false)
            }
        }
    }
}

// Extension for public methods to expose outside(For FTCustomFontViewController to restore previous color while deleting text)
extension FTColorsPaletteViewController {
    func updateLastSelection(index: Int) {
        self.selectedColor = self.colors[index]
        self.colorCollectionView.reloadData()
        if(self.isRegularClass()) {
            self.scrollToRequiredColorPalette(index: index)
        } else {
            self.colorCollectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: UICollectionView.ScrollPosition(), animated: false)
        }
    }
}

//MARK:- ColorCollectionViewDataSource, ColorCollectionViewDelegate, ColorCollectionViewDelegateFlowLayout
extension FTColorsPaletteViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return ((self.colors.count/7) + 1) * 7
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let collectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "PenColor", for: indexPath) as? FTPenColorCollectionViewCell else {
            fatalError("Programmer error, could not find FTPenColorCollectionViewCell")
        }
        let index = indexPath.item
        collectionViewCell.editButton.alpha = 1.0
        collectionViewCell.currentSelected = false

        if(index >= self.colors.count) {
            collectionViewCell.imageViewEmpty.isHidden = true
            collectionViewCell.viewColor.isHidden = true
            collectionViewCell.editButton.isHidden = false
            if index == self.colors.count {
                collectionViewCell.isUserInteractionEnabled = true
                collectionViewCell.editButton.setImage(UIImage(named: "plusImage"), for: .normal)
                collectionViewCell.editButton.setInnerBorder(withBorderWidth: 1.0, withColor: UIColor.black.withAlphaComponent(0.05))
                collectionViewCell.editButton.addTarget(self, action: #selector(FTColorsPaletteViewController.addColorButtonClicked(_:)), for:.touchUpInside)
            } else {
                collectionViewCell.isUserInteractionEnabled = false
                collectionViewCell.editButton.setImage(nil, for: .normal)
                collectionViewCell.editButton.setInnerBorder(withBorderWidth: 0.0, withColor: .clear)
                collectionViewCell.editButton.alpha = 0.3
            }
            return collectionViewCell
        }
        else {
            collectionViewCell.editButton.isHidden = true
            collectionViewCell.isUserInteractionEnabled = true
            let colorHexCode = self.colors[index]
            if colorHexCode == "" {
                collectionViewCell.imageViewEmpty.isHidden = false
                collectionViewCell.viewColor.isHidden = true
            }
            else {
                collectionViewCell.imageViewEmpty.isHidden = true
                collectionViewCell.viewColor.isHidden = false
                collectionViewCell.viewColor.backgroundColor = UIColor(hexString: colorHexCode)
            }
            let isSelected: Bool = (self.selectedColor == colorHexCode)
            collectionViewCell.currentSelected = isSelected
            
            if let bgColor = collectionViewCell.viewColor.backgroundColor {
                collectionViewCell.viewColor.layer.borderWidth = bgColor.isLightColor() ? 0.5 : 0.0
            }
        }
        return collectionViewCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let colorHexCode = self.colors[indexPath.item]
        if colorHexCode != self.selectedColor {
            guard colorHexCode != "" else {
                collectionView.deselectItem(at: indexPath, animated: true)
                self.selectedIndexPath = indexPath
                self.openColorPicker(withDefaultColor: colorHexCode, isEditing: true, colorPickerFlow: .edit)
                return
            }
            self.selectedColor = colorHexCode
            collectionView.reloadData()
            self.delegate?.colorsPaletteViewController(self, didSelectColor: self.selectedColor)
        } else {
            self.selectedIndexPath = indexPath
            self.openColorPicker(withDefaultColor: self.selectedColor, isEditing: true, colorPickerFlow: .edit)
            self.handleActiveFavoriteTapEvent()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return self.getMinimumInterItemSpacingForSection()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if(isRegularClass()) {
            return UIEdgeInsets(top: 0.0, left: 14.0, bottom: 0.0, right: 14.0)
        }
        else {
            return UIEdgeInsets(top: 0.0, left: 20.0, bottom: 0.0, right: 20.0)
        }
    }
    
    private func getMinimumInterItemSpacingForSection() -> CGFloat {
        if !(self.isRegularClass()) {
            return 10.0
        }
        return 14.0
    }
    
    //MARK:- Reorder Colors
    public func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return indexPath.item < self.colorProvider.existingColors.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        var finalDestinationIndexpath = destinationIndexPath
        if destinationIndexPath.item >= self.colorProvider.existingColors.count {
            finalDestinationIndexpath = IndexPath.init(row: self.colorProvider.existingColors.count-1, section: 0)
        }
        let colorString = self.colorProvider.existingColors[sourceIndexPath.item]
        self.colorProvider.existingColors.remove(at: sourceIndexPath.item)
        self.colorProvider.existingColors.insert(colorString, at: finalDestinationIndexpath.item)
        self.colors = self.colorProvider.existingColors

        if (self.isRegularClass()) {
            self.scrollToRequiredColorPalette(index: finalDestinationIndexpath.item)
        } else {
            self.colorCollectionView.scrollToItem(at: IndexPath(item: finalDestinationIndexpath.item, section: 0), at: UICollectionView.ScrollPosition(), animated: false)
        }
        self.delegate?.colorsPaletteViewController(self, didReplaceCurrentColors: self.colors)
    }
    
    public func collectionView(_ collectionView: UICollectionView, targetIndexPathForMoveFromItemAt originalIndexPath: IndexPath, toProposedIndexPath proposedIndexPath: IndexPath) -> IndexPath {
        if(proposedIndexPath.item >= self.colorProvider.existingColors.count) {
            let indexPath = IndexPath.init(row: self.colorProvider.existingColors.count-1, section: 0)
            return indexPath
        }
        return proposedIndexPath;
    }
}

extension FTColorsPaletteViewController {
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if(self.isRegularClass()) {
            let pageWidth = colorCollectionView.frame.size.width
            let currentOffset = scrollView.contentOffset.x
            let targetOffset = targetContentOffset.pointee.x
            var newTargetOffset: CGFloat = 0
            if targetOffset > currentOffset {
                let pageNum = ceil(currentOffset / pageWidth)
                self.updateCurrentPageOnScrollEnd(pageNumber: Int(pageNum))
                newTargetOffset = (pageNum * pageWidth) - (pageNum * self.getMinimumInterItemSpacingForSection())
            }
            else {
                let pageNum = floor(currentOffset / pageWidth)
                self.updateCurrentPageOnScrollEnd(pageNumber: Int(pageNum))
                newTargetOffset = (pageNum * pageWidth) - (pageNum * self.getMinimumInterItemSpacingForSection())
            }
            if newTargetOffset <= self.getMinimumInterItemSpacingForSection()  {
                newTargetOffset = 0
            }
            else if (newTargetOffset >= scrollView.contentSize.width - pageWidth){
                newTargetOffset = scrollView.contentSize.width - pageWidth
            }

            targetContentOffset.pointee.x = currentOffset
            scrollView.setContentOffset(CGPoint(x: newTargetOffset, y: scrollView.contentOffset.y), animated: true)
        }
    }
}

//MARK:- CustomColorPickerViewControllerDelegate
extension FTColorsPaletteViewController: CustomColorPickerViewControllerDelegate {
    
    func customColorPickerViewController(_ cp: FTCustomColorPickerViewController, colorSelected selectedColor: UIColor, colorPickerMode: FTColorPickerMode) {
        let colorHexCode = selectedColor.hexStringFromColor()

        if self.colors.contains(colorHexCode) && self.colorProvider.colorPickerFlow == .edit && colorPickerMode == .palette {
            self.dismissColorPicker()
            self.colorCollectionView.reloadData()
        }
        else {
                if(self.colorProvider.colorPickerFlow == .edit) {
                    self.lastEditedColor = colorHexCode
                    if colorPickerMode == .palette {
                        self.dismissColorPicker()
                    }
            } else {
                    if colorPickerMode == .custom {
                        self.customLastAddedColor = colorHexCode
                        self.colorProvider.isEditing = true
                        self.selectedIndexPath = IndexPath(item: self.colorProvider.existingColors.count - 1, section: 0)
                    } else {
                        self.colorProvider.currentSelectedColorsInPalette.append(colorHexCode)
                    }
            }
        }
        
        self.selectedColor = colorHexCode
        self.colorProvider.currentActiveColor = colorHexCode
        if colorPickerMode == .palette {
            self.notifyColorPickerCurrentColorUpdate()
            track("colorpicker_palettes_color_selected", params: ["color": colorHexCode], screenName: FTScreenNames.penrack)
        }
        self.delegate?.colorsPaletteViewController(_cp: self, didGetCurrentcolor: colorHexCode)
    }
    
    func customColorPickerViewController(_ cp: FTCustomColorPickerViewController, colorDeselected selectedColor: UIColor) {
        let colorHexCode = selectedColor.hexStringFromColor()
        if(self.colorProvider.currentSelectedColorsInPalette.contains(colorHexCode)){
            if let index = self.colorProvider.currentSelectedColorsInPalette.firstIndex(of: colorHexCode) {
                self.colorProvider.currentSelectedColorsInPalette.remove(at: index)
            }
        }
        
        if let colorHex = self.colorProvider.currentSelectedColorsInPalette.last {
            self.colorProvider.currentActiveColor = colorHex
            self.notifyColorPickerCurrentColorUpdate()
            self.delegate?.colorsPaletteViewController(_cp: self, didGetCurrentcolor: colorHex)
        } else {
            self.colorProvider.currentActiveColor = self.colorProvider.initialSelectedColor
            self.notifyColorPickerCurrentColorUpdate()
            self.delegate?.colorsPaletteViewController(_cp: self, didGetCurrentcolor: self.colorProvider.initialSelectedColor)
        }
        
        self.selectedColor = self.colorProvider.currentActiveColor
    }
    
    func customColorPickerViewController(_ cp: FTCustomColorPickerViewController, multipleColorsSelected multipleColors: [UIColor]) {
        multipleColors.enumerated().forEach { (_, color) in
            if(self.colorProvider.currentSelectedColorsInPalette.contains(color.hexStringFromColor()) == false){
                    self.colorProvider.currentSelectedColorsInPalette.append(color.hexStringFromColor())
            }
        }
        
        if let colorHex = multipleColors.last?.hexStringFromColor() {
            self.colorProvider.currentActiveColor = colorHex
            self.notifyColorPickerCurrentColorUpdate()
            self.delegate?.colorsPaletteViewController(_cp: self, didGetCurrentcolor: colorHex)
        }
        
        self.selectedColor = self.colorProvider.currentActiveColor
    }
    
    func customColorPickerViewController(_ cp: FTCustomColorPickerViewController, multipleColorsDeselected multipleColors: [UIColor]){
        multipleColors.enumerated().forEach { (_, color) in
            if let colorIndex = self.colorProvider.currentSelectedColorsInPalette.firstIndex(of: color.hexStringFromColor()){
                self.colorProvider.currentSelectedColorsInPalette.remove(at: colorIndex)
            }
        }
        
        if let colorHex = self.colorProvider.currentSelectedColorsInPalette.last {
            self.colorProvider.currentActiveColor = colorHex
            self.notifyColorPickerCurrentColorUpdate()
            self.delegate?.colorsPaletteViewController(_cp: self, didGetCurrentcolor: colorHex)
        } else {
            self.colorProvider.currentActiveColor = self.colorProvider.initialSelectedColor
            self.notifyColorPickerCurrentColorUpdate()
            self.delegate?.colorsPaletteViewController(_cp: self, didGetCurrentcolor: self.colorProvider.initialSelectedColor)
        }

        self.selectedColor = self.colorProvider.currentActiveColor
    }
    
    func customColorPickerViewControllerDeleteColor(_ cp: FTCustomColorPickerViewController, colorPickerMode: FTColorPickerMode) {
        if colorPickerMode == .custom {
            self.customLastAddedColor = ""
            if let selectedIndex = self.selectedIndexPath?.item, selectedIndex < self.colorProvider.existingColors.count, self.colorProvider.colorPickerFlow == .edit {
                self.colorProvider.existingColors.remove(at: selectedIndex)
                self.replaceCurrentColors(colors: self.colorProvider.existingColors)
                self.lastEditedColor = ""
            }
        } else {
            if !self.colorProvider.currentSelectedColorsInPalette.isEmpty {
                for color in self.colorProvider.currentSelectedColorsInPalette {
                    if let index = self.colorProvider.existingColors.firstIndex(of: color) {
                        self.colorProvider.existingColors.remove(at: index)
                    }
                }
                self.colorProvider.currentSelectedColorsInPalette.removeAll()
                self.colorProvider.existingColorsSelected.removeAll()
                
            } else if let selectedIndex = self.selectedIndexPath?.item, selectedIndex < self.colorProvider.existingColors.count, self.colorProvider.colorPickerFlow == .edit {
                self.colorProvider.existingColors.remove(at: selectedIndex)
            }
            self.replaceCurrentColors(colors: self.colorProvider.existingColors)
        }
        
        self.dismissColorPicker()
    }

    func customColorPickerViewControllerResetAllColors(_ cp: FTCustomColorPickerViewController) {
        self.customLastAddedColor = ""
        self.lastEditedColor = ""
        self.colorProvider.currentSelectedColorsInPalette.removeAll()
        self.colorProvider.existingColorsSelected.removeAll()
        self.delegate?.colorsPaletteViewControllerDidResetAllColors(self)
        self.colorProvider.existingColors = self.colors
        self.reloadColorCollection()
        self.dismissColorPicker()
    }

    func customColorPickerViewControllerWillDisappear(_cp: FTCustomColorPickerViewController) {
        if(self.colorProvider.colorPickerFlow == .edit) && self.lastEditedColor != "" && !self.colors.contains(lastEditedColor) {
            let index = self.selectedIndexPath.item
            self.colorProvider.existingColors.remove(at: index)
            self.colorProvider.existingColors.insert(self.lastEditedColor, at: index)
            if self.colorProvider.currentSelectedColorsInPalette.isEmpty {
                track("colorpicker_custom_color_selected", params: ["color": self.lastEditedColor], screenName: FTScreenNames.penrack)
            }
            self.lastEditedColor = ""
        }
        
        if self.customLastAddedColor != "", !self.colorProvider.existingColors.contains(self.customLastAddedColor) {
            self.colorProvider.existingColors.append(self.customLastAddedColor)
            if self.colorProvider.currentSelectedColorsInPalette.isEmpty {
                track("colorpicker_custom_color_selected", params: ["color": self.customLastAddedColor], screenName: FTScreenNames.penrack)
            }
            self.customLastAddedColor = ""
        }
        self.colorProvider.updateExistingColorsWithCurrentSelectedColors()
        self.replaceCurrentColors(colors: self.colorProvider.existingColors)
        self.colorProvider.currentSelectedColorsInPalette.removeAll()
        self.colorProvider.existingColorsSelected.removeAll()
        self.delegate?.didColorPickerDisappear(self)
        self.scrollToRequiredPositionOnColorPicked()
    }

}

extension FTColorsPaletteViewController {
    private func handleAnalyticTagForDragColor() {
        if self.isFavoritebarEditMode {
            track("favrack_color_dragged", params: [:], screenName: FTScreenNames.favoriteToolBar)
        } else if self.isTextMode {
            track("Color_DragToRearrange", params: [:], screenName: FTScreenNames.textbox)
            track("textrack_color_dragged", params: [:], screenName: FTScreenNames.textbox)
        } else {
            track("Color_DragToRearrange", params: [:], screenName: FTScreenNames.penrack)
            if self.type == .pen {
                track("penrack_color_dragged", params: [:], screenName: FTScreenNames.penrack)
            } else if self.type == .highlighter {
                track("hilrack_color_dragged", params: [:], screenName: FTScreenNames.penrack)
            }
        }
    }
    
    private func handleAnaylyticTagForColorPickerFlow(flow: FTColorPickerFlow) {
        if flow == .add {
            track(self.type == .pen ? "Pen_AddColor" : "Highlighter_AddColor", params: [:], screenName: FTScreenNames.penrack)
        } else {
            track(self.type == .pen ? "Pen_SelectColor_Edit" : "Highlighter_SelectColor_Edit", params: [:], screenName: FTScreenNames.penrack)
        }
    }
    
    private func handleActiveFavoriteTapEvent() {
        if isFavoritebarEditMode {
            track("favrack_activecolor_tapped", params: [:], screenName: FTScreenNames.favoriteToolBar)
        } else if isTextMode {
            track("textrack_activecolor_tapped", params: [:], screenName: FTScreenNames.textbox)
        } else {
            if self.type == .pen {
                track("penrack_activecolor_tapped", params: [:], screenName: FTScreenNames.penrack)
            } else if self.type == .highlighter {
                track("hilrack_activecolor_tapped", params: [:], screenName: FTScreenNames.penrack)
            } else if self.type == .shape {
                track("shapesrack_activecolor_tapped", params: [:], screenName: FTScreenNames.shapes)
            }
        }
    }
    
    private func handleAddNewTapEvent() {
        if isFavoritebarEditMode {
            track("favrack_addnewcolor_tapped", params: [:], screenName: FTScreenNames.favoriteToolBar)
        } else {
            if self.type == .pen {
                track("penrack_addnewcolor_tapped", params: [:], screenName: FTScreenNames.penrack)
            } else if self.type == .highlighter {
                track("hilrack_addnewcolor_tapped", params: [:], screenName: FTScreenNames.penrack)
            } else if self.type == .shape {
                track("shapesrack_addnewcolor_tapped", params: [:], screenName: FTScreenNames.shapes)
            }
        }
    }
}

// To handle the page control count and selection
extension FTColorsPaletteViewController {
    internal func configurePageControl() {
        self.pageControl?.pageIndicatorTintColor = .pageControlInActiveColor
        self.pageControl?.currentPageIndicatorTintColor = .pageControlActiveColor
        self.pageControl?.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
    }

    internal func updatePageCount() {
        let paletteCount = self.getNumberOfPalettes()
        self.pageControl?.numberOfPages = paletteCount
    }
    
    internal func getNumberOfPalettes() -> Int {
        if ((self.colors.count+1) % 7 == 0) {
            return (self.colors.count+1)/7
        }
        return (self.colors.count/7)+1
    }
    
    internal func updateCurrentPage() {
        if let index = self.colors.index(of: self.selectedColor) {
            let pageNum = index / 7
            self.pageControl?.currentPage = pageNum
        }
    }
    
    internal func updateCurrentPageOnScrollEnd(pageNumber: Int) {
        self.pageControl?.currentPage = pageNumber
    }
}

// MARK: - Array extension methods
extension Array where Element:Equatable {
    func removeDuplicates() -> (uniqueElements: [Element], duplicateExists: Bool) {
        var result = [Element]()
        var duplicateExists = false
        for value in self {
            if result.contains(value) == false {
                result.append(value)
            } else {
                duplicateExists = true
            }
        }
        return (result, duplicateExists)
    }

    func indexes(of element: Element) -> [Int] {
        return self.enumerated().filter({ element == $0.element }).map({ $0.offset })
    }

}
