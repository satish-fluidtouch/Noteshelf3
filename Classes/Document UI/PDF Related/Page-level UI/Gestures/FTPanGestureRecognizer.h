//
//  FTPanGestureRecognizer.h
//  Noteshelf
//
//  Created by Rama Krishna on 18/6/13.
//
//

#import "FTTwoTouchBaseGestureRecognizer.h"

typedef NS_ENUM(NSInteger,FTPanRecognitionType)
{
    FTPanRecognitionTypeDefault,
    FTPanRecognitionTypeSingleFinger,
};

@interface FTPanGestureRecognizer : FTTwoTouchBaseGestureRecognizer

@property (assign) FTPanRecognitionType recognitionType;

@end
