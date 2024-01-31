//
//  FTDocumentRequestModel.h
//  FTWhink
//
//  Created by Chandan on 8/3/16.
//  Copyright © 2016 Fluid Touch Pte Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FTDocument.h"

typedef void (^requestCompletionBlock)(NSUInteger token,BOOL success);
typedef void (^completionBlock)(BOOL finished);

@interface FTDocumentRequestModel : NSObject

@property(copy)requestCompletionBlock block;
@property(assign)BOOL served;
@property(assign)FTDocumentOpenRequestType requestType;
@property(weak)FTDocument *document;

@end
