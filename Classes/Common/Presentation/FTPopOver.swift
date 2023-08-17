//
//  FTPopOver.swift
//  DailyNotes
//
//  Created by Siva Kumar Reddy on 07/08/20.
//  Copyright © 2020 Siva Kumar Reddy. All rights reserved.
//

import Foundation
import UIKit

public typealias ShowPopoverCompletion = () -> Void
public typealias DismissPopoverCompletion = () -> Void

private class KUIPopOverUsableDismissHandlerWrapper {
    typealias DismissHandler = ((Bool, DismissPopoverCompletion?) -> Void)
    var closure: DismissHandler?
    
    init(_ closure: DismissHandler?) {
        self.closure = closure
    }
}

fileprivate extension UIView {
    
    struct AssociatedKeys {
        static var onDismissHandler = "onDismissHandler"
    }
    
    var onDismissHandler: KUIPopOverUsableDismissHandlerWrapper.DismissHandler? {
        get { return (objc_getAssociatedObject(self, &AssociatedKeys.onDismissHandler) as? KUIPopOverUsableDismissHandlerWrapper)?.closure }
        set { objc_setAssociatedObject(self, &AssociatedKeys.onDismissHandler, KUIPopOverUsableDismissHandlerWrapper(newValue), .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
}

extension FTPopOver where Self: UIView {
    
    public var contentView: UIView {
        return self
    }
    
    public var contentSize: CGSize {
        return frame.size
    }
    
    public func showPopover(sourceView: UIView, sourceRect: CGRect? = nil, shouldDismissOnTap: Bool = true, completion: ShowPopoverCompletion? = nil) {
        let usableViewController = KUIPopOverUsableViewController(popOverUsable: self)
        usableViewController.showPopover(sourceView: sourceView,
                                         sourceRect: sourceRect,
                                         shouldDismissOnTap: shouldDismissOnTap,
                                         completion: completion)
        onDismissHandler = { [weak self] (animated, completion) in
            self?.dismiss(usableViewController: usableViewController, animated: animated, completion: completion)
        }
    }
    
    public func dismissPopover(animated: Bool, completion: DismissPopoverCompletion? = nil) {
        onDismissHandler?(animated, completion)
    }
    
    // MARK: - Private
    private func dismiss(usableViewController: KUIPopOverUsableViewController, animated: Bool, completion: DismissPopoverCompletion? = nil) {
        if let completion = completion {
            usableViewController.dismiss(animated: animated, completion: { [weak self] in
                self?.onDismissHandler = nil
                completion()
            })
        } else {
            usableViewController.dismiss(animated: animated, completion: nil)
            onDismissHandler = nil
        }
    }
}

extension FTPopOver where Self: UIViewController {
   
    public var contentView: UIView {
        return view
    }
    
    private var rootViewController: UIViewController? {
        let topVC = UIApplication.shared.keyWindow?.rootViewController?.topPresentedViewController
        if topVC == nil {
            return UIApplication.shared.getKeyWindowScene()?.windows.first?.rootViewController
        }
        return topVC
    }
    
    private func setup() {
        modalPresentationStyle = .popover
        preferredContentSize = contentSize
        popoverPresentationController?.delegate = KUIPopOverDelegation.shared
        popoverPresentationController?.backgroundColor = .clear  //popOverBackgroundColor
        popoverPresentationController?.permittedArrowDirections = arrowDirection
        if showArrowDirection == false {
            popoverPresentationController?.popoverBackgroundViewClass = PopoverBackgroundView.self
        }
        popoverPresentationController?.dimmingView?.backgroundColor = .clear
        popoverPresentationController?.shadowView?.backgroundColor = .clear
        popoverPresentationController?.shadowView?.isHidden = false
    }
    
    public func setupPopover(sourceView: UIView, sourceRect: CGRect? = nil) {
        setup()
        popoverPresentationController?.sourceView = sourceView
        popoverPresentationController?.sourceRect = sourceRect ?? sourceView.bounds
    }
    
    public func setupPopover(barButtonItem: UIBarButtonItem) {
        setup()
        popoverPresentationController?.barButtonItem = barButtonItem
    }
    
    public func showPopover(sourceView: UIView, sourceRect: CGRect? = nil, shouldDismissOnTap: Bool = true, completion: ShowPopoverCompletion? = nil) {
        setupPopover(sourceView: sourceView, sourceRect: sourceRect)
        KUIPopOverDelegation.shared.shouldDismissOnOutsideTap = shouldDismissOnTap
        KUIPopOverDelegation.shared.presentedViewController = rootViewController
        rootViewController?.present(self, animated: true, completion: completion)
        
    }
    
    public func dismissPopover(animated: Bool, completion: DismissPopoverCompletion? = nil) {
        if self.isBeingPresented == false {
            dismiss(animated: animated, completion: completion)
        }
    }
}

private final class KUIPopOverUsableViewController: UIViewController, FTPopOver {
    
    var contentSize: CGSize {
        return popOverUsable.contentSize
    }
    
    var contentView: UIView {
        return view
    }
    
    var popOverBackgroundColor: UIColor? {
        return popOverUsable.popOverBackgroundColor
    }
    
    var arrowDirection: UIPopoverArrowDirection {
        return popOverUsable.arrowDirection
    }
    
    var showArrowDirection: Bool? {
        return popOverUsable.showArrowDirection
    }
    
    private var popOverUsable: FTPopOver!
    
    convenience init(popOverUsable: FTPopOver) {
        self.init()
        self.popOverUsable = popOverUsable
        preferredContentSize = popOverUsable.contentSize
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(popOverUsable.contentView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        popOverUsable.contentView.frame = view.bounds
    }
    deinit {
        print("Dismissed")
    }
}

private final class KUIPopOverDelegation: NSObject, UIPopoverPresentationControllerDelegate {
    
    static let shared = KUIPopOverDelegation()
    var shouldDismissOnOutsideTap: Bool = false
    var presentedViewController: UIViewController?
    
    // MARK: UIPopoverPresentationControllerDelegate
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        return shouldDismissOnOutsideTap
    }
    func prepareForPopoverPresentation(_ popoverPresentationController: UIPopoverPresentationController) {
        //        popoverPresentationController.containerView?.backgroundColor = UIColor.blue
        
    }
    func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        
    }
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        print("Dismiss popover")
    }
}

extension UIViewController {
    
    var topPresentedViewController: UIViewController {
        return presentedViewController?.topPresentedViewController ?? self
    }
    
}

public protocol FTPopOver {
    
    var contentSize: CGSize { get }
    var contentView: UIView { get }
    var popOverBackgroundColor: UIColor? { get }
    var arrowDirection: UIPopoverArrowDirection { get }
    var showArrowDirection: Bool? { get }
    
}

extension FTPopOver {
    
    public var popOverBackgroundColor: UIColor? {
        return .clear
    }
    
    public var arrowDirection: UIPopoverArrowDirection {
        return .any
    }
    
    public var showArrowDirection: Bool? {
        return false
    }
}

public extension UIPopoverArrowDirection {
    static var none: UIPopoverArrowDirection {
        return UIPopoverArrowDirection(rawValue: 0)
    }
}

final class PopoverBackgroundView: UIPopoverBackgroundView {
    
    private var offset = CGFloat(0)
    private var arrow = UIPopoverArrowDirection.any
    private var backgroundImageView: UIImageView!
    
    override var arrowDirection: UIPopoverArrowDirection {
        get { return arrow }
        set { arrow = newValue }
    }
    
    override var arrowOffset: CGFloat {
        get { return offset }
        set { offset = newValue }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUpView()
    }
    
    override static func contentViewInsets() -> UIEdgeInsets {
        return .zero
    }
    
    override static func arrowHeight() -> CGFloat {
        return 8
    }
    
    override class var wantsDefaultContentAppearance: Bool {
        return false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var backgroundImageViewFrame = bounds
        
        switch arrowDirection {
        case .down:
            backgroundImageViewFrame.size.height -= PopoverBackgroundView.arrowHeight()
        default:
            backgroundImageViewFrame.size.width -= PopoverBackgroundView.arrowHeight()
            backgroundImageViewFrame.origin.x += PopoverBackgroundView.arrowHeight()
        }
        
        backgroundImageView.frame = backgroundImageViewFrame
        self.backgroundColor = UIColor.clear
        self.removeShadow()
    }
    
    // MARK: - Private
    
    private func setUpView() {
        backgroundImageView = UIImageView(image: UIImage(named: "Bubble"))
        addSubview(backgroundImageView)
//        // Disable default shadow
//        layer.masksToBounds = true
//        layer.shadowColor = UIColor.clear.cgColor
//        self.removeShadow()
    }
}
extension UIPopoverPresentationController {
    
    var dimmingView: UIView? {
        return value(forKey: "_dimmingView") as? UIView
    }
    var shadowView: UIView? {
        return value(forKey: "_shadowView") as? UIView
    }
}

