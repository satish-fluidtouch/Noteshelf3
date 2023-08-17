//
//  FTTiledView.h
//  Noteshelf
//
//  Created by Rama Krishna on 26/4/13.
//
//

#import <UIKit/UIKit.h>
#import "FTTile.h"

#define EXTRA_STATIC_TILES 0

@class FTTile;
@protocol FTTileProvider;

@interface FTTiledView : UIView


@property (nonatomic,strong) id <FTTileProvider> tileProvider;
@property (nonatomic,assign) CGSize tileSize;
@property (strong) NSMutableArray *tilesArray;

- (void)setContent:(id)content forTileAtRow:(NSInteger)row column:(NSInteger)column;
- (nonnull NSArray<FTTile *>*)tilesInRect:(CGRect)rect extraTilesCount:(NSInteger)tilesCount;
- (nonnull NSArray<FTTile *>*)tilesInRect:(CGRect)rect extraTilesCount:(NSInteger)tilesCount generateTileIfRequired:(BOOL)generate;
- (nonnull NSArray<FTTile *>*)tilesSurroundingRect:(CGRect)rect level:(NSUInteger)level;
- (void)releaseTilesNotInRect:(CGRect)rect extraTilesCount:(NSInteger)tilesCount;

- (FTTile*)tileAtPoint:(CGPoint)point;

- (void)reloadTiles;
- (void)removeAllTiles;

-(void)removeTilesMarkedAsShouldRemove;

@end
