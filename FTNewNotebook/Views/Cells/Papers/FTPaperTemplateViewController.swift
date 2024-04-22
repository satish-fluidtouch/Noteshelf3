//
//  FTPaperTemplateViewController.swift
//  FTNewNotebook
//
//  Created by Rakesh on 22/05/23.
//

import UIKit
import FTCommon
import FTTemplatesStore

enum FTPaperTemplateSegment: Int {
    case essentials
    case library
    case custom
    
    func title() -> String {
        var title = ""
        switch self {
        case .essentials:
            title = "paper.template.essentials".localized
        case .library:
            title = "paper.template.library".localized
        case .custom:
            title = "paper.template.custom".localized
        }
        return title
    }
}

public protocol FTPaperTemplateDelegate : AnyObject {
    func didSelectTemplate(info: FTTemplateInfo)
    func didSelectPaperTheme(theme: FTSelectedPaperVariantsAndTheme)
    func didSelectDigitalDiary(fileName: String, title: String, startDate: Date, endDate: Date, coverImage: UIImage, isLandScape: Bool)
    func paperTemplatePicker(_ contmroller: UIViewController, showIAPAlert feature: String?);
}

public class FTPaperTemplateDataHelper {
    private(set) var variantsDataModel: FTPaperTemplatesVariantsDataModel!
    var selectedVariantsAndTheme: FTSelectedPaperVariantsAndTheme!
    var basicPaperThemes: FTBasicTemplateCategoryModel!

    public init(variantsData: FTPaperTemplatesVariantsDataModel, selectedVariantData: FTSelectedPaperVariantsAndTheme,basicPaperThemes:FTBasicTemplateCategoryModel) {
        self.variantsDataModel = variantsData
        self.selectedVariantsAndTheme = selectedVariantData
        self.basicPaperThemes = basicPaperThemes
    }
}

public class FTPaperTemplateViewController: UIViewController {
    private var varaintsData: FTPaperTemplateDataHelper!
    public func configure(varaintsData: FTPaperTemplateDataHelper,delegate: FTPaperTemplateDelegate?) {
        self.varaintsData = varaintsData
        self.currentSelectedThemeURL = varaintsData.selectedVariantsAndTheme.theme.themeFileURL
        self.delegate = delegate
    }
    weak var delegate: FTPaperTemplateDelegate?
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var paperTemplateSegment: UISegmentedControl!

