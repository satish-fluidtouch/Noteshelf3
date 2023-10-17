//
//  FTSearchResultGroupCell.swift
//  Noteshelf3
//
//  Created by Narayana on 13/06/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import FTCommon

class FTSearchResultGroupCell: FTTraitCollectionViewCell {
    @IBOutlet weak var stackPreview: UIView!

    @IBOutlet private weak var view1: UIView!
    @IBOutlet private weak var view2: UIView!
    @IBOutlet private weak var view3: UIView!
    @IBOutlet private weak var view4: UIView!

    @IBOutlet private weak var shadowImgView1: UIImageView!
    @IBOutlet private weak var shadowImgView2: UIImageView!
    @IBOutlet private weak var shadowImgView3: UIImageView!
    @IBOutlet private weak var shadowImgView4: UIImageView!

    @IBOutlet private weak var imgView1: UIImageView!
    @IBOutlet private weak var imgView2: UIImageView!
    @IBOutlet private weak var imgView3: UIImageView!
    @IBOutlet private weak var imgView4: UIImageView!

    @IBOutlet private weak var titleLabel: FTStyledLabel?
    @IBOutlet private weak var categoryTitleLabel: UILabel?
    
    @IBOutlet private weak var categoryTitleLabelBottomConstraint: NSLayoutConstraint?
    @IBOutlet private weak var titleLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var categoryTitleLabelHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var groupResultViewWidthConstraint: NSLayoutConstraint?
    @IBOutlet private weak var groupResultViewHeightConstraint: NSLayoutConstraint?

    func configureCellWithItem(_ searchItem: FTSearchResultBookProtocol,
                               searchKey: String) {
        if let groupItem = searchItem.shelfItem as? FTGroupItem {
            let reqSize = self.isRegular ? GlobalSearchConstants.BookThumbnailSize.regular : GlobalSearchConstants.BookThumbnailSize.compact
            self.groupResultViewWidthConstraint?.constant = reqSize.width
            self.groupResultViewWidthConstraint?.constant = reqSize.height
            self.layoutIfNeeded()

            self.titleLabel?.setTitle(title: searchItem.title, highlight: searchKey)
            self.categoryTitleLabel?.text = groupItem.shelfCollection.displayTitle

            var currentOrder = FTUserDefaults.sortOrder()
            if let userActivity = self.window?.windowScene?.userActivity {
                currentOrder = userActivity.sortOrder
            }
            self.hideAllImageViews()

            if groupItem.shelfCollection != nil {
                groupItem.fetchTopNotebooks(sortOrder: currentOrder,noOfBooksTofetch: 4, onCompletion: { [weak self] top4Children in
                    if top4Children.isEmpty {
                        return
                    }
                    guard let strngSelf = self else {
                        return
                    }

                    strngSelf.fetchCoverImages(for: top4Children) { images in
                        let coverImgInfo = strngSelf.fetchImagesWrToOrientation(from: images)
                        let landscapeImages = coverImgInfo.landscapeImgs
                        let portraitImages = coverImgInfo.portraitImgs
                        let comb = coverImgInfo.currentRep

                        if let reqComb = comb?.requiredCoverRepresentation() {
                            switch reqComb {
                            case .P, .L:
                                strngSelf.updateVisibleStatus(showView1: true, showView2: reqComb == .P)

                                let img1 = reqComb == .P ? portraitImages[0] : landscapeImages[0]
                                strngSelf.updateImages(image1: img1)
                                break

                            case .LP, .LL:
                                strngSelf.updateVisibleStatus(showView1: true, showView3: true, showView4: reqComb == .LP)

                                let img3 = reqComb == .LP ? portraitImages[0] : landscapeImages[1]
                                strngSelf.updateImages(image1: landscapeImages[0], image3: img3)
                                break

                            case .PP:
                                strngSelf.updateVisibleStatus(showView1: true, showView2: true, showView3: true, showView4: true)
                                strngSelf.updateImages(image1: portraitImages[0], image2: portraitImages[1])
                                break

                            case .LPP:
                                strngSelf.updateVisibleStatus(showView1: true, showView3: true, showView4: true)
                                strngSelf.updateImages(image1: landscapeImages[0], image3: portraitImages[0], image4: portraitImages[1])
                                break

                            case .PPL:
                                strngSelf.updateVisibleStatus(showView1: true, showView2: true, showView3: true)
                                strngSelf.updateImages(image1: portraitImages[0], image2: portraitImages[1], image4: landscapeImages[0])
                                break

                            case .PPP:
                                strngSelf.updateVisibleStatus(showView1: true, showView2: true, showView3: true, showView4: true)
                                strngSelf.updateImages(image1: portraitImages[0], image2: portraitImages[1], image3: portraitImages[2])
                                break

                            case .PPPP:
                                strngSelf.updateVisibleStatus(showView1: true, showView2: true, showView3: true, showView4: true)
                                strngSelf.updateImages(image1: portraitImages[0], image2: portraitImages[1], image3: portraitImages[2], image4: portraitImages[3])
                                break
                            }
                            strngSelf.updateShadowAndCornerRadiusIfNeeded()
                        }
                    }
                })
            }
        }
    }
}

private extension FTSearchResultGroupCell {
    private func updateVisibleStatus(showView1: Bool = false, showView2: Bool = false, showView3: Bool = false, showView4: Bool = false) {
        self.view1.isHidden = !showView1
        self.view2.isHidden = !showView2
        self.view3.isHidden = !showView3
        self.view4.isHidden = !showView4
    }

    private func updateImages(image1: UIImage? = nil, image2: UIImage? = nil, image3: UIImage? = nil, image4: UIImage? = nil) {
        self.imgView1.image = image1
        self.imgView2.image = image2
        self.imgView3.image = image3
        self.imgView4.image = image4
    }

