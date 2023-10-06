//
//  FTNoteshelfAIOptionsViewController.swift
//  Sample AI
//
//  Created by Amar Udupa on 28/07/23.
//

import UIKit
import Combine

protocol FTNoteshelfAIOptionsViewControllerDelegate: NSObjectProtocol {
    func aiOptionsController(_ controller: FTNoteshelfAIOptionsViewController, didTapOnOption option:FTOpenAICommandType);
}

private class FTAIOptionTableViewCell: UITableViewCell {
    static let cellIdentifier = "FTAIOptionTableViewCell";
    override func layoutSubviews() {
        super.layoutSubviews();
        if let imgView = self.imageView {
            imgView.contentMode = .scaleAspectFit;
            var frame = imgView.frame;
            frame.size.width = 20;
            frame.size.height = 20;
            imgView.frame = frame;
        }
    }
}

class FTNoteshelfAIOptionsViewController: UIViewController {
    weak var delegate: FTNoteshelfAIOptionsViewControllerDelegate?;
    @IBOutlet private weak var aiTableView: UITableView?;
    @IBOutlet private weak var creditsContainerView: UIView?;
    @IBOutlet private weak var creditsContainerViewHeightConstraint: NSLayoutConstraint?;
    
    private weak var creditsController: UIViewController?;
    private var premiumCancellableEvent: AnyCancellable?;

    var contentString: String?;
        
    override func viewDidLoad() {
        super.viewDidLoad()
        self.aiTableView?.layer.cornerRadius = 10.0
        self.aiTableView?.separatorInset = .zero;
        aiTableView?.register(FTAIOptionTableViewCell.self, forCellReuseIdentifier: FTAIOptionTableViewCell.cellIdentifier);
        self.creditsContainerView?.layer.cornerRadius = 12;
        
        if !FTIAPManager.shared.premiumUser.isPremiumUser {
            premiumCancellableEvent = FTIAPManager.shared.premiumUser.$isPremiumUser.sink { [weak self] isPremium in
                self?.addCredtisFooter();
            }
        }
        else {
            self.addCredtisFooter();
        }
    }
    
    deinit {
        premiumCancellableEvent?.cancel();
        premiumCancellableEvent = nil;
    }
}

extension FTNoteshelfAIOptionsViewController: UITableViewDataSource,UITableViewDelegate {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = FTAIOptionTableViewCell.cellIdentifier;
        let tableCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        tableCell.backgroundColor = UIColor.appColor(.cellBackgroundColor);
        return tableCell;
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let optionCell = cell as? FTAIOptionTableViewCell {
            let aitoption = FTOpenAICommandType.supportedCommands̉[indexPath.row];
            optionCell.imageView?.image = aitoption.image;
            let displayText = contentString?.openAIDisplayString ?? "";
            let attr = NSMutableAttributedString(string: aitoption.title(content: displayText));
            if !displayText.isEmpty {
                let subString = NSAttributedString(string: " \"\(displayText)\"",attributes: [
                    .foregroundColor:UIColor.gray
                    ,.font : UIFont.systemFont(ofSize: 17)
                ]);
                attr.append(subString);
            }
            optionCell.textLabel?.attributedText = attr;
        }
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return FTOpenAICommandType.supportedCommands̉.count;
    }
     
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let aitoption = FTOpenAICommandType.supportedCommands̉[indexPath.row];
        self.delegate?.aiOptionsController(self, didTapOnOption: aitoption);
    }
}

private extension FTNoteshelfAIOptionsViewController {
    func addCredtisFooter() {
        self.creditsContainerViewHeightConstraint?.constant = FTIAPManager.shared.premiumUser.isPremiumUser ? 74 : 142;
        self.creditsController?.view.removeFromSuperview();
        self.creditsController?.removeFromParent();
        
        guard let creditsView = self.creditsContainerView else {
            return;
        }
        var controller: UIViewController;
        if FTIAPManager.shared.premiumUser.isPremiumUser {
            controller = UIStoryboard.instantiateAIViewController(withIdentifier: "FTNoteshelfAIPremiumUserCreditsViewController");
        }
        else {
            controller = UIStoryboard.instantiateAIViewController(withIdentifier: "FTNoteshelfAIFreeUserCreditsViewController");
        }
        self.addChild(controller);
        self.creditsController = controller;
        controller.view.frame = creditsView.bounds;
        controller.view.addFullConstraints(creditsView);
    }
}
