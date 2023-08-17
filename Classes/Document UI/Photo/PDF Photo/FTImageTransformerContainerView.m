//
//  FTImageTransformerContainerView.m
//  Noteshelf
//
//  Created by Amar Udupa on 20/5/13.
//
//

#import "FTImageTransformerContainerView.h"
#import "ImageTransformerView.h"
#import <QuartzCore/QuartzCore.h>
#import "UIImageAdditions.h"
#import "Noteshelf-Swift.h"

#define CONTROL_POINT_SIZE 40

CG_INLINE CGFloat getSizeAdjustmentRatio(CGSize sourceSize,CGSize targetSize);

@interface FTImageTransformerContainerView () <FTImageEditerDelegate>
{
    BOOL editing;
    CGAffineTransform editingTransform;
    
    @private
    UIImageView *controlPointTopLeft;
    UIImageView *controlPointTopRight;
    UIImageView *controlPointBottomLeft;
    UIImageView *controlPointBottomRight;
}

- (CGFloat) getSizeAdjustmentRatio:(CGSize)sourceSize toSize:(CGSize)targetSize;
- (void)showControlPoints:(NSNumber*)showMenu;
- (void)hideControlPoints;
- (void)reset;
- (void)setupMenuItems;

@property (nonatomic) CGSize sourceImageSize;
@property (nonatomic, strong) ImageTransformerView *imageTransformerView;

@property (strong) FTImageEditerViewController *editorController;
@property (nonatomic, strong) UIImage *sourceImageTemp;

@property (weak) UITapGestureRecognizer *doubleTapGesture;

@end


@implementation FTImageTransformerContainerView

@synthesize sourceImage, sourceImageTemp, delegate;
@synthesize imageTransformerView,representedObject;

@synthesize sourceImageSize;
@synthesize zoomScale;
@synthesize imageScale;
@synthesize allowsResizing;
@synthesize allowsCopyPaste;
@synthesize initialFrame = _initialFrame;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.multipleTouchEnabled = YES;
        self.clipsToBounds = YES;
        self.layer.zPosition = 1;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        
        self.editorController = [[FTImageEditerViewController alloc] initWithNibName:@"FTImageEditerViewController" bundle:nil];
        self.editorController.delegate = self;
        [self addSubview:self.editorController.view];
        allowsResizing = YES;
        allowsCopyPaste = YES;
        self.zoomScale = 1.0f;
        self.imageScale = [[UIScreen mainScreen] scale];
        editingTransform = CGAffineTransformIdentity;
        
        self.photoMode = FTPhotoModeNormal;
        
        UITapGestureRecognizer *tapGestue = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapGestureRecognized:)];
        [self.editorController.view addGestureRecognizer:tapGestue];
        tapGestue.cancelsTouchesInView = NO;
        
        UITapGestureRecognizer *doubleTapGestue = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapGestureRecognized:)];
        doubleTapGestue.numberOfTapsRequired = 2;
        self.doubleTapGesture = doubleTapGestue;
        [self.editorController.view addGestureRecognizer:doubleTapGestue];
        doubleTapGestue.cancelsTouchesInView = NO;
    }
    return self;
}

-(void)setupMenuItems{
    [self becomeFirstResponder];
    UIMenuController *theMenu = [UIMenuController sharedMenuController];
    UIMenuItem *editMenuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Edit", @"Edit") action:@selector(editMenuAction:)];
    
    UIMenuItem *deleteMenuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Delete", @"Delete") action:@selector(deleteMenuAction:)];
    UIMenuItem *doneMenuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Done", @"Done") action:@selector(doneMenuAction:)];
    //    theMenu.menuItems = [NSArray arrayWithObjects:pasteMenuItem, deleteMenuItem,cancelMenuItem, nil];
    theMenu.menuItems = [NSArray arrayWithObjects:deleteMenuItem,editMenuItem,doneMenuItem,nil];
}

-(void)setInitialFrame:(CGRect)frame
{
    frame = CGRectIntegral(frame);
    [self.editorController updateContentFrame:frame];
    _initialFrame = frame;
}

-(CGRect)initialFrame
{
    return _initialFrame;
}

