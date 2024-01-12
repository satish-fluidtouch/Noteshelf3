//
//  FTStoreContainerViewController.swift
//  TempletesStore
//
//  Created by Siva on 21/02/23.
//

import UIKit
import Combine
import FTCommon
import PhotosUI
import SDWebImage

let storeBundle = Bundle(for: FTStoreContainerViewController.self)
public protocol FTStoreContainerDelegate: AnyObject {
    func generatePDFFile(withImages images : [UIImage]) async -> URL?
    func convertFileToPDF(filePath: String) async throws -> URL?
    func createNotebookFor(url: URL, onCompletion: @escaping ((Error?) -> Void))
    func createNotebookForTemplate(url: URL, isLandscape: Bool, isDark: Bool)
    func createNotebookForDairy(fileName: String, title: String, startDate: Date, endDate: Date, coverImage: UIImage, isLandScape: Bool)
    func storeController(_ controller: UIViewController,showIAPAlert feature: String?);
    func storeController(_ controller: UIViewController,menuShown isMenuShown: Bool);
    func trackEvent(event: String, params: [String : Any]?, screenName: String?)
}

public class FTStoreContainerViewController: UIViewController {

    public weak var delegate: FTStoreContainerDelegate?
    @IBOutlet private weak var topView: UIView!
    @IBOutlet weak var segmentControl: FTSegmentedControl!

    var topSegmentView: UIView? {
        let viewToReturn = self.topView;
        if var frame = viewToReturn?.frame {
            frame.size.height = 50;
            viewToReturn?.frame = frame;
        }
        return viewToReturn;
    }
    private var customTemplateImportManager = FTCustomTemplateImportManager()
    private var actionManager = FTStoreActionManager()

    lazy var storeFavouriteViewController: FTStoreLibraryViewController = {
        let controller = FTStoreLibraryViewController.controller(source: .none, delegate: self, selectedFile: nil)
        return controller;
    }()

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "templatesStore.navbar.templates".localized
        self.setupView()
    }

    public func scrollToInspirations() {
        // TODO: Narayana
    }
    
    public func navigateToDairies() {
        // TODO: Narayana
    }

    func initializeImportButton() {
        let menu = UIMenu(title: "", options: .displayInline, children: [
            UIAction(title: "templatesStore.custom.import.importFromFiles".localized, handler: {[weak self] _ in
                self?.customTemplateImportManager.actionStream.send(.files)
                // Track Event
                self?.delegate?.trackEvent(event: EventName.custom_import_fromfiles_tap, params: nil, screenName: ScreenName.templatesStore)
            }),
            UIAction(title: "templatesStore.custom.import.photoLibrary".localized, handler: {[weak self] _ in
                self?.customTemplateImportManager.actionStream.send(.photoLibrary)
                // Track Event
                self?.delegate?.trackEvent(event: EventName.custom_import_photolibrary_tap, params: nil, screenName: ScreenName.templatesStore)

            }),
            UIAction(title: "templatesStore.custom.import.takePhoto".localized, handler: { [weak self] _ in
                self?.customTemplateImportManager.actionStream.send(.takePhoto)
                // Track Event
                self?.delegate?.trackEvent(event: EventName.custom_import_takephoto_tap, params: nil, screenName: ScreenName.templatesStore)
            })
        ])
        let rightBarButton = UIBarButtonItem(title: "templatesStore.custom.import".localized, menu: menu)
        rightBarButton.tintColor = UIColor.appColor(.accent)
        self.navigationItem.rightBarButtonItem = rightBarButton
    }
}

// MARK: - Private Methods
private extension FTStoreContainerViewController {
     func setupView() {
        setupSegmentControl()
         updateView()
        observers()
    }

