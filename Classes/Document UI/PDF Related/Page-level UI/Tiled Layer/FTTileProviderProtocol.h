//
//  FTTileProviderProtocol.h
//  Noteshelf
//
//  Created by Rama Krishna on 7/5/13.
//
//

@class FTTile;

#ifndef Noteshelf_FTTileProviderProtocol_h
#define Noteshelf_FTTileProviderProtocol_h

@protocol FTTileProvider <NSObject>

-(FTTile*)tile;
-(void)releaseTile:(FTTile*)inTile;

@end

#endif