-(void)setEditing:(BOOL)isEditing
{
    editing = isEditing;
    
    if(editing) {
        UIImage *localSourceImage = self.sourceImage;
        self.sourceImageTemp = localSourceImage;
        [self.editorController setContentImage:self.sourceImage];
        sourceImageSize = CGSizeMake(localSourceImage.size.width/self.imageScale, localSourceImage.size.height/self.imageScale);
        
        CGSize sourceImageSz = CGSizeScale(sourceImageSize, self.zoomScale);
        
        startingFrame = CGRectMake((self.frame.size.width - sourceImageSz.width)*0.5,
                                   (self.frame.size.height - sourceImageSz.height)*0.5,
                                   sourceImageSz.width, sourceImageSz.height);
        
        if(self.allowsResizing) {
            [self hideControlPoints];
            [self becomeFirstResponder];
            [self setupMenuItems];
            [self performSelector:@selector(showControlPoints:) withObject:@YES afterDelay:0.5];
            [self performSelector:@selector(singleTapGestureRecognized:) withObject:nil afterDelay:0.5];
        }
        else {
            [self becomeFirstResponder];
            [self setupMenuItems];
        }
    }
    else
    {
        self.sourceImageTemp = self.sourceImage;//[self.sourceImage scaleDownToHalf];
        [self.editorController setContentImage:self.sourceImage];
        [self reset];
    }
}
-(void)setDroppedImageToBeActive{
    sourceImageSize = CGSizeMake(sourceImage.size.width/[[UIScreen mainScreen] scale], sourceImage.size.height/[[UIScreen mainScreen] scale]);
    
    imageTransformerView.image = self.sourceImageTemp;
    [self hideControlPoints];
    [self becomeFirstResponder];
    [self setupMenuItems];
    [self performSelector:@selector(showControlPoints:) withObject:@NO afterDelay:0.5];

}
-(void)reset
{
    startingFrame = [sourceImage aspectFrameWithinScreenArea:self.frame zoomScale:self.zoomScale];
    sourceImageSize = CGSizeMake(sourceImage.size.width/[[UIScreen mainScreen] scale], sourceImage.size.height/[[UIScreen mainScreen] scale]);

    startingFrame = CGRectIntegral(startingFrame);
    [self.editorController updateContentFrame:startingFrame];
    [self hideControlPoints];
    [self becomeFirstResponder];
    [self setupMenuItems];
    if(self.completionHandler)
    {
        self.hidden=YES;
        self.completionHandler(self, startingFrame, YES);
        return;
    }

    [self performSelector:@selector(showControlPoints:) withObject:@NO afterDelay:0.5];
}

-(void)setAllowsResizing:(BOOL)inAllowsResizing
{
    allowsResizing = inAllowsResizing;
    self.editorController.allowsResizing = inAllowsResizing;
    if(!inAllowsResizing)
    {
        [self hideControlPoints];
    }
}

-(void)setAllowsEditing:(BOOL)allowsEditing
{
    self.doubleTapGesture.enabled = allowsEditing;
    [self.imageTransformerView setAllowsEditing:allowsEditing];
    self.editorController.allowsEditing = allowsEditing;
}

-(CGAffineTransform)transformedMatrix
{
    return CGAffineTransformIdentity;
}

-(UIImage *)getTransformedImageClipToBounds:(BOOL)clipToBounds{
    return self.sourceImage;
}

-(CGRect)getPlacementRect{
    if(nil == self.editorController) {
        FTCLSLog(@"getPlacementRect: editorController nil");
    }
    CGRect frame = [self.editorController contentFrame];
    return frame;
}

// Touch handling, tile selection, and menu/pasteboard.
- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    
    if (operationActive) {
        return;
    }
    
    CGPoint currentPoint = [[touches anyObject] locationInView:self];
    UIView *hitView =  [self hitTest:currentPoint withEvent:event];
    
    operationActive = YES;
    
    if (hitView.tag > 0) {
        
        activeControlPoint = hitView.tag;
        
    }else if(hitView.tag == -1){
        
        activeControlPoint = kControlPointNone;
        
    }else{
        operationActive = NO;
    }
    
    if([self isPointInside:currentPoint]) {
        operationActive = YES;
    }
    
    if (!operationActive) {
        if([[self delegate] respondsToSelector:@selector(imageTransformerContainerViewDidTapOutsideControlPoint:)])
            [[self delegate]imageTransformerContainerViewDidTapOutsideControlPoint:self ];
        
        return;
    }
    
    [self hideControlPoints];
    [self showMenu:false];
    startPoint = [[[touches allObjects] objectAtIndex:0] locationInView:self];
    currentFrame = imageTransformerView.frame;
    [self.imageTransformerView didBeginResizing];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    
    if (!operationActive)
        return;
}


- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event{
    [self imageTransformerViewOperationCancelled];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    if (!operationActive)
        return;
    
    //NSLog(@"touchesEnded on Control Point");
    operationActive = NO;
    [self showMenu:true];
    [self showControlPoints:@YES];
//    [self performSelector:@selector(showControlPoints:) withObject:@YES afterDelay:0.0];
    if([delegate respondsToSelector:@selector(imageTransformerContainerViewDidEndOperation:)])
    {
        [delegate imageTransformerContainerViewDidEndOperation:self];
    }
}

#pragma mark - ImageTransformerViewDelegate -
-(void)imageTransformerViewOperationStarted{
    if(self.allowsResizing)
    {
        [self hideControlPoints];
    }
}

-(void)imageTransformerViewOperationEndedShowMenu:(BOOL)showMenu
{
    if(self.allowsResizing)
    {
        [self showControlPoints:@(showMenu)];
    }
}

-(void)imageTransformerViewOperationInProgress
{
    [self showMenu:false];
}


-(void)imageTransformerViewDidEndImageEditing
{
    [self showControlPoints:@YES];
    if ([self.delegate respondsToSelector:@selector(imageTransformerContainerDidFinishEditing:)]) {
        [self.delegate imageTransformerContainerDidFinishEditing:self];
    }
    [self showMenu:false];
}

-(void)imageTransformerViewDidStartImageEditing
{
    [self showControlPoints:@NO];
    [self showMenu:false];
}

-(BOOL)imageTransformerViewShouldZoom
{
    return YES;
}

-(void)imageTransformerViewOperationCancelled
{
    operationActive = NO;

    [self.delegate imageTransformerContainerViewCancel:self withExternatTouches:YES];
}

-(CGRect)visibleBounds
{
    if([self.delegate respondsToSelector:@selector(visibleBounds)]) {
        return [self.delegate visibleBounds];
    }
    return CGRectZero;
}

#pragma mark - FTImageEditerDelegate -
-(void)imageEditorDidStartRotation:(FTImageEditerViewController *)controller
{
    [self hideControlPoints];
    [self showMenu:false];
}

-(FTPhotoMode)currentPhotoMode
{
    return self.photoMode;
}

-(void)imageEditorDidEndRotation:(FTImageEditerViewController *)controller
{
    [self showControlPoints:@YES];
    [self showMenu:true];
}

- (void)imageEditorDidStartScale:(FTImageEditerViewController *)controller
{
    [self hideControlPoints];
    [self showMenu:false];
}

- (void)imageEditorDidEndScale:(FTImageEditerViewController *)controller
{
    [self showControlPoints:@YES];
    [self showMenu:true];
}
#pragma mark-
#pragma mark EditImageDelegate
- (void)didCancelEditing:(EditImageRootViewController *)viewController
{
    FTCLSLog(@"Image Cancel Editing");
    [self showMenu:true];
    [self showControlPoints:@YES];
}

- (void)didEndEditing:(EditImageRootViewController *)viewController withImage:(UIImage *)finalImage
{
    FTCLSLog([NSString stringWithFormat:@"Image End Editing: image size: %@",NSStringFromCGSize(finalImage.size)]);
    if (!CGSizeEqualToSize(sourceImage.size, finalImage.size)) {
        sourceImage = finalImage;
        _sourceImageUpdated = YES;
        CGPoint center = self.editorController.view.center;
        [self reset];
        self.editorController.view.center = center;
    }else{
        sourceImage = finalImage;
        _sourceImageUpdated = YES;
    }
    [self.editorController setContentImage:sourceImage];
    [self showMenu:true];
    [self showControlPoints:@YES];
}

#pragma mark - test -


-(CGPoint)imageTransformerViewForBoundary:(CGPoint)center
{
    CGRect rectWithinBoundary = [self frameWithinBoundaryForCenter:center];
    return CGPointMake(CGRectGetMidX(rectWithinBoundary), CGRectGetMidY(rectWithinBoundary));
}

