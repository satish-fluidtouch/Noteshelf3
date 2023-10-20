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
    @IBOutlet private weak var tableViewHeightConstraint: NSLayoutConstraint?;

    private var premiumCancellableEvent: AnyCancellable?;

    var content: FTPageContent = FTPageContent();
        
    private var supportedCommands = FTOpenAICommandType.supportedCommands̉;
    
    var isAllTokensConsumend = false;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.aiTableView?.layer.cornerRadius = 10.0
        self.aiTableView?.separatorInset = .zero;
        aiTableView?.register(FTAIOptionTableViewCell.self, forCellReuseIdentifier: FTAIOptionTableViewCell.cellIdentifier);
        self.loadSupportedCommands();
    }
    
    private func loadSupportedCommands() {
        let strSize = self.content.nonPDFContent.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).components(separatedBy: CharacterSet.newlines);
        if strSize.count < 5 {
            self.supportedCommands.removeAll { eachItem in
                return eachItem == .cleanUp;
            }
        }
        self.aiTableView?.isUserInteractionEnabled = !isAllTokensConsumend;
        self.aiTableView?.alpha = isAllTokensConsumend ? 0.6 : 1;
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews();
        if let constraint = self.tableViewHeightConstraint {
            let maxHeight: CGFloat = CGFloat(self.supportedCommands.count) * 44;
            let heightToApply = min(maxHeight,self.view.frame.height);
            if constraint.constant != heightToApply {
                constraint.constant = heightToApply;
           }
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
            let aitoption = self.supportedCommands[indexPath.row];
            optionCell.imageView?.image = aitoption.image;
            let displayText = self.content.content.openAIDisplayString;
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
        return self.supportedCommands.count;
    }
     
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let aitoption = self.supportedCommands[indexPath.row];
        self.delegate?.aiOptionsController(self, didTapOnOption: aitoption);
    }
}
