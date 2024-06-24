//
//  FTPDFRenderViewController+DocumentEntity.swift
//  Noteshelf
//
//  Created by Siva on 25/04/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import FTCommon
import FTNewNotebook
import FTTemplatesStore

extension FTPDFRenderViewController: FTAddDocumentEntitiesViewControllerDelegate {
    /// Pixabay and Unsplash
    func mediaLibraryViewController(_ mediaLibraryViewController: FTMediaLibraryViewController, didSelect mediaImage: UIImage, source: FTInsertImageSource) {
        self.insert([mediaImage], center: .zero, droppedPoint: .zero, source: source)

    }
    
    @objc func setUpUndoRedoGesture() {
        let undoRedoGestureDetector = FTPageUndoRedoGestureDetector(delegate: self, contentHolderView: self.contentHolderView)
        self.undoRedoGestureDetector = undoRedoGestureDetector
    }
    
    @objc func showToastWith(_ message: String) {
        FTToastHostController.showToast(from: self, toastConfig: FTToastConfiguration(title: message))
    }

    @objc func audioAnnotations() -> [FTAnnotation] {
        var annotationsToReturn = [FTAnnotation]()
        if  let page = self.firstPageController()?.pdfPage as? FTNoteshelfPage {
            annotationsToReturn.append(contentsOf: page.audioAnnotations())
        }
        return annotationsToReturn
    }

    /// Photo Library,  Take Photo
    func didFinishPickingUIImages(_ images: [UIImage], source: FTInsertImageSource) {
        self.insert(images, center: .zero, droppedPoint: .zero, source: source)
    }
    
    /// Photo Template, Page From Camera
    func didFinishPickingImportItems(_ items: [FTImportItem]?) {
        self.addNewpageMode = FTNormalMode
        if let items = items {
            self.beginImporting(items: items)
        }
    }
    
    /// Page
    func didTapPage(_ item: FTPageType) {
        self.addNewpageMode = FTNormalMode
        if item == .pageFromCamera || item == .photoTemplate {
            self.insertingPhotoAsPage = true
        }
        self.performPageInsertOperation(item)
    }
    
    func didInsertPageFromFinder(_ item: FTPageType) {
        self.addNewpageMode = FTFinderPageMode
        if item == .pageFromCamera || item == .photoTemplate {
            self.insertingPhotoAsPage = true
        }
        self.performPageInsertOperation(item)
    }
    
    func performPageInsertOperation(_ item: FTPageType) {
        switch item {
        case .newPage:
            self.executer?.execute(type: .addPage)
            break
        case .chooseTemplate:
            self.isNewPageFromTemplate = true
            self.showPaperTemplateScreen(source: .addMenu)
            break
        case .photoTemplate:
            FTPHPicker.shared.presentPhPickerController(from: self, selectionLimit: 1)
        case .scanDocument:
            let scanService = FTScanDocumentService.init(delegate: self)
            scanService.startScanningDocument(onViewController: self)
        case .pageFromCamera:
            self.openCamera()
        case .importDocument:
            self.importDocumentClicked(nil)
        case .inserFromclipboard:
            if nil != FTPasteBoardManager.shared.getBookUrl() {
                let pageIndex = self.currentlyVisiblePage()?.pageIndex() ?? self.numberOfPages();
                self.insertPagesFromClipBoard(atIndex: pageIndex + 1, showLoaderOnViewController: self) { (_, error) in
                    if error != nil {
                        self.refreshUIforInsertedPages(at: UInt(pageIndex + 1),
                                                       count: 0,
                                                       forceReLayout: true);
                    }
                }
            }
            
            FTPasteBoardManager.shared.handledCopiedItems { (list) in
                var items = [FTImportItem]();
                list.fileItems.forEach { (eachItem) in
                    let item = FTImportItem(item: eachItem as AnyObject, onCompletion: nil);
                    items.append(item);
                }
                list.notebookItems.forEach { (eachItem) in
                    let item = FTImportItem(item: eachItem as AnyObject, onCompletion: nil);
                    items.append(item);
                }
                list.imageItems.forEach { (eachImage) in
                    let item = FTImportItem(item: eachImage, onCompletion: nil);
                    items.append(item);
                }
                self.beginImporting(items: items);
            }
        }
    }

