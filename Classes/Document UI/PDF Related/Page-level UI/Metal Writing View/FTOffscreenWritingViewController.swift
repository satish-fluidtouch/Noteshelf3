//
//  FTOffscreenWritingViewController.swift
//  Noteshelf
//
//  Created by Amar on 21/12/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

class FTOffscreenWritingViewController: UIViewController {

    fileprivate let extraTileCount : Int = 0;
    fileprivate var currentTileRenderRequest: FTOffscreenTileRequest?;
    
    weak var delegate : FTContentDelegate?;
    
    fileprivate var tileRenderOperations = [FTOffscreenTileRequest]();
    class func viewController(delegate : FTContentDelegate) -> FTOffscreenWritingViewController
    {
        let vc = FTOffscreenWritingViewController.init(nibName: "FTOffscreenDrawingViewController", bundle: nil);
        vc.delegate = delegate;
        return vc;
    }
    
    private var _offscreenRenderer : FTOffScreenRenderer?
    fileprivate var offscreenRenderer : FTOffScreenRenderer? {
        if(nil == _offscreenRenderer) {
            _offscreenRenderer =  FTRendererProvider.shared.dequeOffscreenRenderer()
        }
        return _offscreenRenderer;
    };
    
    deinit {
        FTRendererProvider.shared.enqueOffscreenRenderer(_offscreenRenderer)
    }
    
    private var tiledView : FTTiledView {
        return self.view as! FTTiledView;
    }
    
    override func loadView() {
        let view = FTTiledView.init(frame: UIScreen.main.bounds);
        view.tileProvider = FTImageTileProvider();
        view.tileSize = CGSize.init(width: FTRenderConstants.TILE_SIZE, height: FTRenderConstants.TILE_SIZE);
        view.isUserInteractionEnabled = false;
        view.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth,UIView.AutoresizingMask.flexibleHeight];
        self.view = view;
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.reloadTiles();
    }
    
    func reloadTiles()
    {
        self.tiledView.reloadTiles();
    }
    
    func markTilesAsDirty(inRect rect : CGRect) {
        let tilesArray = self.tiledView.tiles(in: rect, extraTilesCount: extraTileCount)
        tilesArray.forEach({ (tile) in
            tile.isDirty = true;
        });
    }
    
    func releaseTilesNot(in rect : CGRect,extraTilesCount : Int)
    {
        self.tiledView.releaseTilesNot(in: rect, extraTilesCount: extraTilesCount);
    }
    
    func removeTilesMarkedAsShouldRemove()
    {
        self.tiledView.removeTilesMarkedAsShouldRemove();
    }

    func renderTiles(inRect rect : CGRect)
    {
        guard let page = self.delegate?.pageToDisplay else { return }
        let tilesArray = self.tiledView.tiles(in: rect, extraTilesCount: extraTileCount)
        let contentScale : CGFloat = self.delegate?.contentScale ?? 1;
        
        let annotations = page.annotations()
        let texture = self.delegate?.backgroundTexture;
        let contentSize = self.delegate?.contentSize ?? self.view.frame.size;
        let bgColor = (page as? FTPageBackgroundColorProtocol)?.pageBackgroundColor ?? .white

        for eachTile in tilesArray where eachTile.isDirty {
            let tileRequest = FTOffscreenTileRequest(with: self.view.window?.hash);
            tileRequest.backgroundColor = bgColor;
            tileRequest.label = "RELOAD_TILE"
            if FTRenderConstants.USE_BG_TILING {
                tileRequest.backgroundTextureTileContent = self.delegate?.backgroundTextureTileContent;
            } else {
                tileRequest.backgroundTexture = texture;
            }

            tileRequest.annotations = annotations;
            tileRequest.scale = contentScale;
            tileRequest.contentSize = contentSize;
            tileRequest.areaToRefresh = eachTile.frame;
            tileRequest.tile = eachTile;
            tileRequest.completionBlock = { [weak eachTile] returnedImage in
                if let image = returnedImage {
                    eachTile?.imageView.image = image;
                }
            }
            eachTile.isDirty = false;
            tileRenderOperations.append(tileRequest);
        }
        self.performTileRender();
    }
}

private extension FTOffscreenWritingViewController
{
    func performTileRender()
    {
        if(currentTileRenderRequest != nil) {
            return;
        }
        if !self.tileRenderOperations.isEmpty {
           let currentRender = self.tileRenderOperations.removeFirst();
            self.currentTileRenderRequest = currentRender;
            let completion = currentRender.completionBlock;
            currentRender.completionBlock = { [weak self] (image) in
                runInMainThread {
                    self?.currentTileRenderRequest = nil;
                    completion?(image);
                    self?.performTileRender();
                }
            }
            if (nil != currentRender.tile) {
                self.offscreenRenderer?.imageFor(request:currentRender);
            }
            else {
                currentRender.completionBlock?(nil);
            }
        }
        else {
            FTRendererProvider.shared.enqueOffscreenRenderer(_offscreenRenderer)            
            _offscreenRenderer = nil
        }
    }
}

private class FTOffscreenTileRequest : FTOffScreenTileImageRequest
{
    weak var tile : FTTile?;
}