-(CGPoint)pointWithinBoundary:(CGPoint)point
{
    CGPoint newPoint = point;
    CGRect boundaryRect = self.bounds;
    CGFloat halfKnobSize = CONTROL_POINT_SIZE*0.25;
    if(newPoint.x < CGRectGetMinX(boundaryRect)+halfKnobSize)
        newPoint.x = CGRectGetMinX(boundaryRect)+halfKnobSize;
    
    if(newPoint.x > CGRectGetMaxX(boundaryRect)-halfKnobSize)
        newPoint.x = CGRectGetMaxX(boundaryRect)-halfKnobSize;
    
    if(newPoint.y < CGRectGetMinY(self.bounds)+halfKnobSize)
        newPoint.y = CGRectGetMinY(self.bounds)+halfKnobSize;
    
    if(newPoint.y > CGRectGetMaxY(self.bounds)-halfKnobSize)
        newPoint.y = CGRectGetMaxY(self.bounds)-halfKnobSize;
    
    return newPoint;
}

-(CGRect)frameWithinBoundaryForCenter:(CGPoint)center
{
    CGRect viewSize = self.bounds;
    CGSize imageTransformerViewSize = self.imageTransformerView.frame.size;
    CGRect newRect = CGRectMake(center.x-imageTransformerViewSize.width*0.5, center.y-imageTransformerViewSize.height*0.5, imageTransformerViewSize.width, imageTransformerViewSize.height);
    
    CGFloat halfKnobSize = CONTROL_POINT_SIZE*0.25;
    
    if(newRect.origin.x < viewSize.origin.x+halfKnobSize)
    {
        newRect.origin.x = viewSize.origin.x+halfKnobSize;
    }
    if(newRect.origin.y < viewSize.origin.y+halfKnobSize)
    {
        newRect.origin.y = viewSize.origin.y+halfKnobSize;
    }
    if(CGRectGetMaxX(newRect) > CGRectGetMaxX(viewSize)-halfKnobSize)
    {
        newRect.origin.x = CGRectGetMaxX(viewSize)-CGRectGetWidth(newRect)-halfKnobSize;
    }
    if(CGRectGetMaxY(newRect) > CGRectGetMaxY(viewSize)-halfKnobSize)
    {
        newRect.origin.y = CGRectGetMaxY(viewSize)-CGRectGetHeight(newRect)-halfKnobSize;
    }
    return newRect;
}

- (void)showControlPoints:(NSNumber*)showMenu
{
    [UIView commitAnimations];
    [self becomeFirstResponder];
    [self.editorController showControlPointsWithAnimate:true];
}

- (void)hideControlPoints
{
    [UIView commitAnimations];
    [self.editorController hideControlPointsWithAnimate:true];
}

-(void)showMenu:(BOOL)show
{
    UIMenuController *theMenu = [UIMenuController sharedMenuController];
    if(show) {
        [theMenu update];
        [theMenu setTargetRect:CGRectInset(self.editorController.view.frame,0, 0) inView:self];
        [theMenu setMenuVisible:YES animated:YES];
    }
    else {
        [theMenu setMenuVisible:NO animated:YES];
    }
}

- (CGFloat) getSizeAdjustmentRatio:(CGSize)sourceSize toSize:(CGSize)targetSize{
	
	//do not resize if the actual size is within the bounds
	if (sourceSize.width <= targetSize.width && sourceSize.height <= targetSize.height) {
		return 1;
	}
	
	CGFloat horizontalRatio = targetSize.width / sourceSize.width;
    CGFloat verticalRatio = targetSize.height / sourceSize.height;
    CGFloat ratio;
	ratio = MIN(horizontalRatio, verticalRatio);
	
	return ratio;
	
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    BOOL retValue = NO;
    
    if (action == @selector(cancelMenuAction:)) {
        retValue = YES;
    }
    else if(action == @selector(deleteMenuAction:))
    {
        if(self.photoMode == FTPhotoModeTransform) {
            retValue = NO;
        }
        else {
            retValue = YES;
        }
    }
    else if (self.allowsCopyPaste && (action == @selector(pasteMenuAction:)))
    {
        if(self.editorController != nil) {
            retValue = YES;
        }
    }
    else if (action == @selector(editMenuAction:)) {
        if(self.editorController.allowsEditing) {
            retValue = YES;
        }
    }
    else if ((action == @selector(doneMenuAction:)) && imageTransformerView.imageEditingInProgress)
    {
        retValue = YES;
    }
    return retValue;
}

#pragma mark - Menu Actions -
-(void)doneMenuAction:(id)sender
{
    [self.imageTransformerView exitEditMode];
}

-(void)editMenuAction:(id)sender
{
    FTCLSLog([NSString stringWithFormat:@"Image Edit Enter (menu): %@",NSStringFromCGSize(sourceImage.size)]);
    [self displayEditImageView:sourceImage];
}

- (void)pasteMenuAction:(id)sender {
    [delegate imageTransformerContainerViewPaste:self];
}

