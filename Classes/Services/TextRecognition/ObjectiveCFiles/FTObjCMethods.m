//
//  FTRecognitionProcessor.m
//  Noteshelf
//
//  Created by Naidu on 24/12/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

#import "FTObjCMethods.h"
#import "Noteshelf-Swift.h"

//Workaround for pointerEvents which are not working in Swift
@implementation FTObjCMethods
+(void)finishBulkEvents:(NSInteger)totalCount events:(NSArray*)events andEditor:(IINKEditor *)editor{
    NSInteger index = 0;
    IINKPointerEvent *pointerEvents = malloc(sizeof(IINKPointerEvent)*totalCount);
    for(FTScriptEvent *eachEvent in events) {
        switch(eachEvent.type){
            case 0:
                pointerEvents[index] = IINKPointerEventMakeDown(eachEvent.point, -1, 0, IINKPointerTypePen, 0);
                break;
            case 1:
                pointerEvents[index] = IINKPointerEventMakeMove(eachEvent.point, -1, 0, IINKPointerTypePen, 0);
                break;
            case 2:
                pointerEvents[index] = IINKPointerEventMakeUp(eachEvent.point, -1, 0, IINKPointerTypePen, 0);
                break;
            default:
                break;
        }
        index++;
    }
    
    NSError *error;
    @try{
        [editor pointerEvents:pointerEvents count:events.count doProcessGestures:NO error:&error];
        [editor waitForIdle];
    }
    @catch(NSException *e){
        
    }
    free(pointerEvents);
}
@end
