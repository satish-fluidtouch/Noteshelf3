//
//  FTColorEyeDropper.swift
//  FTColorPicker
//
//  Created by Amar Udupa on 12/07/23.
//

import UIKit

@objc protocol FTColorEyeDropperPickerDelegate: NSObjectProtocol {
    @objc optional func colorPicker(picker: FTColorEyeDropperPickerController,didUpdateColor color:UIColor);
    @objc optional func colorPicker(picker: FTColorEyeDropperPickerController,didPickColor color:UIColor);
}

class FTColorEyeDropperPickerController: UIViewController {
    weak var delegate: FTColorEyeDropperPickerDelegate?;
    
    static func showEyeDropperOn(_ presentingCOntorller: UIViewController,delegate: FTColorEyeDropperPickerDelegate? = nil) {
        let dropper = FTColorEyeDropperPickerController();
        dropper.delegate = delegate;
        dropper.modalPresentationStyle = .overCurrentContext;
        presentingCOntorller.present(dropper, animated: false) {
            dropper.showDropperAt(dropper.view.center);
        };
    }
    
    private lazy var magnifyerView: FTColorEyeDropperView = {
        let dropperView = FTColorEyeDropperView(offset: .zero
                                , radius: 50
                                , scale: 2
                                , borderColor: .lightGray
                                , borderWidth: 2
                                , showsCrosshair: true
                                , crosshairColor: .blue
                                , crosshairWidth: 0.5);
        dropperView.delegate = self;
        return dropperView;
    }();
    
    
    override func viewDidLoad() {
        super.viewDidLoad();
        self.view.backgroundColor = .clear;
    }

    public func showDropperAt(_ point: CGPoint) {
        if(self.magnifyerView.superview == nil) {
            self.view.addSubview(self.magnifyerView);
            self.magnifyerView.magnifiedView = self.presentingViewController?.view
        }
        self.magnifyerView.magnify(at: point)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: view) else {
            return
        }
        self.showDropperAt(location);
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: view) else {
            return
        }
        self.showDropperAt(location);
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        removeEyeDropperView();
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        removeEyeDropperView();
    }
    
    private func removeEyeDropperView() {
        self.delegate?.colorPicker?(picker: self, didPickColor: self.magnifyerView.currentColor);
        self.dismiss(animated: false);
    }
}

extension FTColorEyeDropperPickerController: FTColorEyeDropperDelegate {
    func colorDropper(_ dropperView: FTColorEyeDropperView, didPickColor color: UIColor) {
        self.delegate?.colorPicker?(picker: self, didUpdateColor: color)
    }
}
