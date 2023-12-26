//
//  FTTagsDebugViewController.swift
//  Noteshelf3
//
//  Created by Akshay on 26/12/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTTagsDebugViewController: UIViewController {

    @IBOutlet private weak var plistTagsDiffLabel: UILabel!
    @IBOutlet private weak var modelTagsDiffLabel: UILabel!

    private var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()

        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true, block: { [weak self] timer in
            self?.configure()
        })
    }

    private func cachedPageTagsLocation() -> URL {
        guard NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).last != nil else {
            fatalError("Unable to find cache directory")
        }
        let cachedTagsPlistURL = FTDocumentCache.shared.cacheFolderURL.appendingPathComponent(FTCacheFiles.cacheTagsPlist)
        return cachedTagsPlistURL
    }

    private func configure() {
        do {
            let data = try Data(contentsOf: cachedPageTagsLocation())
            let decoder = PropertyListDecoder()
            let cacheTags = try decoder.decode([String: [String]].self, from: data)
            let tags = FTTagsProvider.shared.getTags()

            // Tags diff
            let justPlistTags = cacheTags.keys
            let modelTags = tags.map({ $0.tag.text })

            let modelDiff = Set(modelTags).subtracting(justPlistTags).sorted()
            let plistDiff = Set(justPlistTags).subtracting(modelTags).sorted()

            modelTagsDiffLabel.text = "\(modelDiff.count)\n" + modelDiff.joined(separator: "\n")
            plistTagsDiffLabel.text = "\(plistDiff.count)\n" + plistDiff.joined(separator: "\n")
        } catch {
            print("error", error.localizedDescription)
        }
    }
}

extension FTRootViewController {
    func setupTagsDebugView() {
        let storyboard = UIStoryboard(name: "FTDeveloperOptions", bundle: nil)
        guard let controller = storyboard.instantiateViewController(withIdentifier: "FTTagsDebugViewController") as? FTTagsDebugViewController else {
            return
        }
        self.add(controller)
        self.view.window?.addSubview(controller.view)
        controller.view.layer.cornerRadius = 8
        controller.view.layer.masksToBounds = true
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        if let windowView = self.view.window {
            NSLayoutConstraint.activate([
                windowView.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor),
                windowView.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor),
                controller.view.widthAnchor.constraint(equalToConstant: 200),
                controller.view.heightAnchor.constraint(equalToConstant: 200),
            ])
        }
    }
}