    private func hideAllImageViews() {
        self.view1.isHidden = true
        self.view2.isHidden = true
        self.view3.isHidden = true
        self.view4.isHidden = true
    }

    private func updateShadowAndCornerRadiusIfNeeded() {
        self.shadowImgView1.image = nil
        self.shadowImgView2.image = nil
        self.shadowImgView3.image = nil
        self.shadowImgView4.image = nil
        
        if !view1.isHidden, nil != imgView1.image {
            updateShadow(for: self.shadowImgView1)
            imgView1.layer.cornerRadius = 4.0
        }

        if !view2.isHidden, nil != imgView2.image {
            updateShadow(for: self.shadowImgView2)
            imgView2.layer.cornerRadius = 4.0
        }
        if !view3.isHidden, nil != imgView3.image {
            updateShadow(for: self.shadowImgView3)
            imgView3.layer.cornerRadius = 4.0
        }
        if !view4.isHidden, nil != imgView4.image {
            updateShadow(for: self.shadowImgView4)
            imgView4.layer.cornerRadius = 4.0
        }

         func updateShadow(for shadowImgView: UIImageView) {
            shadowImgView.image = UIImage(named: "searchResultGroup_contentShadow")
            let scalled = shadowImgView.image?.resizableImage(withCapInsets: UIEdgeInsets(top: 2, left: 6, bottom: 10, right: 6), resizingMode: .stretch)
            shadowImgView.image = scalled
        }
    }

    private func fetchImagesWrToOrientation(from images: [UIImage?]) -> (portraitImgs: [UIImage], landscapeImgs: [UIImage], currentRep: FTGroupItemsFormat?) {
        var portraitImgInfo: [UIImage] = []
        var landscapeImgInfo: [UIImage] = []
        var requiredComb: String = ""

        images.forEach { img in
            if let image = img {
                let orientation: FTCoverOrientation = image.isPortraitDimension() ? .portrait : .landscape
                requiredComb.append(orientation.rawValue)

                if orientation == .portrait {
                    portraitImgInfo.append(image)
                } else {
                    landscapeImgInfo.append(image)
                }
            }
        }

        let currentComb = FTGroupItemsFormat(rawValue: requiredComb)
        return (portraitImgInfo, landscapeImgInfo, currentComb)
    }

    private func fetchCoverImages(for shelfItems: [FTShelfItemProtocol], completion: @escaping ([UIImage?]) -> Void) {
        let group = DispatchGroup()
        var images: [UIImage?] = []

        for shelfItem in shelfItems {
            group.enter()

            var token: String?
            var reqImg = UIImage(named: "shelfDefaultNoCover")
            token = FTURLReadThumbnailManager.sharedInstance.thumnailForItem(shelfItem) { [weak self] (image, imageToken) in
                if token == imageToken, let image {
                    reqImg = image
                }
                images.append(reqImg)

                group.leave()
            }
        }

        group.notify(queue: .main) {
            completion(images)
        }
    }
}

enum FTCoverOrientation: String {
    case portrait = "P"
    case landscape = "L"
}

enum FTGroupCoverFormat: String {
    case L
    case P
    case LP
    case PP
    case LL
    case LPP
    case PPL
    case PPP
    case PPPP
}


enum FTGroupItemsFormat: String {
    //  Children == 1
    case L
    case P

    //  Children == 2
    case PP
    case PL
    case LP
    case LL

    // Children == 3
    case PPP
    case PPL
    case PLP
    case PLL
    case LPP
    case LPL
    case LLP
    case LLL

    // Children == 4
    case PPPP
    case PPPL
    case PPLP
    case PPLL
    case PLPP
    case PLPL
    case PLLP
    case PLLL
    case LPPP
    case LPPL
    case LPLP
    case LPLL
    case LLPP
    case LLPL
    case LLLP
    case LLLL

    func requiredCoverRepresentation() -> FTGroupCoverFormat {
        var reqRep = FTGroupCoverFormat.P
        switch self {
        case .L:
            reqRep = .L

        case .P:
            reqRep = .P

        case .LP, .PL:
            reqRep = .LP

        case .PP:
            reqRep = .PP

        case .LL, .LLP, .LLL, .LLPL, .LLPP, .LLLP, .LLLL, .PLL, .LPL, .PLLP, .PLLL, .LPLL, .LPPL, .PPLL, .PLPL, .LPLP:
            reqRep = .LL

        case .PPL, .PLP, .LPP, .PLPP, .LPPP, .PPPL, .PPLP:
            reqRep = .LPP

        case .PPP:
            reqRep = .PPP

        case .PPPP:
            reqRep = .PPPP
        }
        return reqRep
    }

    // MARK: The above enum cases - are generated using below functions, keeping for reference
    /*
    func generateCombinations(_ orientations: [FTCoverOrientation], _ places: Int, _ currentCombination: String, _ result: inout [String]) {
        if places == 0 {
            result.append(currentCombination)
            return
        }

        // Place 'portrait'
        generateCombinations(orientations, places - 1, currentCombination + orientations[0].rawValue, &result)

        if currentCombination.count < orientations.count {
            // Place 'landscape'
            generateCombinations(orientations, places - 1, currentCombination + orientations[1].rawValue, &result)
        }
    }

    func generateLetterCombinations(_ orientations: [FTCoverOrientation], _ places: Int) -> [String] {
        var result: [String] = []
        generateCombinations(orientations, places, "", &result)
        return result
    }
    */
}

private extension UIImage {
    func isPortraitDimension() -> Bool {
        return self.size.height > self.size.width
    }
}