    func showPaperTemplateScreen(source: Source) {
        let basicTemplatesDataSource = FTBasicTemplatesDataSource.shared
         let dataSource = basicTemplatesDataSource.basictemplateDateSourceForMode(.template)
         let paperVariantsDataModel = FTPaperTemplatesVariantsDataModel(templateColors: dataSource.colorModel,
                                                                        lineHeights: dataSource.lineHeightsModel,
                                                                        sizes: dataSource.sizeModel)
        let selPaperTheme = FTThemesLibrary(libraryType: .papers).getDefaultTheme(defaultMode: .template)
        var variants = basicTemplatesDataSource.variantsForMode(.template)
        self.updateVariants(&variants)

        let selectedPaperVariantsAndTheme =
         FTSelectedPaperVariantsAndTheme(templateColorModel: variants.color,
                                         lineHeight: variants.lineHeight,
                                         orientation: variants.orientaion,
                                         size: variants.templateSize,
                                        selectedPaperTheme: selPaperTheme)
         if let basicThemes = FTBasicTemplatesDataSource.shared.fetchThemesForMode(.template).first {
             let paperTemplateDataManager = FTPaperTemplateDataHelper(variantsData: paperVariantsDataModel, selectedVariantData: selectedPaperVariantsAndTheme, basicPaperThemes: basicThemes)
             FTPaperTemplateViewController.showPaperTemplateScreen(from: self,delegate: self, variantsData: paperTemplateDataManager, source: source)
         }
    }

    /// Media
    func didTapMedia(_ item: MediaType) {
        switch item {
        case .audio:
            debugPrint("recordAudio")
            didClick(onAddNewRecording: self)
        case .importMedia:
            self.insertingPhotoAsPage = true
            self.importMediaTapped(nil)
        default:
            break;
        }
    }
    
    ///Attachment
    func didTapAttachment(_ item: AttachmentType) {
        switch item {
        case .webClip:
            FTWebClipViewController.showWebClip(overViewController: self, withDelegate: self)
        default:
            break
        }
    }
}
extension FTPDFRenderViewController: FTSavedClipdelegate {
    func didTapSavedClip(clip: FTSavedClipModel) {
        func performCopy(annotations: [FTAnnotation], completion: @escaping () -> Void) {
            if let pageController = self.firstPageController(), let page = pageController.pdfPage as? FTNoteshelfPage {
                let vertices = annotations.map { eachAnn in
                    return CGPoint(x: eachAnn.boundingRect.midX, y: eachAnn.boundingRect.midY)
                }
                var startRect = FTShapeUtility.boundingRect(vertices)
                if annotations.count == 1 {
                    let boundingRect = annotations.first?.boundingRect ?? CGRect.zero
                    startRect = boundingRect
                }
                let screenArea = CGRect.scale(pageController.contentHolderView!.bounds, 1 / pageController.contentScale())
                let targetRect = CGRect(x: (screenArea.size.width - startRect.size.width) * 0.5, y: (screenArea.size.height - startRect.size.height) * 0.5, width: startRect.size.width, height: startRect.size.height)
                let translateX = targetRect.origin.x - startRect.origin.x;
                let translateY = targetRect.origin.y - startRect.origin.y;
                let groupId = UUID().uuidString
                annotations.forEach { eachAnn in
                    eachAnn.groupId = groupId
                    eachAnn.setOffset(CGPoint(x: translateX, y: translateY))
                }
                page.deepCopyAnnotations(annotations, disableUndo: false) { [pageController] copiedAnnotations in
                    pageController.resizeSavedClipFor(annotations: copiedAnnotations)
                    completion()
                }
            }
        }

        if let fileUrl = FTSavedClipsProvider.shared.fileUrlForClip(clip: clip) {
            let request = FTDocumentOpenRequest(url: fileUrl, purpose: .read)
            FTNoteshelfDocumentManager.shared.openDocument(request: request) { token, snippetsDocument, error in
                if error != nil {
                } else if let snippetsDocument, let firstPage = snippetsDocument.pages().first {
                    let annotations = firstPage.annotations()
                    performCopy(annotations: annotations, completion: {
                        FTNoteshelfDocumentManager.shared.closeDocument(document: snippetsDocument, token: token, onCompletion: nil)
                    })
                }
            }
        }
    }

}