     func updateView() {
         removeChilderns()
        if segmentControl.selectedIndex == 0 {
            let viewController = FTStoreViewController.controller(with: actionManager)
            self.add(viewController)
            viewController.view.frame = view.bounds
         } else if segmentControl.selectedIndex == 1 {
             self.add(storeFavouriteViewController)
             storeFavouriteViewController.view.frame = view.bounds
             self.delegate?.trackEvent(event: EventName.templates_library_tap, params: nil, screenName: ScreenName.templatesStore)
         } else if segmentControl.selectedIndex == 2 {
             let viewController = FTStoreCustomViewController.controller(source: .none, delegate: self, selectedFile: nil, customTemplateImportManager: customTemplateImportManager, storeActionManager: actionManager)
             self.add(viewController)
             viewController.view.frame = view.bounds
             self.delegate?.trackEvent(event: EventName.templates_custom_tap, params: nil, screenName: ScreenName.templatesStore)
         }
    }

    func removeChilderns() {
        children.forEach({
          $0.willMove(toParent: nil)
          $0.view.removeFromSuperview()
          $0.removeFromParent()
        })
    }

    func setupSegmentControl() {
        let titles = ["templatesStore.segmentbar.discover".localized,
                      "templatesStore.segmentbar.library".localized,
                      "templatesStore.segmentbar.custom".localized]
        segmentControl.frame.size.width = self.view.frame.size.width
        segmentControl.setTitles(titles, style: .adaptiveSpace(10))
        segmentControl.textColor = UIColor.label
        segmentControl.textSelectedColor = UIColor.appColor(.accent)
        segmentControl.textCornerRadius = 0
        segmentControl.textBorderWidth = 0
        segmentControl.textFont = UIFont.appFont(for: .regular, with: 17)
        segmentControl.segmentBgColor = UIColor.clear
        segmentControl.selectedSegmentBgColor = UIColor.clear
        segmentControl.setSilder(backgroundColor: UIColor.appColor(.accent), position: .bottomWithHight(2), widthStyle: .adaptiveSpace(10))
        segmentControl.delegate = self
        segmentControl.backgroundColor = .clear
    }
}

// MARK: - Observers
extension FTStoreContainerViewController {
    func observers() {
        customTemplateImportManager.importConverterInput.sink { [weak self] action in
            guard let self = self else { return }
            switch action {
            case .convertToPDF(let filePath):
                Task {
                    do {
                        let url = try await self.delegate?.convertFileToPDF(filePath: filePath)
                         self.customTemplateImportManager.importConverterOutput.send(.importedFileUrl(url: url, error: nil))
                    } catch let error {
                         self.customTemplateImportManager.importConverterOutput.send(.importedFileUrl(url: nil, error: error))
                    }
                }
            case .generatePDF(let images):
                Task {
                    if let url = await self.convertImagesToPdf(images: images) {
                        self.customTemplateImportManager.importConverterOutput.send(.importedFileUrl(url: url, error: nil))
                    } else {
                        let error = NSError(domain: "com.ft.fileExists", code: -100, userInfo: [NSLocalizedDescriptionKey:"Unknown error while importing file"])
                        self.customTemplateImportManager.importConverterOutput.send(.importedFileUrl(url: nil, error: error))
                    }

                }
            }
        }.store(in: &customTemplateImportManager.cancellables)

        actionManager.containerActions.sink { [weak self] action in
            guard let self = self else { return }
            switch action {
            case .createNotebookForTemplate(url: let url, isLandscape: let isLandscape, isDark: let isDark):
                self.delegate?.createNotebookForTemplate(url: url, isLandscape: isLandscape, isDark: isDark)
            case .createNotebookForDairy(fileName: let fileName, title: let title, startDate: let startDate, endDate: let endDate, coverImage: let coverImage, isLandScape: let isLandScape):
                self.delegate?.createNotebookForDairy(fileName: fileName, title: title, startDate: startDate, endDate: endDate, coverImage: coverImage, isLandScape: isLandScape)
            case .createNotebookFor(url: let url):
                    self.delegate?.createNotebookFor(url: url, onCompletion: { [weak self] error in
                        self?.customTemplateImportManager.importConverterOutput.send(.createNootbookOutput(url: url, error: error))
                    })
            }
        }.store(in: &actionManager.cancellables)

        FTStorePremiumPublisher.shared.actionStream.sink { [weak self] action in
            guard let self = self else { return }
            switch action {
            case .showUpgradeAlert(controller: let controller, feature: let feature):
                self.delegate?.storeController(controller, showIAPAlert: feature);
            case .track(let event, params: let params, screenName: let screenName):
                self.delegate?.trackEvent(event: event, params: params, screenName: screenName)
            }
        }.store(in: &FTStorePremiumPublisher.shared.cancellables)
    }

