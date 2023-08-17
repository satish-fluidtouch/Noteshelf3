//
//  FTAudioPlayerManager.m
//  Noteshelf
//
//  Created by Chandan on 13/8/15.
//
//

#import "FTAudioAnnotationViewManager.h"
#import "FTAudioPlayerController.h"
#import "FTAudioAnnotationViewController.h"
#import "Noteshelf-Swift.h"

@interface FTAudioAnnotationViewManager ()<FTAudioPlayerControllerProtocol>

@property (nonatomic,strong)FTAudioPlayerController *playerController;
@property (nonatomic,strong)NSMutableArray *annotatonViewControllers;

@end

@implementation FTAudioAnnotationViewManager

+(instancetype)sharedManager
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.annotatonViewControllers = [NSMutableArray array];
    }
    return self;
}

-(void)deSelectAllAnnotations:(BOOL)forceFully
{
    NSMutableArray *selectedAnnotations = [NSMutableArray array];
    [self.annotatonViewControllers enumerateObjectsUsingBlock:^(FTAudioAnnotationViewController *viewController, NSUInteger idx, BOOL *stop) {
        if(!forceFully){
            id<FTAudioAnnotationProtocol> annotation = viewController.annotation;
            FTAudioRecordingModel *currentModel = self.playerController.recordingModel;
            if(![currentModel isEqual:annotation.recordingModel] || !currentModel){
                [selectedAnnotations addObject:viewController];
            }
        }
        else{
            [selectedAnnotations addObject:viewController];
        }
    }];
    
    [selectedAnnotations enumerateObjectsWithOptions:NSEnumerationReverse
                                          usingBlock:^(FTAudioAnnotationViewController *viewController, NSUInteger idx, BOOL *stop) {
                                              [viewController deselectAnnotation];
                                          }];
}

-(void)createAudioPlayerForAnnoatation:(id<FTAudioAnnotationProtocol>)annotation audioState:(AudioSessionState)state
{
    FTAudioPlayerController *playerController = [[FTAudioPlayerController alloc] initWithNibName:@"FTAudioPlayerController" bundle:nil];
    self.playerController = playerController;
    self.playerController.delegate = self;
    self.playerController.recordingModel = [annotation recordingModel];
    
    UIViewController *rootViewController = [APP_DELEGATE rootViewController];

    CGRect tempFrame = self.playerController.view.frame;
    tempFrame.origin.y = 64.0;
    if(rootViewController.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact) {
        tempFrame.origin.y = 44.0;
    }
    tempFrame.size.height = 0;
    tempFrame.size.width = CGRectGetWidth(rootViewController.view.frame);
    self.playerController.view.frame = tempFrame;
    
    CGRect frame = self.playerController.view.frame;
    frame.size.height = 47;
    
    [rootViewController.view addSubview:self.playerController.view];
    
    [UIView animateWithDuration:0.1 animations:^(void){
        self.playerController.view.frame =frame;
    }];

    [self.playerController resetControllerForState:state];
    
    NSString *audioModelName = self.playerController.recordingModel.fileName;
    if(audioModelName)
    {
        NSDictionary *dict = @{@"audioModelName":audioModelName,@"annotation":annotation};
        [[NSNotificationCenter defaultCenter] postNotificationName:FTAudioPlayerControllerDidOpenNotification object:self userInfo:dict];
    }
}

-(void)showAudioControlForAnnoatation:(id<FTAudioAnnotationProtocol>)annotation
                           audioState:(AudioSessionState)state
{
    if(!self.playerController){
        [self createAudioPlayerForAnnoatation:annotation audioState:state];
        [self.playerController animateView:0.3f state:state];
    }
    else{
        FTAudioAnnotation *audioAnnotataion = (FTAudioAnnotation *)annotation;
        if(![self isSameHasAudioControlModel:audioAnnotataion.recordingModel]){
            [self.playerController resetControllerForState:state];
            
            self.playerController.recordingModel = [annotation recordingModel];

            [self.playerController fadeAnimation:state];
            [self postPlayerAnnotationDidChangeNotification];
        }
        else{
            if(state == AudioStateRecording){
                [self.playerController recordAudio];
            }
            else{
                [self.playerController playAudio];
            }
        }
    }
}

-(CGFloat)currentPlayingRate
{
    CGFloat rate = 1.0f;
    if(self.playerController){
        rate = self.playerController.rate;
    }
    return rate;
}

