//
//  FTDocumentRequestManager.h
//  FTWhink
//
//  Created by Chandan on 8/3/16.
//  Copyright © 2016 Fluid Touch Pte Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FTDocumentRequestModel.h"
#import "FTDocument.h"

@interface FTDocumentRequestManager : NSObject

+(FTDocumentRequestManager*)sharedManager;

-(void)openDocument:(FTDocument*)document openRequestType:(FTDocumentOpenRequestType)requestType completionBlock:(requestCompletionBlock)block;
-(void)closeDocument:(FTDocument*)document andToken:(NSUInteger)token completionBlock:(completionBlock)block;
-(void)removeAllTokensForURL:(NSURL*)fileURL;

@end
