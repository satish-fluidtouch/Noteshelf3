//
//  FTStoreTemplateContextPreview.swift
//  FTTemplatesStore
//
//  Created by Siva on 06/06/23.
//

import UIKit
import AVKit

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

class FTStoreTemplateContextPreview: UIViewController {
    @IBOutlet weak var imageView: UIImageView?
    var previewImage: UIImage?;

    override func viewDidLoad() {
        super.viewDidLoad()
        self.imageView?.image = self.previewImage;
        self.imageView?.layer.cornerRadius = 10
        // Do any additional setup after loading the view.
    }

}
