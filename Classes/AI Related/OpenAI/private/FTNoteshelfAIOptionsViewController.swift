//
//  FTNoteshelfAIOptionsViewController.swift
//  Sample AI
//
//  Created by Amar Udupa on 28/07/23.
//

import UIKit

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
            frame.size.width = 24;
            frame.size.height = 24;
            imgView.frame = frame;
        }
    }
}

class FTNoteshelfAIOptionsViewController: UIViewController {
    weak var delegate: FTNoteshelfAIOptionsViewControllerDelegate?;
    @IBOutlet private weak var aiTableView: UITableView?;
    var contentString: String?;
        
    override func viewDidLoad() {
        super.viewDidLoad()
        aiTableView?.register(FTAIOptionTableViewCell.self, forCellReuseIdentifier: FTAIOptionTableViewCell.cellIdentifier);
    }
}

extension FTNoteshelfAIOptionsViewController: UITableViewDataSource,UITableViewDelegate {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = FTAIOptionTableViewCell.cellIdentifier;
        let tableCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        return tableCell;
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let optionCell = cell as? FTAIOptionTableViewCell {
            let aitoption = FTOpenAICommandType.supportedCommands̉[indexPath.row];
            optionCell.imageView?.image = aitoption.image;
            let displayText = contentString?.openAIDisplayString ?? "";
            let attr = NSMutableAttributedString(string: aitoption.title(content: displayText));
            if !displayText.isEmpty {
                let subString = NSAttributedString(string: " \"\(displayText)\"",attributes: [.foregroundColor:UIColor.gray]);
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