extension FTPDFRenderViewController: FTImportingProtocol {

    #if targetEnvironment(macCatalyst)
    func addAnnotationButtonAction(toolbarItem: NSToolbarItem) {
        self.normalizeAndEndEditingAnnotation(true);
        FTAddDocumentEntitiesViewController.showAsPopover(source: toolbarItem, fromViewController: self, delegate: self)
    }
    #endif
    
    @objc func addAnnotationButtonAction(source: UIView) {
        self.normalizeAndEndEditingAnnotation(true);
      let addDocVc =   FTAddDocumentEntitiesViewController.showAsPopover(source: source, fromViewController: self, delegate: self)
        addDocVc.ftPresentationDelegate.onDismissBlock = {
            self.statusInformer.updateRightPanelToolStatus()
        }
    }
    
    @objc func showStickyScreen(sourceView:UIView) {
        self.insertingPhotoAsPage = false;
        FTEmojisViewController.showAsPopover(fromSourceView: sourceView, overViewController: self, withDelegate: self)
    }
    
    //MARK:- FTDocumentEntitySelectionDelegate
    func currentPageInfoFromPDFRenderer() -> FTPageProtocol? {
        if let pageViewController = self.firstPageController(), let curPage = pageViewController.pdfPage {
            return curPage;
        }
        return nil;
    }
    
    //MARK:- FTPhotosViewControllerDelegate
    func photosCollectionViewController(_ photosCollectionViewController: FTPhotosViewController, didFinishPickingPhoto photo: UIImage) {
    }
    
    func photosCollectionViewController(_ photosCollectionViewController: UIViewController, didFinishPickingPhotos photos: [UIImage],isCamera: Bool) {
        self.dismiss(animated: true, completion: {
            if !photos.isEmpty {
                if self.insertingPhotoAsPage {
                    self.insertingPhotoAsPage = false;
                    var items = [FTImportItem]();
                    photos.forEach { (eachPhoto) in
                        let item = FTImportItem(item: eachPhoto, onCompletion: nil);
                        items.append(item);
                    }
                    // TODO : PageViewContoller implemet this
                    self.beginImporting(items: items)
                }
                else {
                    // TODO : MediaViewContoller implemet this
                    self.insert(photos, center: .zero, droppedPoint: .zero, source: isCamera ? FTInsertImageSourceCamera : FTInsertImageSourcePhotos)
                }
            }
        });
    }
    
    func handleCameraClickInPhotosCollectionViewController(_ photosCollectionViewController: UIViewController) {
        if let presentedViewController = self.presentedViewController {
            presentedViewController.dismiss(animated: true, completion: {
                self.openCamera()
            })
        }
        else {
            self.openCamera()
        }
    }

    private func openCamera() {
        FTImagePicker.shared.showImagePickerController(from: self)
    }

    //MARK:- ImportDocument
    func beginImporting(items: [FTImportItem]) {
        let progress = Progress();
        progress.totalUnitCount = Int64(items.count);
        progress.localizedDescription = NSLocalizedString("Importing", comment: "Importing");
        
        let smartProgessView = FTSmartProgressView.init(progress: progress);
        smartProgessView.showProgressIndicator(NSLocalizedString("Importing", comment: "Importing"), onViewController: self);
        
        let currentPageCount = self.pdfDocument.pages().count;
        let index = self.getNewPageInsertIndex();
        self.importItems(items,progress: progress) { (error) in
            smartProgessView.hideProgressIndicator();
            if(nil != error) {
                (error! as NSError).showAlert(from: self)
            }
            else {
                let newPagesCount = self.pdfDocument.pages().count;
                let pagesAdded = newPagesCount - currentPageCount;
                if(pagesAdded > 0) {
                    runInMainThread {
                        self.refreshUIforInsertedPages(at: UInt(index),
                                                       count: UInt(pagesAdded),
                                                       forceReLayout: true);
                    }
                }
            }
        }
    };
    
