//
//  FTBlurSelectionController.swift
//  Noteshelf
//
//  Created by Narayana on 11/02/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import SwiftUI

protocol FTBlurSelectionDelegate: AnyObject {
    func didSelectBlurStyle(string: String)
}

let blurOptions = ["systemUltraThinMaterial","systemThinMaterial","regular", "systemThickMaterial", "systemThickMaterialLight", "systemMaterial"]

enum FTBlurStyle: String {
    case systemUltraThinMaterial
    case systemThinMaterial
    case regular
    case systemThickMaterial
    case systemThickMaterialLight
    case systemMaterial

    func blurStyle() -> UIBlurEffect.Style {
        var blurStyle: UIBlurEffect.Style = .regular

        switch self {
        case .systemUltraThinMaterial:
            blurStyle = .systemUltraThinMaterial
        case .systemThinMaterial:
            blurStyle = .systemThinMaterial
        case .regular:
            blurStyle = .regular
        case .systemThickMaterial:
            blurStyle = .systemThickMaterial
        case .systemThickMaterialLight:
            blurStyle = .systemThickMaterialLight
        case .systemMaterial:
            blurStyle = .systemMaterial
        }
        return blurStyle
    }

    func swiftUIMaterial() -> Material {
        var materialStyle: Material = .regularMaterial
        switch self {
        case .regular:
            materialStyle = .regularMaterial
        case .systemThinMaterial:
            materialStyle = .thinMaterial
        case .systemThickMaterial:
            materialStyle = .thickMaterial
        case .systemUltraThinMaterial:
            materialStyle = .ultraThinMaterial
        case .systemMaterial:
            materialStyle = .bar
        case .systemThickMaterialLight:
            materialStyle = .ultraThickMaterial
        }
        return materialStyle
    }
}


class FTBlurSelectionController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    let blurOptions = ["systemUltraThinMaterial","systemThinMaterial","regular", "systemThickMaterial", "systemThickMaterialLight", "systemMaterial"]

    weak var delegate: FTBlurSelectionDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.blurOptions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "Cell")
        cell.textLabel?.text = self.blurOptions[indexPath.row]
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedOne = self.blurOptions[indexPath.row]
        self.delegate?.didSelectBlurStyle(string: selectedOne)
        self.navigationController?.popViewController(animated: true)
    }
}
