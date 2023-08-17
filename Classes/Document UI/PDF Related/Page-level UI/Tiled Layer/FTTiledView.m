//
//  FTTiledView.m
//  Noteshelf
//
//  Created by Rama Krishna on 26/4/13.
//
//

#import "FTTiledView.h"
#import "FTTileProviderProtocol.h"

#define REMOVE_OLD_TILES_IMMEDIATLY  1

CGFloat TILE_SIZE = 512;

@interface FTTiledView(){
    CGFloat _numberOfCols;
    CGFloat _numberOfRows;
    CGSize viewSize;
}

- (FTTile*)tileAtRow:(NSInteger)row column:(NSInteger)column;
- (NSInteger)numberOfRows;
- (NSInteger)numberOfColumns;

@end

@implementation FTTiledView

@synthesize tileProvider;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
        self.tileSize = CGSizeMake(TILE_SIZE, TILE_SIZE);
    }
    return self;
}


-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
        self.tileSize = CGSizeMake(TILE_SIZE, TILE_SIZE);
    }
    return self;
}

@synthesize tileSize;
@synthesize tilesArray;

- (id)init
{
    self = [super init];
    if (self) {
        self.tileSize = CGSizeMake(TILE_SIZE, TILE_SIZE);
        //        self.opaque = NO;
    }
    return self;
}

- (void)dealloc
{
    for (id object in self.tilesArray) {
        if (object != [NSNull null]) {
            FTTile *tile = (FTTile *)object;
            
            if (self.tileProvider) {
                [self.tileProvider releaseTile:tile];
            }
        }
    }
    
    self.tilesArray = nil;
}

-(void)setTileSize:(CGSize)inTileSize
{
    if(!CGSizeEqualToSize(tileSize, inTileSize))
    {
        tileSize = inTileSize;
    }
}

-(void)reloadTiles
{
    if (viewSize.width != self.bounds.size.width)
    {
        //get parent scrollview
        _numberOfCols = -1;
        _numberOfRows = -1;
        
        if(self.tilesArray)
        {
            [self removeAllTiles];
        }
        NSInteger numberOfROws = [self numberOfRows];
        NSInteger numberOfColums = [self numberOfColumns];
        
        self.tilesArray = [NSMutableArray array];
        
        for (NSInteger eachRow = 0;eachRow <numberOfROws; eachRow++)
        {
            for (NSInteger eachCol = 0; eachCol < numberOfColums; eachCol++)
            {
                [self.tilesArray addObject:[NSNull null]];
            }
        }
    }
    else if(viewSize.height != self.bounds.size.height)
    {
        //        for (id obj in self.tilesArray)
        //        {
        //            if (obj != [NSNull null])
        //            {
        //                [(FTTile*)obj setIsDirty:YES];
        //            }
        //        }
        
        NSInteger lasstRow = _numberOfRows;
        //just find out the rows and don't remove the tiles.
        _numberOfRows = -1;
        NSInteger numberOfROws = [self numberOfRows];
        NSInteger numberOfColums = [self numberOfColumns];
        if (lasstRow > numberOfROws) {
            //delete
            for (NSInteger eachRow = lasstRow;eachRow > numberOfROws; eachRow--)
            {
                for (NSInteger eachCol = 0; eachCol < numberOfColums; eachCol++)
                {
                    NSInteger index = eachRow*numberOfColums+eachCol;
                    if (self.tilesArray.count > index)
                    {
                        FTTile *tile = [self.tilesArray objectAtIndex:index];
                        if([self.subviews containsObject:tile])
                        {
#if REMOVE_OLD_TILES_IMMEDIATLY
                            if ((id)tile != [NSNull null])
                            {
                                [self.tileProvider releaseTile:tile];
                            }
                            [tile removeFromSuperview];
                            tile.shouldRemove = NO;
#else
                            tile.shouldRemove = YES;
#endif
                        }
                        [self.tilesArray removeObjectAtIndex:index];
                    }
                }
            }
        }
        else
        {
            //add
            for (NSInteger eachRow = lasstRow;eachRow < numberOfROws; eachRow++)
            {
                for (NSInteger eachCol = 0; eachCol < numberOfColums; eachCol++)
                {
                    [self.tilesArray addObject:[NSNull null]];
                }
            }
        }
        for (id eachItem in self.tilesArray) {
            if ((id)eachItem != [NSNull null])
            {
                [(FTTile*)eachItem setIsDirty:true];
                [self.tileProvider releaseTile:eachItem];
            }
        }
    }
    else {
        for (id eachItem in self.tilesArray) {
            if ((id)eachItem != [NSNull null])
            {
                [(FTTile*)eachItem setIsDirty:true];
                [self.tileProvider releaseTile:eachItem];
            }
        }
    }
    viewSize = self.bounds.size;
}

