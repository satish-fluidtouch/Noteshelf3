//
//  FTCSIndexModel.h
//  FTWhink
//
//  Created by Chandan on 14/10/15.
//  Copyright © 2015 Fluid Touch Pte Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FTCSIndexItem : NSObject

@property(nonatomic,strong)NSString *uniqueID;
@property(nonatomic,strong)NSDate *modifiedDate;

-(NSDictionary*)dictionary;
-(id)initWithDictionary:(NSDictionary*)dictionary;

@end