    func convertImagesToPdf(images: [UIImage]) async -> URL? {
        if let requiredUrl = await self.delegate?.generatePDFFile(withImages: images) {
            return requiredUrl
        }
        return nil
    }
}

// MARK: - SegmentControlDelegate

extension FTStoreContainerViewController: FTSegmentedControlDelegate {
    public func didEndScrollOfSegments() {

    }

    public func didTapSegment(_ index: Int) {
        self.navigationItem.rightBarButtonItem = nil
        self.updateView()
        if index == 1 {
            storeFavouriteViewController.reloadData()
        }
        if index == 2 {
            initializeImportButton()
        }
    }

    public func segmentedControlSelectedIndex(_ index: Int, animated: Bool, segmentedControl: FTSegmentedControl) {
    }
}

extension FTStoreContainerViewController: FTStoreLibraryDelegate {
    public func libraryController(_ contmroller: UIViewController, menuShown isMenuShown: Bool) {
        self.delegate?.storeController(self, menuShown: isMenuShown)
    }

    public func libraryController(_ contmroller: UIViewController, showIAPAlert feature: String?) {
        self.delegate?.storeController(contmroller, showIAPAlert: feature);
    }
    
    public func libraryController(_ contmroller: UIViewController, didSelectTemplate info: FTTemplateInfo) {
        if let dairyInfo = info as? FTDairyTemplateInfo {
            self.delegate?.createNotebookForDairy(fileName: dairyInfo.themeName
                                                  , title: dairyInfo.title ?? "Untitiled"
                                                  , startDate: dairyInfo.startDate
                                                  , endDate: dairyInfo.endDate
                                                  , coverImage: dairyInfo.coverImage ?? UIImage()
                                                  , isLandScape: dairyInfo.isLandscape);
        }
        else if let fileURl = info.url {
            self.delegate?.createNotebookForTemplate(url: fileURl, isLandscape: info.isLandscape, isDark: info.isDark);
        }
    }
}

extension FTStoreContainerViewController: FTStoreCustomDelegate {
    public func customController(_ contmroller: UIViewController, menuShown isMenuShown: Bool) {
        self.delegate?.storeController(self, menuShown: isMenuShown)
    }

    public func customController(_ contmroller: UIViewController, showIAPAlert feature: String?) {
        self.delegate?.storeController(contmroller, showIAPAlert: feature);
    }
    
    
    public func customController(_ contmroller: UIViewController, didSelectTemplate info: FTTemplateInfo) {
        if let fileUrl = info.url {
                self.delegate?.createNotebookFor(url: fileUrl, onCompletion: { [weak self] error in
                    self?.customTemplateImportManager.importConverterOutput.send(.createNootbookOutput(url: fileUrl, error: error))
                })
        }
    }
}

public extension FTStoreContainerViewController {
    static func templatesStoreViewController(delegate:FTStoreContainerDelegate?,premiumUser: FTPremiumUser) -> FTStoreContainerViewController {
        let storyboard = UIStoryboard(name: "FTTemplatesStore", bundle: storeBundle)
        let viewController = storyboard.instantiateViewController(withIdentifier: "FTStoreContainerViewController") as! FTStoreContainerViewController
        viewController.delegate = delegate
        FTStorePremiumPublisher.shared.premiumUser = premiumUser;
        return viewController
    }
    // Comes from Paper templates
    static func storeLibraryViewController(source: Source,delegate: FTStoreLibraryDelegate, selectedFile: URL?) -> UIViewController  {
        let viewController = FTStoreLibraryViewController.controller(source: source, delegate: delegate, selectedFile: selectedFile)
        return viewController
    }

    // Comes from Paper templates
    static func storeCustomViewController(source: Source, delegate: FTStoreCustomDelegate, selectedFile: URL?) -> UIViewController {
        let viewController = FTStoreCustomViewController.controller(source: source, delegate: delegate, selectedFile: selectedFile, customTemplateImportManager: nil, storeActionManager: nil)
        return viewController
    }

}