#if 0
-(void)layoutSubviews
{
    NSInteger numberOfROws = [self numberOfRows];
    NSInteger numberOfColums = [self numberOfColumns];
    
    for (NSInteger eachRow = 0;eachRow < numberOfROws; eachRow++)
    {
        for (NSInteger eachCol = 0; eachCol < numberOfColums; eachCol++)
        {
            NSInteger index = (eachRow*numberOfColums)+eachCol;
            id object = [self.tilesArray objectAtIndex:index];
            if([NSNull null] != object)
            {
                FTTile *aTile = (FTTile*)object;
                CGRect frame = [self frameForTileAtRow:eachRow col:eachCol];
                aTile.frame = frame;
            }
        }
    }
}
#endif

-(NSInteger)numberOfRows
{
    if(_numberOfRows == -1)
    {
        NSInteger numberOfROws = 0;
        if(tileSize.height > 0)
            numberOfROws = ceilf(self.frame.size.height/tileSize.height);
        _numberOfRows = numberOfROws;
    }
    return _numberOfRows;
}

-(NSInteger)numberOfColumns
{
    if(_numberOfCols == -1)
    {
        NSInteger numberOfColums = 0;
        if(tileSize.width > 0)
            numberOfColums = ceilf(self.frame.size.width/tileSize.width);
        _numberOfCols = numberOfColums;
    }
    return _numberOfCols;
}

-(void)setContent:(id)content forTileAtRow:(NSInteger)row column:(NSInteger)column
{
    FTTile *tileLayer = [self tileAtRow:row column:column];
    if(tileLayer)
    {
        //[tileLayer draw];
    }
}

-(FTTile*)tileAtRow:(NSInteger)row column:(NSInteger)column generateTileIfRequired:(BOOL)generate
{
    FTTile *tile = nil;
    NSInteger tileIndex = (row*[self numberOfColumns])+column;
    if(tileIndex < self.tilesArray.count)
    {
        tile = [self.tilesArray objectAtIndex:tileIndex];
        if(generate && ((id)tile == [NSNull null]))
        {
            
            if (self.tileProvider) {
                tile = [self.tileProvider tile];
            }
            
            //[tile removeFromSuperview];
            tile.tag = tileIndex;
            [self.tilesArray replaceObjectAtIndex:tileIndex withObject:tile];
            tile.frame = [self frameForTileAtRow:row col:column];
            [self addSubview:tile];
            [tile tileDidGetAdded];
        }
    }
    if((id)tile == [NSNull null])
        tile=nil;
    return tile;
    
}


-(FTTile*)tileAtRow:(NSInteger)row column:(NSInteger)column
{
    return  [self tileAtRow:row column:column generateTileIfRequired:YES];
}

- (nonnull NSArray<FTTile *>*)tilesInRect:(CGRect)rect extraTilesCount:(NSInteger)tilesCount generateTileIfRequired:(BOOL)generate
{
    NSInteger firstVisibleRow = [self firstVisibleRowForRect:rect];
    
    if(tilesCount && firstVisibleRow > 0)
    {
        firstVisibleRow-=tilesCount;
        firstVisibleRow = MAX(firstVisibleRow, 0);
    }
    
    NSInteger lastVisibleRow = [self lastVisibleRowForRect:rect];
    if(tilesCount && lastVisibleRow > 0 && lastVisibleRow < [self numberOfRows]-1)
    {
        lastVisibleRow+=tilesCount;
        lastVisibleRow = MIN(lastVisibleRow, [self numberOfRows]);
    }
    
    NSInteger firstVisibleColumn = [self firstVisibleColForRect:rect];
    if(tilesCount && firstVisibleColumn > 0)
    {
        firstVisibleColumn-=tilesCount;
        firstVisibleColumn = MAX(firstVisibleColumn, 0);
    }
    
    NSInteger lastVisibleColumn = [self lastVisibleColForRect:rect];
    if(tilesCount && lastVisibleColumn > 0 && lastVisibleColumn < [self numberOfColumns]-1)
    {
        lastVisibleColumn+=tilesCount;
        lastVisibleColumn = MIN(lastVisibleColumn, [self numberOfColumns]);
    };
    
    NSMutableArray *visibleTilesArray = [NSMutableArray array];
    for (NSInteger eachRow = firstVisibleRow;eachRow < lastVisibleRow;eachRow++)
    {
        for (NSInteger eachCol = firstVisibleColumn;eachCol < lastVisibleColumn;eachCol++)
        {
            FTTile *layer = [self tileAtRow:eachRow column:eachCol generateTileIfRequired:generate];
            if(layer)
            {
                [visibleTilesArray addObject:layer];
            }
        }
    }
    return visibleTilesArray;
}


