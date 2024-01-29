//
//  UIScrollView_Extension.swift
//  Noteshelf
//
//  Created by Amar on 19/05/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

extension UIScrollView {
    static let between_Page_offset : CGFloat = 10;
    
    @objc var visibleRect: CGRect {
        let origin = self.contentOffset;
        let scrollViewSize = self.frame.size;
        let contentViewSize = self.contentSize;
        
        var visibleRect = CGRect.zero;
        visibleRect.origin = origin;
        visibleRect.size.width = min(contentViewSize.width, scrollViewSize.width);
        visibleRect.size.height = min(contentViewSize.height, scrollViewSize.height);
        return visibleRect;
    }
    
    @objc var isScrolling: Bool {
        return self.isDragging || self.isDecelerating;
    }
    
    @objc var zoomFactor: CGFloat {
        get {
            return self.zoomScale;
        }
        set {
            self.zoomScale =  newValue;
        }
    }
    
    @objc func zoomTo(_ zoomPoint: CGPoint,scale inScale:CGFloat,animate:Bool) {
        //Ensure scale is clamped to the scroll view's allowed zooming range
        var scale = inScale;
        scale = min(scale, self.maximumZoomScale);
        scale = max(scale, self.minimumZoomScale);
        
        let zoomRect = self.zoomRect(for: scale, center: zoomPoint);
        if animate {
            UIView.animate(withDuration: 0.4,
                           delay: 0.0,
                           usingSpringWithDamping: 1.0,
                           initialSpringVelocity: 0.6,
                           options: [.curveLinear],
                           animations: {
                self.zoom(to: zoomRect, animated: false)
                self.scrollRectToVisible(CGRect.scale(zoomRect, scale), animated: false);
            }, completion: { _ in
                let zoomView = self.delegate?.viewForZooming?(in: self);
                self.delegate?.scrollViewDidEndZooming?(self, with: zoomView, atScale: scale);
            })
        }
        else {
            self.zoom(to: zoomRect, animated: animate);
            let zoomView = self.delegate?.viewForZooming?(in: self);
            self.delegate?.scrollViewDidEndZooming?(self, with: zoomView, atScale: scale);
        }
    }
    
    @objc func centerContentHolderView(_ inView: UIView?) {
        guard let contentView = inView else {
            return;
        }
        let boundsSize = self.bounds.size;
        var frameToCenter = contentView.frame;

        // Center horizontally.
        if frameToCenter.size.width < boundsSize.width {
            frameToCenter.origin.x = ((boundsSize.width - frameToCenter.width)*0.5).rounded();
        }
        else {
            frameToCenter.origin.x = 0;
        }

        // Center vertically.
        if (frameToCenter.size.height < boundsSize.height) {
            frameToCenter.origin.y = ((boundsSize.height - frameToCenter.height)*0.5).rounded();
        }
        else {
            frameToCenter.origin.y = 0;
        }
        contentView.frame = frameToCenter;
    }
    
    func zoomRect(for scale:CGFloat,center:CGPoint) -> CGRect {
        //`zoomToRect` works on the assumption that the input frame is in relation
        //to the content view when zoomScale is 1.0
        //Work out in the current zoomScale, where on the contentView we are zooming
        var centeredZoomPoint = center;
        //Figure out what zoom scale we need to get back to default 1.0f
        let zoomFactor = 1.0 / self.zoomScale;
        //By multiplying by the zoom factor, we get where we're zooming to, at scale 1.0f;
        centeredZoomPoint.x *= zoomFactor;
        centeredZoomPoint.y *= zoomFactor;

        var zoomRect = CGRect.zero;
        
        // The zoom rect is in the content view's coordinates.
        // At a zoom scale of 1.0, it would be the size of the
        // imageScrollView's bounds.
        // As the zoom scale decreases, so more content is visible,
        // the size of the rect grows.
        zoomRect.size.height = self.frame.height / scale;
        zoomRect.size.width  = self.frame.width  / scale;
        
        // choose an origin so as to get the right center.
        zoomRect.origin.x = centeredZoomPoint.x - (zoomRect.size.width  / 2.0);
        zoomRect.origin.y = centeredZoomPoint.y - (zoomRect.size.height / 2.0);
        
        if zoomRect.maxY > self.contentSize.height {
            zoomRect.origin.y = self.contentSize.height - zoomRect.size.height;
        }
        if zoomRect.maxX > self.contentSize.width {
            zoomRect.origin.x = self.contentSize.width - zoomRect.size.width;
        }
        return zoomRect;
    }
    
    @objc var maximumSupportedZoomScale: CGFloat {
        return UIScrollView.nsMaximumZoomScale;
    }
    
    @objc var miniumSupportedZoomScale: CGFloat {
        return UIScrollView.nsMinimumZoomScale;
    }
    
    @objc static let nsMinimumZoomScale: CGFloat = 1;
    @objc static let nsMaximumZoomScale: CGFloat = 6;
}