-(void)resetMenuAction:(id)sender{
    [self reset];
}

-(void)cancelMenuAction:(id)sender{
    [delegate imageTransformerContainerViewCancel:self withExternatTouches:NO];
}

-(void)deleteMenuAction:(id)sender
{
    FTCLSLog(@"Image Delete (menu)");
    if (self.representedObject) {
        if([delegate respondsToSelector:@selector(imageTransformerContainerViewDelete:)])
            [delegate imageTransformerContainerViewDelete:self];
    }
    else
    {
        [self cancelMenuAction:nil];
    }
}

- (void)dealloc{
    [self resignFirstResponder];
}

#pragma MARK - Show editimageviewcontroller
- (void)displayEditImageView:(UIImage*)image {
    [[FTTooltipsManager sharedManager] dismissTipForID:@"PenSelectionTip" canExpireIfNeeded:FALSE];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"EditImage" bundle:nil];
    EditImageRootViewController *editImageController = [storyboard instantiateInitialViewController];
    editImageController.initialImage = image;
    editImageController.delegate = self;
    editImageController.modalPresentationStyle = UIModalPresentationOverFullScreen;

    [[APPLICATION visibleViewController] presentViewController:editImageController animated:YES completion:nil];
}

-(void)setCurrentTransform:(CGAffineTransform)transform
{
    currentTransform=transform;
}

-(void)setImageTransformation:(CGAffineTransform)imageTransform
{
    self.editorController.view.transform = imageTransform;
}

-(CGAffineTransform)imageTransformation
{
    return self.editorController.view.transform;
}

- (void)doubleTapGestureRecognized:(UITapGestureRecognizer*)gestureRecognizer
{
    FTCLSLog([NSString stringWithFormat:@"Image Edit Enter (tap): %@",NSStringFromCGSize(sourceImage.size)]);
    [self displayEditImageView:sourceImage];
}

-(void)singleTapGestureRecognized:(UITapGestureRecognizer*)gestureRecognizer
{
    if ([[UIMenuController sharedMenuController] isMenuVisible]) {
        [self showMenu:false];
    }
    else
    {
        [self showMenu:true];
    }
}

-(BOOL)isPointInside:(CGPoint)point
{
    BOOL pointInside = false;
    point = [self convertPoint:point toView:self.editorController.view];
    pointInside = [self.editorController isPointInside:point];
    return pointInside;
}
@end

@implementation UIImage (PDF_EXTRA)

- (UIImage *)resizeImageTo:(CGSize)newSize
                 transform:(CGAffineTransform)transform
              clippingRect:(CGRect)clipRect
             includeBorder:(BOOL)includeBorder{
    
    CGRect rect = CGRectIntegral(CGRectMake(0, 0, clipRect.size.width, clipRect.size.height));
    
    CGSize scaledImageSize = CGSizeMake(self.size.width, self.size.height);
    
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.0);
    CGContextSetInterpolationQuality(UIGraphicsGetCurrentContext(), kCGInterpolationLow);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    // Transform the image (as the image view has been transformed)
    CGContextTranslateCTM(ctx, newSize.width*0.5- clipRect.origin.x, newSize.height*0.5- clipRect.origin.y);
    CGContextConcatCTM(ctx, transform);
    CGContextTranslateCTM(ctx, -scaledImageSize.width*0.5, -scaledImageSize.height*0.5);
    
    CGContextTranslateCTM(ctx, 0.0, scaledImageSize.height);
    CGContextScaleCTM(ctx, 1.0, -1.0);
    
    // Draw view into context
    CGContextDrawImage(ctx, CGRectMake(0,0,scaledImageSize.width, scaledImageSize.height), self.CGImage);
    
    if (includeBorder){
        
        //Implement someday:
        
        //CGContextAddRect(ctx, CGRectInset(CGRectMake(0,0,self.size.width, self.size.height),2,2));
        //CGContextSetStrokeColorWithColor(ctx, [UIColor redColor].CGColor);
        //CGContextSetLineWidth(ctx, 10);
        //CGContextStrokePath(ctx);
    }
    
    // Create the new UIImage from the context
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // End the drawing
    UIGraphicsEndImageContext();
    
    //NSTimeInterval t2 = [NSDate timeIntervalSinceReferenceDate];
    
    //NSLog(@"%.0f", (t2-t1)*1000);
    
    return newImage;
}