- (nonnull NSArray<FTTile *>*)tilesInRect:(CGRect)rect extraTilesCount:(NSInteger)tilesCount
{
    return [self tilesInRect:rect extraTilesCount:tilesCount generateTileIfRequired:YES];
}

- (nonnull NSArray<FTTile *>*)tilesSurroundingRect:(CGRect)rect level:(NSUInteger)level
{
    NSUInteger firstVisibleRowInRect= [self firstVisibleRowForRect:rect];
    NSInteger firstVisibleRow=firstVisibleRowInRect-level;
    if(firstVisibleRow<0)
        firstVisibleRow=0;
    
    
    NSUInteger lastVisibleRowInRect= [self lastVisibleRowForRect:rect];
    NSUInteger numberOfRows=[self numberOfRows];
    NSInteger lastVisibleRow=lastVisibleRowInRect+level;
    if(lastVisibleRow> numberOfRows)
        lastVisibleRow=numberOfRows;
    
    NSUInteger firstVisibleColInRect= [self firstVisibleColForRect:rect];
    NSInteger firstVisibleCol=firstVisibleColInRect-level;
    if(firstVisibleCol<0)
        firstVisibleCol=0;
    
    
    NSUInteger lastVisibleColumnInRect= [self lastVisibleColForRect:rect];
    NSUInteger numberOfColumns=[self numberOfColumns];
    NSInteger lastVisibleCol=lastVisibleColumnInRect+level;
    if(lastVisibleCol> numberOfColumns)
        lastVisibleCol=numberOfColumns;
    NSMutableArray *surroundingTiles=[NSMutableArray array];
    for (NSUInteger row=0; row<numberOfRows;row++)
    {
        for (NSUInteger col=0; col<numberOfColumns;col++)
        {
            if(row>=firstVisibleRow && row<=lastVisibleRow && col>=firstVisibleCol && col<=lastVisibleCol)
            {
                FTTile *tile=[self tileAtRow:row column:col];
                if(tile)
                    [surroundingTiles addObject:tile];
            }
            
        }
        
    }
    
    return surroundingTiles;
    
}
-(NSUInteger)firstVisibleRowForRect:(CGRect)rect
{
    rect = CGRectIntegral(rect);
    NSUInteger firstVisibleRow = MAX(CGRectGetMinY(rect)/self.tileSize.height,0);
    return firstVisibleRow;
}

-(NSUInteger)lastVisibleRowForRect:(CGRect)rect
{
    rect = CGRectIntegral(rect);
    NSUInteger lastVisibleRow = CGRectGetMaxY(rect)/self.tileSize.height;
    if((int)CGRectGetMaxY(rect)%(int)self.tileSize.height>0)
        lastVisibleRow++;
    return lastVisibleRow;
}

-(NSUInteger)firstVisibleColForRect:(CGRect)rect
{
    rect = CGRectIntegral(rect);
    NSUInteger firstVisibleColumn = MAX(CGRectGetMinX(rect),0)/self.tileSize.width;
    return firstVisibleColumn;
}

-(NSUInteger)lastVisibleColForRect:(CGRect)rect
{
    rect = CGRectIntegral(rect);
    NSUInteger lastVisibleColumn = CGRectGetMaxX(rect)/self.tileSize.width;
    if((int)CGRectGetMaxX(rect)%(int)self.tileSize.width>0)
        lastVisibleColumn++;
    return lastVisibleColumn;
}

-(FTTile*)tileAtPoint:(CGPoint)point
{
    NSInteger row = point.y/self.tileSize.height;
    NSInteger col = point.x/self.tileSize.width;
    
    FTTile *layer = [self tileAtRow:row column:col];
    return layer;
}

