//
//  ApplicationState.h
//  Daily Notes
//
//  Created by Rama Krishna on 3/5/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

@interface DataServices : NSObject{
    
    NSDateFormatter *shelfItemDateFormatter;
}

+(DataServices*)sharedDataServices;

-(void)initializeDatabase;

@end
