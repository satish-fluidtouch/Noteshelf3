//
//  FTSmartProgressView.swift
//  Noteshelf
//
//  Created by Amar on 25/11/16.
//
//

import Foundation
import FTCommon

class FTSmartProgressView : NSObject
{
    fileprivate var progress : Progress!;
    fileprivate var loadingIndicatorViewController : FTLoadingIndicatorViewController?;
    fileprivate var observerAdded = false;
    static var isProgressIndicatorShown: Bool = false
    
    init(progress : Progress)
    {
        super.init();
        self.progress = progress;
    }
    
    deinit {
        self.removeObservers();
    }
    
    func showProgressIndicator(_ message : String,onViewController : UIViewController)
    {
        if !FTSmartProgressView.isProgressIndicatorShown {
            self.loadingIndicatorViewController =  FTLoadingIndicatorViewController.show(onMode: .progressView,
                                                                                         from: onViewController,
                                                                                         withText: message);
            FTSmartProgressView.isProgressIndicatorShown = true
            if(self.progress.isCancellable) {
                weak var weakSelf = self;
                self.loadingIndicatorViewController?.setCancelCallback({ (_) in
                    weakSelf?.progress.cancel();
                });
            }
            self.addObservers();
        }
    }
    
    private func hideProgressIndicator(withCompletion completionHandler: @escaping (() -> Void))
    {
        if FTSmartProgressView.isProgressIndicatorShown {
            if(!Thread.current.isMainThread) {
                runInMainThread {
                    self.hideProgressIndicator(withCompletion: completionHandler);
                    FTSmartProgressView.isProgressIndicatorShown = false
                }
                return;
            }
            self.removeObservers();
            self.loadingIndicatorViewController?.hide {
                completionHandler();
            };
        }
    }
    
    func hideProgressIndicator()
    {
        if FTSmartProgressView.isProgressIndicatorShown {
            self.loadingIndicatorViewController?.hide();
            FTSmartProgressView.isProgressIndicatorShown = false
            self.removeObservers();
        }
    }

    func hideProgressWithSuccessIndicator()
    {
        if FTSmartProgressView.isProgressIndicatorShown {
            self.loadingIndicatorViewController?.hideWithSuccessIndication();
            FTSmartProgressView.isProgressIndicatorShown = false
            self.removeObservers();
        }
    }

    func updateProgress(_ progress : Progress)
    {
        self.removeObservers();
        self.progress = progress;
        self.addObservers();
        self.updateUI(progress: progress);
    }
    
    fileprivate func addObservers()
    {
        self.progress.addObserver(self, forKeyPath: "totalUnitCount", options: [NSKeyValueObservingOptions.new,NSKeyValueObservingOptions.old], context: nil);
        self.progress.addObserver(self, forKeyPath: "completedUnitCount", options: [NSKeyValueObservingOptions.new,NSKeyValueObservingOptions.old], context: nil);
        self.progress.addObserver(self, forKeyPath: "localizedDescription", options: [NSKeyValueObservingOptions.new], context: nil);
        observerAdded = true;
    }
    
    fileprivate func removeObservers()
    {
        if(observerAdded)
        {
            self.progress.removeObserver(self, forKeyPath: "totalUnitCount");
            self.progress.removeObserver(self, forKeyPath: "completedUnitCount");
            self.progress.removeObserver(self, forKeyPath: "localizedDescription");
            observerAdded = false;
        }
    }
    
    internal override func observeValue(forKeyPath keyPath: String?,
                                        of object: Any?,
                                        change: [NSKeyValueChangeKey : Any]?,
                                        context: UnsafeMutableRawPointer?)
    {
        if (keyPath == "totalUnitCount"
            || keyPath == "completedUnitCount"
            || keyPath == "localizedDescription"
            )
        {
            if let progress = object as? Progress {
                if(Thread.isMainThread) {
                    self.updateUI(progress: progress);
                }
                else {
                    DispatchQueue.main.async(execute: {
                        self.updateUI(progress: progress);
                    });
                }
            }
        }
    }
    
    private func updateUI(progress : Progress)
    {
        if self.loadingIndicatorViewController?.isViewLoaded ?? false {
            self.loadingIndicatorViewController?.progress = CGFloat(progress.fractionCompleted);
            self.loadingIndicatorViewController?.setText(progress.localizedDescription);
        }
    }
}