-(void)removeAudioControllerForAnnotation:(id<FTAudioAnnotationProtocol>)annotation
{
    if(self.playerController){
        if(annotation){
            NSString *audioModelName = self.playerController.recordingModel.fileName;
            if(audioModelName){
                NSDictionary *dict = @{@"audioModelName":audioModelName,@"annotation":annotation};
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:FTAudioPlayerControllerDidCloseNotification object:self userInfo:dict];
                });
            }
        }
        else{
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:FTAudioPlayerControllerDidCloseNotification object:nil userInfo:nil];
            });
        }

        [self.playerController resetControllerForState:AudioStateNone];
        
        CGRect frame = self.playerController.view.frame;
        frame.size.height = 0.0;
        UIViewController *currentPlayer = self.playerController;
        self.playerController = nil;
        [UIView animateWithDuration:0.1 animations:^(void){
            currentPlayer.view.frame = frame;
        } completion:^(BOOL finished){
            [currentPlayer.view removeFromSuperview];
        }];
    }
}


#pragma mark - AnnotationViewController - 

-(void)addViewForAudioAnnotation:(id<FTAudioAnnotationProtocol>)annotation
                            view:(UIView*)parentView
                      controller:(UIViewController*)parentController
                           scale:(CGFloat)scale
                       eventType:(FTProcessEventType)eventType;
{
    
    FTAudioAnnotationViewController *annotationViewController = [self controllerForAnnotation:annotation];
    if(!annotationViewController){
        [self deSelectAllAnnotations:YES];

        annotationViewController = [FTAudioAnnotationViewController viewController];
        [parentView addSubview:annotationViewController.view];
        annotationViewController.view.layer.zPosition = 1;//always comes to top
        annotationViewController.delegate = self;
        [self.annotatonViewControllers addObject:annotationViewController];
        annotationViewController.view.frame = parentView.bounds;
    }
    
    [annotationViewController updateContentForAnnotation:annotation scale:scale];
    [annotationViewController processEvent:eventType];
}

-(void)removeViewForAudioAnnotation:(id<FTAudioAnnotationProtocol>)annotation
{
    FTAudioAnnotationViewController *controller = [self controllerForAnnotation:annotation];
    if(controller){
        [controller.view removeFromSuperview];
        [self.annotatonViewControllers removeObject:controller];
    }
}

-(void)update:(CGFloat)scale
{
    [self.annotatonViewControllers enumerateObjectsUsingBlock:^(FTAudioAnnotationViewController *obj, NSUInteger idx, BOOL *stop) {
        obj.scale = scale;
    }];
}

-(FTAudioAnnotationViewController*)controllerForAnnotation:(id<FTAudioAnnotationProtocol>)annotation
{
    __block FTAudioAnnotationViewController *controller = nil;
    [self.annotatonViewControllers enumerateObjectsUsingBlock:^(FTAudioAnnotationViewController *obj, NSUInteger idx, BOOL *stop) {
        if([[obj.annotation uuid] isEqual:[annotation uuid]]){
            controller = obj;
            *stop = YES;
        }
    }];
    return controller;
}


-(BOOL)isSameHasAudioControlModel:(FTAudioRecordingModel *)model
{
    BOOL isSame = NO;
    FTAudioRecordingModel *playerModel = [self.playerController recordingModel];
    if([playerModel.fileName isEqualToString:model.fileName]){
        isSame = YES;
    }
    return isSame;
}

-(void)postPlayerAnnotationDidChangeNotification
{
    NSString *audioModelName = self.playerController.recordingModel.fileName;
    if(audioModelName){
        NSDictionary *dict = [NSDictionary dictionaryWithObject:audioModelName forKey:@"audioModelName"];
        [[NSNotificationCenter defaultCenter] postNotificationName:FTAudioPlayerControllerDidChangeAnnotationNotification object:self userInfo:dict];
    }
}

-(void)updateOrientation:(UIInterfaceOrientation)interfaceOrientation alwaysInPortrait:(BOOL)alwaysInPortrait isInverted:(BOOL)isInverted
{
    [self.annotatonViewControllers enumerateObjectsUsingBlock:^(FTAudioAnnotationViewController *obj, NSUInteger idx, BOOL *stop) {
        [obj updateOrientation:interfaceOrientation alwaysInPortrait:alwaysInPortrait isInverted:isInverted];
    }];
}

#pragma mark - AnnotationController Delegates - 

