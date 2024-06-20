//
//  FTRefreshPageView.swift
//  newPage
//
//  Created by Mahesh on 14/10/22.
//

import UIKit

protocol FTRefreshPageDelegate: NSObjectProtocol {
    func didTappedItem(item: FTNewPageCreationOption, with sender: UIButton)
}

class FTRefreshPageView: UIView {
    @IBOutlet private weak var contentView: UIView?
    @IBOutlet private weak var containerView: UIView?
    @IBOutlet weak var importView: UIView!
    @IBOutlet weak var changeTemplateView: UIView!
    @IBOutlet private weak var stackView: UIStackView?
    @IBOutlet weak var configuredStackView: UIStackView!
    @IBOutlet weak var mainStackView: UIStackView!
    @IBOutlet private weak var addNewLbl: UILabel?
    
    @IBOutlet weak var centerYConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    weak var delegate: FTRefreshPageDelegate?
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    
    private func commonInit() {
        let bundle = Bundle(for: type(of: self))
        bundle.loadNibNamed("FTRefreshPageView", owner: self, options: nil)
        addSubview(contentView!)
        contentView?.frame = bounds
        contentView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        applyBordersForView()
        if !FTFeatureConfigHelper.shared.isFeatureEnabled(.ImportDocument) {
            importView.isHidden = true
        }
        if !FTFeatureConfigHelper.shared.isFeatureEnabled(.ImportDocument) {
            mainStackView.isHidden = true
            configuredStackView.isHidden = false
        } else {
            mainStackView.isHidden = false
            configuredStackView.isHidden = true
        }
    }
    
    func swapPositions() {
        if let containerView, let stackView {
            mainStackView.removeArrangedSubview(containerView)
            mainStackView.removeArrangedSubview(stackView)
            mainStackView.insertArrangedSubview(stackView, at: 0)
            mainStackView.insertArrangedSubview(containerView, at: 1)
        }
    }
    
    func configureView(position: FTRefreshPosition) {
        if position == .left || position == .right {
            configuredStackView.axis = .vertical
        } else {
            configuredStackView.axis = .horizontal
        }
    }
    
    func activateBottomConstraint(_ value: Bool) {
        centerYConstraint.isActive = !value
        bottomConstraint.isActive = value
    }
    
    private func applyBordersForView() {
        stackView?.arrangedSubviews.forEach({ vw in
            vw.layer.cornerRadius = 16.0
            vw.layer.borderWidth = 1
            vw.layer.borderColor = UIColor.appColor(.accentBorder).cgColor
        })
    }
    
    @IBAction func tappedOnTemplate(_ sender: UIButton) {
        self.delegate?.didTappedItem(item: .templatePage, with: sender)
    }
    
    @IBAction func tappedOnPageOptions(_ sender: UIButton) {
        self.delegate?.didTappedItem(item: .pageOptions, with: sender)
    }
    
    @IBAction func tappedOnImportFiles(_ sender: UIButton) {
        self.delegate?.didTappedItem(item: .importPhotoPage, with: sender)
    }
    
    @IBAction func tappedOnNewPage(_ sender: UIButton) {
        self.delegate?.didTappedItem(item: .normalPage, with : sender)
    }
    
}