    public var source: Source = .none
    private var libraryVC: UIViewController!
    private var customVC: UIViewController!
    private var storeTemplateInfo: FTTemplateInfo?

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.setUpStoreViewControllers()
        self.styleNavigationBar()
        let segCount = self.paperTemplateSegment.numberOfSegments
        for i in 0..<segCount {
            let title = FTPaperTemplateSegment(rawValue: i)?.title() ?? ""
            self.paperTemplateSegment.setTitle(title, forSegmentAt: i)
        }
    }
    private var currentSelectedThemeURL : URL?
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setSelectedSegmentBasedOnPreviousSelection()
        updateView()
    }
    @IBAction func paperTemplateSegmentTapped(_ sender: Any) {
        updateView()
    }
    private func setSelectedSegmentBasedOnPreviousSelection() {
        let selectedTheme = varaintsData.selectedVariantsAndTheme.theme
        if selectedTheme.dynamicId == 2 {
            self.paperTemplateSegment.selectedSegmentIndex = 0
        } else if selectedTheme.dynamicId == 3 {
            self.paperTemplateSegment.selectedSegmentIndex = selectedTheme.isCustom ? 2 : 1
        }
    }
    private func setUpStoreViewControllers(){
        let selectedUrl = self.varaintsData.selectedVariantsAndTheme.theme.themeFileURL
        libraryVC = FTStoreContainerViewController.storeLibraryViewController(source: self.source,delegate: self, selectedFile: selectedUrl);
        customVC = FTStoreContainerViewController.storeCustomViewController(source: self.source, delegate: self, selectedFile: selectedUrl)
    }
    private func updateView() {
        if source == .addMenu || source == .finder {
            self.navigationItem.rightBarButtonItem?.isHidden = true
        } else {
            self.navigationItem.rightBarButtonItem?.isHidden = false
        }
        if paperTemplateSegment.selectedSegmentIndex == 0 {
            add(asChildViewController: essentialViewcontroller)
            remove(asChildViewController: libraryVC)
            remove(asChildViewController: customVC)
        } else if paperTemplateSegment.selectedSegmentIndex == 1 {
            add(asChildViewController: libraryVC)
            remove(asChildViewController: essentialViewcontroller)
            remove(asChildViewController: customVC)

        } else {
            add(asChildViewController: customVC)
            remove(asChildViewController: essentialViewcontroller)
            remove(asChildViewController: libraryVC)
        }
    }
    private func add(asChildViewController viewController: UIViewController) {
        addChild(viewController)
        containerView.addSubview(viewController.view)
        viewController.view.frame = containerView.bounds
        viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        viewController.didMove(toParent: self)
    }
    private func remove(asChildViewController viewController: UIViewController) {
        viewController.willMove(toParent: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
    }
    private lazy var essentialViewcontroller: FTEssentialsPaperSegmentViewController = {
        let storyboard = UIStoryboard.init(name: "FTPapers", bundle: currentBundle)
        var viewController = storyboard.instantiateViewController(withIdentifier: "FTEssentialsPaperSegmentViewController") as! FTEssentialsPaperSegmentViewController
        viewController.configure(varaintsData: varaintsData,source: source,delegate: delegate, themeUpdateDel: self)
        self.add(asChildViewController: viewController)
        return viewController
    }()
    private func styleNavigationBar(){
        self.title = "shelf.quickCreateSettings.paperTemplate".localized
        let titleAttrs = [NSAttributedString.Key.font: UIFont.clearFaceFont(for: .medium, with: 20.0), NSAttributedString.Key.foregroundColor: UIColor.label]
        self.navigationController?.navigationBar.titleTextAttributes = titleAttrs
        let leftNavItem = FTNavBarButtonItem(type: .left, title: "Cancel".localized, delegate: self)
        let rightNavItem = FTNavBarButtonItem(type: .right, title: "Done".localized, delegate: self)
        self.navigationItem.leftBarButtonItem = leftNavItem
        self.navigationItem.rightBarButtonItem = rightNavItem
    }
}
extension FTPaperTemplateViewController {
      public static func showPaperTemplateScreen(from viewController: UIViewController,
                                               delegate: FTPaperTemplateDelegate,
                                                 variantsData: FTPaperTemplateDataHelper, source: Source) {
        let storyboard = UIStoryboard.init(name: "FTPapers", bundle: currentBundle)
        if let paperTemplateVc = storyboard.instantiateViewController(withIdentifier: "FTPaperTemplateViewController") as? FTPaperTemplateViewController {
            paperTemplateVc.source = source
            paperTemplateVc.configure(varaintsData: variantsData, delegate: delegate)
            let navController = UINavigationController(rootViewController: paperTemplateVc)
            viewController.ftPresentFormsheet(vcToPresent: navController, hideNavBar: false)
        }
    }
}
extension FTPaperTemplateViewController: FTBarButtonItemDelegate {
    public func didTapBarButtonItem(_ type: FTBarButtonItemType) {
        if type == .left {
            self.dismiss(animated: true)
        } else {
            self.dismiss(animated: true)
            if storeTemplateInfo != nil {
                self.didSelectStoreTemplate()
            } else {
                self.delegate?.didSelectPaperTheme(theme: self.varaintsData.selectedVariantsAndTheme)
            }
        }
    }
}
public class FTPaperTemplateNavigationController: UINavigationController {
}

extension FTPaperTemplateViewController: FTStoreLibraryDelegate {
    public func libraryController(_ contmroller: UIViewController, menuShown isMenuShown: Bool) {
    }

    public func currentSelectedURL() -> URL? {
        return self.currentSelectedThemeURL
    }
    
    public func setCurrentSelectedURL(url: URL) {
        self.currentSelectedThemeURL = url
    }

    public func libraryController(_ contmroller: UIViewController, showIAPAlert feature: String?) {
        self.delegate?.paperTemplatePicker(contmroller, showIAPAlert: feature);
    }
    
    public func libraryController(_ contmroller: UIViewController, didSelectTemplate info: FTTemplateInfo) {
        storeTemplateInfo = info
        if source != .shelf {
            self.dismiss(animated: true) {
                self.didSelectStoreTemplate()
            }
        }
    }

    func didSelectStoreTemplate() {
        if let dairyInfo = storeTemplateInfo as? FTDairyTemplateInfo {
            delegate?.didSelectDigitalDiary(fileName: dairyInfo.themeName, title: dairyInfo.title ?? "Untitiled", startDate: dairyInfo.startDate, endDate: dairyInfo.endDate, coverImage: dairyInfo.coverImage ?? UIImage(), isLandScape: dairyInfo.isLandscape)
        } else if let templateInfo = storeTemplateInfo{
            delegate?.didSelectTemplate(info: templateInfo)
        }
    }

}

extension FTPaperTemplateViewController: FTStoreCustomDelegate {
    public func customController(_ contmroller: UIViewController, menuShown isMenuShown: Bool) {
    }

    public func customController(_ contmroller: UIViewController, showIAPAlert feature: String?) {
        self.delegate?.paperTemplatePicker(contmroller, showIAPAlert: feature);
    }
    
    public func customController(_ contmroller: UIViewController, didSelectTemplate info: FTTemplatesStore.FTTemplateInfo) {
        storeTemplateInfo = info
        if source != .shelf {
            self.dismiss(animated: true) {
                self.didSelectStoreTemplate()
            }
        }
    }
}