    private func importItems(_ items : [FTImportItem],
                             progress : Progress,
                             onCompletion : ((Error?) -> Void)?){
        progress.localizedDescription = NSLocalizedString("Importing", comment: "Importing");
        
        var itemsToImport = items;
        let firstItem = itemsToImport.last;
        if(nil != firstItem) {
            let subprogress = self.insertFileItem(firstItem!,
                                                  atIndex: self.getNewPageInsertIndex(),
                                                  onCompletion: { (_, error) in
                if(error != nil) {
                    onCompletion?(error);
                }
                else {
                    itemsToImport.removeLast();
                    self.importItems(itemsToImport,
                                     progress: progress,
                                     onCompletion: onCompletion)
                }
            });
            progress.addChild(subprogress, withPendingUnitCount: 1);
        }
        else {
            onCompletion?(nil);
        }
    }
}

// MARK: - Unsplash
extension FTPDFRenderViewController: FTAddMenuSelectImageProtocal {
    func didSelectImage(_ images: [UIImage], source: FTInsertImageSource) {
        self.insert(images, center: .zero, droppedPoint: .zero, source: FTInsertImageSourcePhotos)
    }
}

//MARK:- TagsViewControllerDelegate
var selectedShelfTagItems = Dictionary<String, FTShelfTagsItem>()

extension FTPDFRenderViewController: FTTagsViewControllerDelegate {
    func didDismissTags() {
        let items = selectedShelfTagItems.values.reversed();
        selectedShelfTagItems.removeAll()
        FTShelfTagsUpdateHandler.shared.updateTagsFor(items: items, completion: nil)
    }

    func tagsViewControllerFor(items: [FTShelfItemProtocol], onCompletion: @escaping ((Bool) -> Void)) {

    }

    func addTagsViewController(didTapOnBack controller: FTTagsViewController) {
        controller.dismiss(animated: true, completion: nil)
    }

    func didAddTag(tag: FTTagModel) {
        self.updateShelfTagItemsFor(tag: tag)
    }

    func didUnSelectTag(tag: FTTagModel) {
        self.updateShelfTagItemsFor(tag: tag)
    }

    private func updateShelfTagItemsFor(tag: FTTagModel) {
        if let tagModel = FTTagsProvider.shared.getTagItemFor(tagName: tag.text) {
            if let page = self.currentlyVisiblePage() as? FTThumbnailable
                , let documentItem = self.currentShelfItemInSidePanelController() as? FTDocumentItemProtocol {
                tagModel.updateTagForPages(documentItem: documentItem, pages: [page]) { [weak self] items in
                    guard let self = self else { return }
                    items.forEach { item in
                        (page as? FTNoteshelfPage)?.addTags(tags: item.tags.map({$0.text}))
                        selectedShelfTagItems[page.uuid] = item;
                        NotificationCenter.default.post(name: .shouldReloadFinderNotification, object: nil)
                    }
                }
            }
        }
    }

}

//Mark:- WebclipControllerDelegate
extension FTPDFRenderViewController: FTWebClipControllerDelegate {
    func didCaptureScreenShot(screenShot: UIImage?, clipUrlString: String?) {
        if let img = screenShot {
            self.insertClip(img, webClipUrlString: clipUrlString)
        }
    }
}

extension FTPDFRenderViewController : FTImportFileHandlerDelegate
{
    public var supportsNoteshelfFormat : Bool {
        return false;
    }
    
    public var supportsAudioFileImport: Bool {
        return true;
    }
    
    public var allowsMultipleSelection : Bool {
        return true;
    }
    
