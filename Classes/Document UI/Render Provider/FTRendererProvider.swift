//
//  FTRendererProvider.swift
//  Noteshelf
//
//  Created by Akshay on 04/10/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

class FTRendererProvider: NSObject {
    static let shared = FTRendererProvider();

    fileprivate var onScreenEnque = FTEnqueueRenderHelper(withIntent: .onScreen,maxCount: 4);
    fileprivate var offScreenEnque = FTEnqueueRenderHelper(withIntent: .offScreen, maxCount: 10);

    private override init() {
        super.init()
    }

    func dequeOnscreenRenderer() -> FTOnScreenRenderer {
        NotificationCenter.default.post(name: UIApplication.releaseOnScreenRendererIfNeeded, object: nil)
        let renderer = onScreenEnque.dequeueRenderer() as! FTOnScreenRenderer;
        renderer.prepareForReuse()
        return renderer
    }

    func dequeOffscreenRenderer() -> FTOffScreenRenderer {
        let renderer = offScreenEnque.dequeueRenderer() as! FTOffScreenRenderer;
        renderer.prepareForReuse()
        return renderer
    }

    func enqueOnscreenRenderer(_ renderer: FTOnScreenRenderer?) {
        if let _renderer = renderer {
            _renderer.prepareForReuse()
            onScreenEnque.enqueueRenderer(_renderer)
        }
    }

    func enqueOffscreenRenderer(_ renderer: FTOffScreenRenderer?) {
        if let _renderer = renderer {
            _renderer.prepareForReuse()
            offScreenEnque.enqueueRenderer(_renderer)
        }
    }
}

//MARK:- FTEnqueueRenderHelper
private class FTEnqueueRenderHelper
{
    fileprivate let intent: FTRendererIntent;
    fileprivate let dequeueMaxItemsCount : Int;

    fileprivate var enqueuedRenderers = [FTRenderer]();
    fileprivate var dequeuedRenderers = [FTRenderer]();

    init(withIntent : FTRendererIntent,maxCount : Int) {
        intent = withIntent;
        dequeueMaxItemsCount = maxCount;
    }

    var description: String {
        return "enque: \(enqueuedRenderers.count) deque:\(dequeuedRenderers.count)"
    }

    private var shouldRelease : Bool {
        var shouldRelease = false;
        if(dequeuedRenderers.count + enqueuedRenderers.count >= dequeueMaxItemsCount) {
            shouldRelease = true;
        }
        return shouldRelease;
    }

    func enqueueRenderer(_ renderer : FTRenderer)
    {
        objc_sync_enter(self)
        let _index = enqueuedRenderers.firstIndex(where: { (object) -> Bool in
            return object.uuid == renderer.uuid;
        });

        if let index = _index {
            enqueuedRenderers.remove(at: index);
            if(!self.shouldRelease) {
                dequeuedRenderers.append(renderer);
            }
        }
        objc_sync_exit(self)
    }

    func dequeueRenderer() -> FTRenderer
    {
        let metalRenderer : FTRenderer;
        objc_sync_enter(self)
        if !dequeuedRenderers.isEmpty {
            metalRenderer = dequeuedRenderers.removeFirst();
        } else {
            if intent == .onScreen {
                metalRenderer = FTRendererFactory.createOnScreenRenderer();
            } else {
                metalRenderer = FTRendererFactory.createOffScreenRenderer();
            }
        }
        enqueuedRenderers.append(metalRenderer);
        objc_sync_exit(self)
        return metalRenderer;
    }
}