-(UIImage *) scaleAndRotateImageFor1x
{
    CGRect maxRect = [[UIScreen mainScreen] bounds];
    int kMaxResolution = MAX(1500,MAX(maxRect.size.width, maxRect.size.height)); // Or whatever
    
    CGImageRef imgRef = self.CGImage;
    
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect bounds = CGRectMake(0, 0, width, height);
    
    if (width > kMaxResolution || height > kMaxResolution) {
        CGFloat ratio = width/height;
        if (ratio > 1) {
            bounds.size.width = kMaxResolution;
            bounds.size.height = bounds.size.width / ratio;
        }
        else {
            bounds.size.height = kMaxResolution;
            bounds.size.width = bounds.size.height * ratio;
        }
    }
    
    CGFloat scaleRatio = bounds.size.width / width;
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
    CGFloat boundHeight;
    UIImageOrientation orient = self.imageOrientation;
    switch(orient) {
            
        case UIImageOrientationUp: //EXIF = 1
            transform = CGAffineTransformIdentity;
            break;
            
        case UIImageOrientationUpMirrored: //EXIF = 2
            transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            break;
            
        case UIImageOrientationDown: //EXIF = 3
            transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationDownMirrored: //EXIF = 4
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
            transform = CGAffineTransformScale(transform, 1.0, -1.0);
            break;
            
        case UIImageOrientationLeftMirrored: //EXIF = 5
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationLeft: //EXIF = 6
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationRightMirrored: //EXIF = 7
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeScale(-1.0, 1.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
        case UIImageOrientationRight: //EXIF = 8
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
        default:
            [NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
            
    }
    
    UIGraphicsBeginImageContextWithOptions(bounds.size, NO, 1.0);
    CGContextSetInterpolationQuality(UIGraphicsGetCurrentContext(), kCGInterpolationHigh);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
        CGContextScaleCTM(context, -scaleRatio, scaleRatio);
        CGContextTranslateCTM(context, -height, 0);
    }
    else if (orient == UIImageOrientationRightMirrored || orient == UIImageOrientationLeftMirrored){
        CGContextScaleCTM(context, scaleRatio, -scaleRatio);
        
        CGContextTranslateCTM(context, 0, -width);
        
    }
    else {
        CGContextScaleCTM(context, scaleRatio, -scaleRatio);
        CGContextTranslateCTM(context, 0, -height);
    }
    
    CGContextConcatCTM(context, transform);
    
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageCopy;
}

-(UIImage *)scaleDownToHalf
{
    CGSize scaledImageSize = CGSizeMake(self.size.width*0.5, self.size.height*0.5);
    
    UIGraphicsBeginImageContextWithOptions(scaledImageSize, NO, 1.0);
    CGContextSetInterpolationQuality(UIGraphicsGetCurrentContext(), kCGInterpolationHigh);
    
    [self drawInRect:CGRectMake(0, 0, scaledImageSize.width, scaledImageSize.height)];
    
    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageCopy;
}

-(CGRect)aspectFrameWithinScreenArea:(CGRect)screenArea zoomScale:(CGFloat)scale
{
    CGSize imageSize = CGSizeMake(self.size.width/[[UIScreen mainScreen] scale], self.size.height/[[UIScreen mainScreen] scale]);
    
    CGSize sourceImageSz = CGSizeScale(imageSize, scale);

    CGSize targetSize = CGRectInset(screenArea,CONTROL_POINT_SIZE*0.5,CONTROL_POINT_SIZE*0.5).size;
    CGFloat ratio = getSizeAdjustmentRatio(sourceImageSz, targetSize);
    
    sourceImageSz = CGSizeScale(sourceImageSz, ratio);
    
    CGRect startingFrame = CGRectMake((screenArea.size.width - sourceImageSz.width)*0.5,
                               (screenArea.size.height - sourceImageSz.height)*0.5,
                               sourceImageSz.width, sourceImageSz.height);
    
    return startingFrame;
}

@end

CG_INLINE CGFloat getSizeAdjustmentRatio(CGSize sourceSize,CGSize targetSize)
{
    //do not resize if the actual size is within the bounds
    if (sourceSize.width <= targetSize.width && sourceSize.height <= targetSize.height) {
        return 1;
    }
    
    CGFloat horizontalRatio = targetSize.width / sourceSize.width;
    CGFloat verticalRatio = targetSize.height / sourceSize.height;
    CGFloat ratio;
    ratio = MIN(horizontalRatio, verticalRatio);
    
    return ratio;
}