    public func importFileHandler(_ handler: FTImportFileHandler, didFinishingPickingURL urls: [URL]) {
        
        var importItem = [FTImportItem]();
        urls.forEach { (eachURL) in
            let item = FTImportItem(item: eachURL as AnyObject, onCompletion: nil);
            importItem.append(item);
        }
        self.beginImporting(items: importItem);
        FTNotebookEventTracker.trackFreePageAddedEvent()
        self.importFileHandler = nil;
    }
}

extension FTPDFRenderViewController {
    fileprivate func updateVariants(_ variants: inout FTBasicPaperVariants) {
        let basicTemplatesDataSource = FTBasicTemplatesDataSource.shared
        if let page = self.currentlyVisiblePage() as? FTNoteshelfPage {
            // Lineheight automation
            let lineHeight = page.lineHeight
            if let type = basicTemplatesDataSource.getLIneTypes().first(where: { lineType in
                Int(lineType.horizontalLineSpacing) == lineHeight && Int(lineType.verticalLineSpacing) == lineHeight
            }) {
                variants.lineHeight = type.lineType
            }

            // Color automation
            var bgColor = page.pageBackgroundColor
            if nil == bgColor {
                bgColor = page.pdfPageRef?.getBackgroundColor()
            }
            if let reqColor = bgColor {
                if let model = basicTemplatesDataSource.getTemplateColorsDataForMode(.template).first(where: { colorModel in
                    colorModel.hex.isEqualToHexColor(reqColor.hexString)
                }) {
                    variants.color = model
                } else {
                    variants.color = FTTemplateColorModel(color: .custom, hex: reqColor.hexString)
                }
            }

            // Orientation automation
            var pageSize = page.pdfPageRect.size
            let roundedWidth = pageSize.width.rounded()
            let roundedHeight = pageSize.height.rounded()
            pageSize = CGSize(width: roundedWidth, height: roundedHeight)

            variants.orientaion = FTTemplateOrientation.orientation(for: pageSize)

            // Size automation
            var isBasicFound = false
            let sizeModels = basicTemplatesDataSource.getTemplateSizeData()

            for sizeModel in sizeModels {
                let size = sizeModel.requiredSize(with: variants.orientaion)
                if size.equalTo(pageSize) {
                    variants.templateSize = sizeModel.size
                    isBasicFound = true
                    break
                }
            }

            if !isBasicFound {
                for sizeModel in sizeModels {
                    let size = sizeModel.requiredSize(with: variants.orientaion)
                    if size.validate(with: pageSize, by: 0.2) {
                        variants.templateSize = sizeModel.size
                        break
                    }
                }
            }
        }
    }

    @objc func undo(_ sender:Any) {
        let undoMethod = self as FTDeskToolbarDelegate;
        undoMethod.undo?();
    }
    
    @objc func redo(_ sender: Any) {
        let undoMethod = self as FTDeskToolbarDelegate;
        undoMethod.redo?();
    }
    
    override open func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        var canPerform: Bool = false//super.canPerformAction(action, withSender: sender);
#if targetEnvironment(macCatalyst)
        if self.containsLoadingActivity() || self.presentedViewController != nil {
            return false;
        }
        
        if action == #selector(paste(_:)) {
            if self.currentDeskMode != RKDeskMode.deskModeLaser {
                canPerform = UIPasteboard.canPasteContent()
            }
        }
        if action == #selector(cut(_:))
            || action == #selector(copy(_:))
            || action == #selector(delete(_:)) {
            canPerform = self.firstPageController()?.canPerformMenuAction(action) ?? false;
        }
        else {
            canPerform = self.canPeformAction(action: action);
        }
#else
        if self.currentDeskMode == RKDeskMode.deskModeClipboard {
            if (action == #selector(pasteMenuAction2(_:)) || action == #selector(newCutCopyMenuAction(_:))){
                canPerform = true
            }
        }
        else if(action == #selector(self.undo(_:))) || (action == #selector(self.redo(_:))) {
            if(action == #selector(self.undo(_:))) {
                canPerform = self.undoManager?.canUndo ?? false;
            }
            else if(action == #selector(self.redo(_:))) {
                canPerform = self.undoManager?.canRedo ?? false;
            }
        }
