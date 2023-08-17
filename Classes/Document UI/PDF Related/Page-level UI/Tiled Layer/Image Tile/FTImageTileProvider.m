//
//  FTImageTileProvider.m
//  Noteshelf
//
//  Created by Rama Krishna on 7/5/13.
//
//

#import "FTImageTileProvider.h"
#import "FTTile.h"

CG_EXTERN CGFloat TILE_SIZE;

@implementation FTImageTileProvider

-(FTTile*)tile{
    return [[FTTile alloc] initWithFrame:CGRectMake(0, 0, TILE_SIZE, TILE_SIZE)];
}

-(void)releaseTile:(FTTile*)inTile{
    
}


@end
