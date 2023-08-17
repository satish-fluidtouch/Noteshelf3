//
//  FTStylusPenProtocol.h
//  Noteshelf
//
//  Created by Amar Udupa on 13/5/14.
//
//

#ifndef Noteshelf_FTStylusPenProtocol_h
#define Noteshelf_FTStylusPenProtocol_h

#if !TARGET_OS_MACCATALYST
#define TEST_MAJOR_RADIUS 1
#endif

@class  FTTouch;
@import FTRenderKit;

@protocol FTStylusPenDelegate <NSObject>

-(void)stylusPenTouchBegan:(FTTouch*)touch;
-(void)stylusPenTouchMoved:(FTTouch*)touch;
-(void)stylusPenTouchEnded:(FTTouch*)touch;
-(void)stylusPenTouchCancelled:(FTTouch*)touch;

-(CGSize)sizeOfCurrentStroke;
-(BOOL)isApplePencilEnabled;
-(void)enableApplePencil;
-(BOOL)shouldProcessTouch:(UITouch*)touch;


@optional
-(BOOL)isNotebookInLandscapeOrientation;
-(BOOL)isNotebookInverted;
-(void)disableGestures;
-(void)enableGestures;
-(void)stylusPenButtonAction:(RKAccessoryButtonAction)actionToPerform;
-(FTPenType)penType;
-(BOOL)shouldAlwaysUseFingerTouch;

@end

#endif
