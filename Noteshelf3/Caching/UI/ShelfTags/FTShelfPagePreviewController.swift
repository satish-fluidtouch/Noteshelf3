//
//  FTShelpPagePreviewController.swift
//  Noteshelf3
//
//  Created by Siva on 15/11/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

struct FTPreviewDefaultSize {
   static let portrait = CGSize(width: 664, height: 830);
   static let landscape = CGSize(width: 686, height: 375);

   static func previewSize(for image: UIImage) -> CGSize {
       return image.size
       var referenceRect = CGRect.zero;
       if(image.size.width > image.size.height) {
           referenceRect.size = FTPreviewDefaultSize.landscape;
       }
       else {
           referenceRect.size = FTPreviewDefaultSize.portrait;
       }
       let aspectRect = AVMakeRect(aspectRatio: image.size, insideRect: referenceRect);
       return aspectRect.size;
   }
}

class FTShelfPagePreviewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView?
    var previewImage: UIImage?;

    override func viewDidLoad() {
        super.viewDidLoad()
        self.imageView?.image = self.previewImage;
        self.imageView?.layer.cornerRadius = 10
        // Do any additional setup after loading the view.
    }

}
