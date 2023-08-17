//
//  FTIndexingPageViewController.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 15/03/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTIndexingPageViewController: UIViewController {
    @IBOutlet weak var indexingContentView: UIView!
    @IBOutlet weak var labelIndexing: FTStyledLabel?
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.indexingContentView.layer.cornerRadius = self.indexingContentView.frame.height / 2.0
        self.indexingContentView.layer.shadowOpacity = 0.1;
        self.indexingContentView.layer.shadowRadius = 10;
        self.indexingContentView.layer.shadowColor = UIColor.headerColor.cgColor;
        self.indexingContentView.layer.shadowOffset = CGSize.init(width: 0, height: 4);

        // Do any additional setup after loading the view.
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    func updateIndexingText(to text: String){
        self.labelIndexing?.text = text
    }
    func startAnimating(){
        if !self.activityIndicator!.isAnimating{
            self.activityIndicator?.startAnimating()
        }
    }
    func stopAnimating(){
        if self.activityIndicator!.isAnimating{
            self.activityIndicator?.stopAnimating()
        }
    }
}