#endif
        return canPerform
    }

    //MARK:- Navigation
    @objc func importMediaTapped(_ sender: Any?) {
        self.insertingPhotoAsPage = true
        if(nil == self.importFileHandler) {
            self.importFileHandler = FTImportFileHandler(withDelegate: self);
        }
        self.importFileHandler?.insertFrom(onViewController: self);
    }
}

#if targetEnvironment(macCatalyst)
extension FTPDFRenderViewController {
    open override func copy(_ sender: Any?) {
        self.firstPageController()?.performMenuAction(#selector(copy(_:)));
    }
    
    open override func cut(_ sender: Any?) {
        self.firstPageController()?.performMenuAction(#selector(cut(_:)));
    }
    
    open override func delete(_ sender: Any?) {
        self.firstPageController()?.performMenuAction(#selector(delete(_:)));
    }
    
    open override func validate(_ command: UICommand) {
        super.validate(command)
        if self.firstPageController()?.pdfPage?.isBookmarked ?? false {
            command.state = .on
        }
    }
}
#endif

extension FTPDFRenderViewController: FTPaperTemplateDelegate {
    public func paperTemplatePicker(_ contmroller: UIViewController, showIAPAlert feature: String?) {
        if let inFeature = feature {
            FTIAPurchaseHelper.shared.showIAPAlertForFeature(feature: inFeature, on: contmroller);
        }
        else {
            FTIAPurchaseHelper.shared.showIAPAlert(on: contmroller);
        }
    }
    
    public func didSelectDigitalDiary(fileName: String, title: String, startDate: Date, endDate: Date, coverImage: UIImage, isLandScape: Bool) {
        let stockFolder = "StockPapers";
        let url1 = Bundle.main.url(forResource: stockFolder, withExtension: "bundle")!;
        let subFiles = try? FileManager.default.contentsOfDirectory(at: url1, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
        let planner = subFiles?.filter { $0.lastPathComponent == "\(fileName).nsp" }
        if let plannerUrl = planner?.first {
            if let theme = FTTheme.theme(url: plannerUrl, themeType: .papers) as? FTAutoTemlpateDiaryTheme {
                theme.startDate = startDate
                theme.endDate = endDate
                var varients = FTBasicTemplatesDataSource.shared.getDefaultVariants()
                varients.isLandscape = isLandScape
                varients.selectedDevice = FTDeviceDataManager().getCurrentDevice()
                (theme as FTPaperTheme).setPaperVariants(varients)
                self.addPaperTheme(theme)
            }
        }

    }

    public func didSelectTemplate(info: FTTemplatesStore.FTTemplateInfo) {
        if let fileUrl = info.url {
            let theme = FTStoreTemplatePaperTheme(url: fileUrl)
            theme.isCustom = info.isCustom
            let bgColor = info.isDark ? UIColor(hexString: "#1D232F") : UIColor.white
            let lineColorHex = FTBasicThemeCategory.getCustomLineColorHex(bgHex: bgColor.hexStringFromColor())
            let dict = ["colorName": FTTemplateColor.custom.displayTitle,
                        "colorHex": bgColor.hexStringFromColor(),
                        "horizontalLineColor": lineColorHex,
                        "verticalLineColor":  lineColorHex]
            let customThemeColor = FTThemeColors(dictionary: dict)
            var variants = FTBasicTemplatesDataSource.shared.getDefaultVariants()
            variants.isLandscape = info.isLandscape
            variants.selectedDevice = FTDeviceDataManager().getCurrentDevice()
            variants.selectedColor = customThemeColor
            theme.setPaperVariants(variants)
            self.addPaperTheme(theme)
        }
    }
    private func addPaperTheme(_ theme:FTThemeable) {
        guard let reqTheme = theme as? FTPaperTheme else {
            return;
        }
        Task {
            let loadingIndicatorViewController = FTLoadingIndicatorViewController.show(onMode: .activityIndicator, from: self.parent ?? self, withText: "");
            do {
                let generator = FTAutoTemplateGenerator.autoTemplateGenerator(theme:reqTheme,generationType :FTGenrationType.template)
                let docInfo = try await generator.generate()
                docInfo.isCustomTemplate = reqTheme.isCustom;
                docInfo.rootViewController = self;

                if self.isNewPageFromTemplate {
                    let newPageIndex = self.getNewPageInsertIndex();
                    self.isNewPageFromTemplate = false;
                    let pagesAdded = await insertNewPage(docInfo: docInfo)
                    if(pagesAdded > 0) {
                        self.refreshUIforInsertedPages(at: UInt(newPageIndex), count: UInt(pagesAdded), forceReLayout: true);
                        self.pdfDocument.isDirty = true
                    }
                }
                else {
                    if let curPage = self.currentlyVisiblePage() {
                        try await changePageTemplate(docInfo: docInfo, currentPage: curPage)
                        loadingIndicatorViewController.hide()
                        self.pdfDocument.isDirty = true
                        NotificationCenter.default.post(name: NSNotification.Name.FTPageDidChangePageTemplate, object: curPage);
                    }
                }
                loadingIndicatorViewController.hide();
            } catch let error as NSError {
                if(!(error.domain == FTDocumentCreateErrorDomain && error.code == FTDocumentCreateErrorCode.cancelled.rawValue)) {
                    error.showAlert(from: self)
                }
                loadingIndicatorViewController.hide();
            }
        }
    }
    public func didSelectPaperTheme(theme: FTSelectedPaperVariantsAndTheme) {
        udpatePaperThemeAndVariants(theme)
        guard let reqTheme = theme.theme as? FTPaperTheme else {
            return;
        }
        let variants = FTBasicTemplatesDataSource.shared.fetchSelectedVaraintsForMode(.template)
        reqTheme.setPaperVariants(variants)
        self.addPaperTheme(reqTheme)
        FTNotebookEventTracker.trackFreePageAddedEvent()
    }
    private func udpatePaperThemeAndVariants(_ themeWithVariants: FTNewNotebook.FTSelectedPaperVariantsAndTheme) {
        let basicTemplatesDataSource = FTBasicTemplatesDataSource.shared
        basicTemplatesDataSource.saveThemeWithVariants(themeWithVariants,mode: .template)
    }

    @objc func importDocumentClicked(_ sender: AnyObject?) {
        self.insertingPhotoAsPage = true
        if(nil == self.importFileHandler) {
            self.importFileHandler = FTImportFileHandler(withDelegate: self);
        }
        self.importFileHandler?.importFile(onViewController: self);
    }

   @MainActor
   func insertNewPage(docInfo: FTDocumentInputInfo) async -> Int {
       return await withCheckedContinuation({ continuation in
           docInfo.insertAt = self.getNewPageInsertIndex();
           let oldpageCount = self.numberOfPages();
           self.pdfDocument.insertFile(docInfo) { (_, _) in
               let newPageCount = self.numberOfPages();
               let pagesAdded = newPageCount - oldpageCount;
               continuation.resume(returning: pagesAdded)
           }
       })
   }

   @MainActor
   func changePageTemplate(docInfo: FTDocumentInputInfo, currentPage: FTPageProtocol) async throws {
       return try await withCheckedThrowingContinuation { continuation in
           self.pdfDocument.updatePageTemplate(page: currentPage,
                                               info: docInfo,
                                               onCompletion: { (error, success) in
               if let error {
                   continuation.resume(throwing: error)
               } else if success {
                   continuation.resume()
               }
           })
       }
   }

}

private extension CGSize {
    func validate(with size: CGSize, by diff: CGFloat = 0.1) -> Bool {
        let widthDifference = max(width, size.width) * diff
        let heightDifference = max(height, size.height) * diff
        let widthInRange = abs(width - size.width) <= widthDifference
        let heightInRange = abs(height - size.height) <= heightDifference
        return widthInRange && heightInRange
    }
}
