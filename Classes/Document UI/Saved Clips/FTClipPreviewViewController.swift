//
//  FTClipPreviewViewController.swift
//  Noteshelf3
//
//  Created by Akshay on 13/03/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTClipPreviewViewController: UIViewController {
    @IBOutlet weak private var imageView: UIImageView?

    private weak var image: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.imageView?.image = image
    }
    
    func setPreviewImage(_ image: UIImage?) {
        self.image = image
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