-(void)releaseTilesNotInRect:(CGRect)rect extraTilesCount:(NSInteger)tilesCount
{
#if 1
    if (tilesCount) {
        rect = CGRectInset(rect, -self.tileSize.width, -self.tileSize.height);
    }
    
    for (NSInteger tileIndex = 0;tileIndex < self.tilesArray.count;tileIndex++)
    {
        id tile = [self.tilesArray objectAtIndex:tileIndex];
        if((id)tile != [NSNull null])
        {
            if([self.subviews containsObject:tile])
            {
                if (!CGRectIntersectsRect(rect, [tile frame]))
                {
                    [self.tileProvider releaseTile:tile];
                    [tile removeFromSuperview];
                    [self.tilesArray replaceObjectAtIndex:tileIndex withObject:[NSNull null]];
                }
            }
        }
    }
#else
    NSInteger firstVisibleRow = [self firstVisibleRowForRect:rect];
    if(tilesCount && firstVisibleRow > 0)
    {
        firstVisibleRow-=tilesCount;
        firstVisibleRow = MAX(firstVisibleRow, 0);
    }
    NSInteger lastVisibleRow = [self lastVisibleRowForRect:rect];
    if(tilesCount && lastVisibleRow > 0 && lastVisibleRow < [self numberOfRows]-1)
    {
        lastVisibleRow+=tilesCount;
        lastVisibleRow = MIN(lastVisibleRow, [self numberOfRows]);
    }
    NSInteger firstVisibleColumn = [self firstVisibleColForRect:rect];
    if(tilesCount && firstVisibleColumn > 0)
    {
        firstVisibleColumn-=tilesCount;
        firstVisibleColumn = MAX(firstVisibleColumn, 0);
    }
    NSInteger lastVisibleColumn = [self lastVisibleColForRect:rect];
    
    if(tilesCount && lastVisibleColumn > 0 && lastVisibleColumn < [self numberOfColumns]-1)
    {
        lastVisibleColumn+=tilesCount;
        lastVisibleColumn = MIN(lastVisibleColumn, [self numberOfColumns]);
    }
    
    for (NSInteger eachRow = 0; eachRow < [self numberOfRows]; eachRow++)
    {
        for (NSInteger eachCol = 0; eachCol < [self numberOfColumns]; eachCol++)
        {
            BOOL shouldRemove = NO;
            
            NSInteger tileIndex = (eachRow*[self numberOfColumns])+eachCol;
            id tile = [self.tilesArray objectAtIndex:tileIndex];
            
            if((eachRow < firstVisibleRow) || (eachRow >= lastVisibleRow))
            {
                shouldRemove = YES;
            }
            else if((eachRow >= firstVisibleRow) && (eachRow <= lastVisibleRow))
            {
                if((eachCol < firstVisibleColumn) || (eachCol >= lastVisibleColumn))
                {
                    shouldRemove = YES;
                }
            }
            
            if(shouldRemove)
            {
                if((id)tile != [NSNull null])
                {
                    if([self.subviews containsObject:tile])
                    {
                        [self.tileProvider releaseTile:tile];
                        [tile removeFromSuperview];
                        [self.tilesArray replaceObjectAtIndex:tileIndex withObject:[NSNull null]];
                    }
                }
                
            }
        }
    }
#endif
}

-(CGRect)frameForTileAtIndex:(NSInteger)index
{
    CGRect tileRect = CGRectZero;
    NSInteger row = 0;
    NSInteger col = 0;
    
    NSInteger numberOfRows = [self numberOfRows];
    if(numberOfRows > 0)
    {
        row = index/numberOfRows;
        col = index%numberOfRows;
    }
    
    ;
    tileRect = [self frameForTileAtRow:row col:col];
    return tileRect;
}

-(CGRect)frameForTileAtRow:(NSInteger)row col:(NSInteger)col
{
    CGRect tileRect = CGRectZero;
    tileRect.size = self.tileSize;
    tileRect.origin.x = col*tileSize.width;
    tileRect.origin.y = row*tileSize.height;
    return tileRect;
}

-(void)removeAllTiles
{
    NSMutableArray *localtilesArray = [NSMutableArray arrayWithArray:self.tilesArray];
    for (FTTile *tile in localtilesArray) {
        if((id)tile != [NSNull null])
        {
            if([self.subviews containsObject:tile])
            {
                
#if REMOVE_OLD_TILES_IMMEDIATLY
                [self.tileProvider releaseTile:tile];
                [tile removeFromSuperview];
                tile.shouldRemove = NO;
#else
                tile.shouldRemove = YES;
#endif
                
                [self.tilesArray replaceObjectAtIndex:[self.tilesArray indexOfObject:tile] withObject:[NSNull null]];
                
            }
        }
    }
}

-(void)removeTilesMarkedAsShouldRemove{
    
    for (UIView *aView in self.subviews) {
        
        if ([aView isKindOfClass:[FTTile class]]) {
            
            FTTile *aTile = (FTTile *)aView;
            
            if (aTile.shouldRemove) {
                aTile.shouldRemove = NO;
                
                [self.tileProvider releaseTile:aTile];
                [aTile removeFromSuperview];
            }
        }
    }
}

@end