- (void)annotation:(id<FTAudioAnnotationProtocol>)annotation
     didMoveToRect:(CGRect)newBoudingRect
{
    if(self.delegate && [self.delegate respondsToSelector:@selector(annotation:didMoveToRect:)]){
        [self.delegate annotation:(FTAudioAnnotation*)annotation didMoveToRect:newBoudingRect];
    }

}

- (void)annotationView:(FTAudioAnnotationViewController*)annotationViewController
              exportAs:(id<FTAudioAnnotationProtocol>)annotation;
{
    if(self.delegate && [self.delegate respondsToSelector:@selector(annotationView:exportAs:)]){
        [self.delegate annotationView:annotationViewController exportAs:annotation];
    }
    
}

- (void)annotationView:(FTAudioAnnotationViewController*)annotationViewController
           didSelected:(id<FTAudioAnnotationProtocol>)annotation
{
    if(self.delegate && [self.delegate respondsToSelector:@selector(annotationDidSelect:)]){
        [self.delegate annotationDidSelect:(FTAudioAnnotation*)annotation];
    }
}

- (void)annotationView:(FTAudioAnnotationViewController*)annotationViewController
           didDeselect:(FTAnnotation*)annotation
{
    if(self.delegate && [self.delegate respondsToSelector:@selector(annotationDidDeselect:)]){
        [self.delegate annotationDidDeselect:(FTAudioAnnotation*)annotation];
    }
    [self removeViewForAudioAnnotation:(FTAudioAnnotation*)annotation];
}

- (void)audioAnnotationDidStartRecording:(FTAudioAnnotationViewController *)annotationViewController
{
    [self showAudioControlForAnnoatation:annotationViewController.annotation audioState:AudioStateRecording];
}

- (void)audioAnnotationDidStartPlay:(FTAudioAnnotationViewController *)annotationViewController
{
    FTAudioAnnotationViewController *controller = (FTAudioAnnotationViewController *)annotationViewController;
    [self showAudioControlForAnnoatation:controller.annotation audioState:AudioStatePlaying];
}

- (void)audioAnnotationDidStopRecording:(FTAudioAnnotationViewController *)annotationViewController
{
    [self.playerController stopRecord];
}

- (void)audioAnnotationDidStopPlay:(FTAudioAnnotationViewController *)annotationViewController
{
    [self.playerController pauseAudio];
}

-(void)deleteAnnotation:(id<FTAudioAnnotationProtocol>)audioAnnotation
{
    [self audioAnnotationDeleteSelected:audioAnnotation];
}

- (void)audioAnnotationDeleteSelected:(id<FTAudioAnnotationProtocol>)annotation
{
    id<FTAudioAnnotationProtocol> audioAnnotation = self.playerController.recordingModel.representedObject;
    if([[audioAnnotation uuid] isEqualToString:[annotation uuid]]){
        [self removeAudioControllerForAnnotation:annotation];
    }
    [self removeViewForAudioAnnotation:annotation];
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(annotationDidDelete:)]){
        [self.delegate annotationDidDelete:(FTAudioAnnotation*)annotation];
    }
}

-(id<FTAudioAnnotationProtocol>)activeAudioAnnotation
{
    return self.playerController.recordingModel.representedObject;
}

-(void)audioPlayerDidClose:(FTAudioPlayerController *)controller
{
    id<FTAudioAnnotationProtocol> audioAnnotation = controller.recordingModel.representedObject;
    [self removeAudioControllerForAnnotation:audioAnnotation];
}

- (void)audioPlayerDidExpand:(FTAudioPlayerController *)controller {
    [[NSNotificationCenter defaultCenter] postNotificationName:FTAudioPlayerControllerDidExpand object:nil];
}
- (void)audioPlayerDidCollapse:(FTAudioPlayerController *)controller {
    [[NSNotificationCenter defaultCenter] postNotificationName:FTAudioPlayerControllerDidCollapse object:nil];
}


-(BOOL)isPlayerVisible
{
    BOOL visible = NO;
    if(self.playerController){
        visible = YES;
    }
    return visible;
}

-(BOOL)isExpanded
{
    BOOL isExpanded = NO;
    if(self.playerController){
        isExpanded = self.playerController.isExpanded;
    }
    return isExpanded;
}

-(void)cleanUP
{
    [self.annotatonViewControllers removeAllObjects];
    [self removeAudioControllerForAnnotation:nil];
}

@end
