//
//  FTFlexibleTextView.m
//  Noteshelf
//
//  Created by Ashok Prabhu on 23/3/13.
//



#import "FTFlexibleTextView.h"
#import "UIColorAdditions.h"
#import "NoteshelfAppDelegate.h"
#import "NoteshelfAppDelegate.h"
#import "FTRichTextEditorView.h"
#import "Noteshelf-Swift.h"
#import "UITextView_BulletsAndIndentation.h"
#import "FTBulletsConstants.h"
#import "NSAttributedString_Extended.h"

#import "Noteshelf-Swift.h"

typedef NS_ENUM(NSInteger, FTKnobPosition)
{
    FTKnobPositionNone = -1,
    FTKnobPositionLeft = 100,
    FTKnobPositionRight,
};

@interface FTFlexibleTextView () <FTTextInputAccessoryDelegate,FTTextViewDelegate>
{
    UIImageView *resizeKnobImageView;
    BOOL isRepositionedAfterSave;
    BOOL shouldResign;
}

-(void)resizeTextViewAsNeeded;
-(void)saveTextEntryAttributes;
-(void)saveTextEntryTemporarly;

@property (nonatomic) BOOL isMoving;
@property (nonatomic) BOOL isScaling;
@property (strong) FTTextInputAccerssoryViewController *inputAccessoryViewController;

@end

@implementation FTFlexibleTextView

@synthesize textView, editMode, delegate, selected, representedObject;
@synthesize debuggingRandomID;
@synthesize zoomScale;
@synthesize isMoving, isScaling;

#pragma mark -
#pragma mark View Management

- (id)initWithFrame:(CGRect)frame
          zoomScale:(CGFloat)inZoomScale
     textAnnotation:(FTTextAnnotation*)annotation
{
    self = [super initWithFrame:frame];
    if (self) {
        zoomScale = inZoomScale;
        
		self.backgroundColor = [UIColor clearColor];
		self.exclusiveTouch = YES;
        
        shouldResign = YES;

        NSInteger version = [FTTextAnnotation defaultAnnotationVersion];
        CGFloat transformScale = 1;
        if(nil != annotation) {
            version = annotation.version;
            transformScale = annotation.transformScale;
        }
        self.representedObject = annotation;
        
        FTRichTextEditorView *richTextView = [[FTRichTextEditorView alloc] initWithFrame:self.bounds
                                                      delegate:self
                                             annotationVersion:version
                                                transformScale:transformScale];
        textView = richTextView;
        textView.userInteractionEnabled = NO;
        textView.autocorrectionType = UITextAutocorrectionTypeNo;
		[self addSubview:textView];

        FTTextInputAccerssoryViewController *accessoryViewController = [FTTextInputAccerssoryViewController viewController:self inputView:self.textView.textInputView];
        accessoryViewController.fontStyles = self.textView.fontStyles;
        self.textView.textInputView.inputAccessoryView = accessoryViewController.view;
        self.textView.autocorrectionType = UITextAutocorrectionTypeNo;
        self.inputAccessoryViewController = accessoryViewController;
        [textView applyScale:zoomScale];

        debuggingRandomID = rand();
        self.layer.zPosition=99;
        
        resizeKnobImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,KNOB_SIZE,KNOB_SIZE)];
        resizeKnobImageView.image = [UIImage imageNamed:@"text_input_resize_indicator"];
        resizeKnobImageView.userInteractionEnabled = YES;
        resizeKnobImageView.tag = FTKnobPositionLeft;
        resizeKnobImageView.backgroundColor = [UIColor clearColor];
        resizeKnobImageView.hidden = NO;
        [self addSubview:resizeKnobImageView];
        self.layer.borderColor = [[UIColor blackColor] colorWithAlphaComponent:0.05f].CGColor;
        
        NSString *backgroundColorString = [[NSUserDefaults standardUserDefaults] stringForKey:@"text_background_color"];
        if(nil == backgroundColorString || [backgroundColorString isEqualToString:[[UIColor clearColor] hexStringFromColor]]) {
            
        }
        else {
            [self.textView setTextBackgroundColor:[UIColor colorWithHexString:backgroundColorString]];
        }
        self.layer.borderWidth = 4.0f;
    }
    return self;
}

- (void)dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)layoutSubviews{
    [super layoutSubviews];
	textView.frame = CGRectIntegral(CGRectIntegral(self.bounds));

    CGRect frame = resizeKnobImageView.frame;
    frame.origin.x = CGRectGetWidth(self.bounds) - CGRectGetWidth(frame);
    frame.origin.y = CGRectGetHeight(self.bounds) - CGRectGetHeight(frame);
    resizeKnobImageView.frame = frame;
}

-(void)setZoomScale:(CGFloat)scale
{
    if(zoomScale != scale)
    {        
        self.transform = CGAffineTransformIdentity;
        
        CGRect newFrame = CGRectScale(self.frame, 1/zoomScale);
        newFrame = CGRectScale(newFrame, scale);

        if(self.representedObject)
        {
            newFrame = CGRectScale(self.representedObject.boundingRect, scale);
        }

        [self setFrame:newFrame];
        [self layoutIfNeeded];
        zoomScale = scale;

        [textView applyScale:zoomScale];
        textView.attributedString = textView.attributedString;
    }
}
#pragma mark -
#pragma mark Public Methods

-(void)saveToDatabase{
    //NSLog(@"saveActiveText");
    isRepositionedAfterSave = NO;
    
	if ([self.textView isEmpty])  {
        [delegate flexibleTextViewDidChange:self];
	}
    else
    {
        if (!self.representedObject) {
            //Get a new textEntryManagedObject
            [delegate flexibleTextViewCreateManagedObject:self];
        }else{
            [delegate flexibleTextViewDidChange:self];
        }
    }
}

#pragma mark -
#pragma mark Getters / Setters
-(BOOL)editMode{
	return textView.userInteractionEnabled;
}

-(void)setEditMode:(BOOL)newEditMode{
	
    if(newEditMode == textView.userInteractionEnabled) {
        return;
    }
    if (newEditMode) {
        //NSLog(@"%d Entering setEditMode YES", debuggingRandomID);
    }else{
        //NSLog(@"%d Entering setEditMode NO", debuggingRandomID);
    }
    
    
	if (newEditMode) {
		textView.userInteractionEnabled = YES;
		textView.autocorrectionType = UITextAutocorrectionTypeYes;
		[textView becomeFirstResponder];
        self.selected = YES;
	}else {
		textView.autocorrectionType = UITextAutocorrectionTypeNo;
        textView.userInteractionEnabled = NO;
        [textView resignFirstResponder];
        self.selected = NO;
        [self.inputAccessoryViewController dismissPopoverViews];
        if(isRepositionedAfterSave)
        {
            [self saveToDatabase];
        }
    }
}


-(void)setSelected:(BOOL)isSelected{
	
    selected = isSelected;
    [self setNeedsDisplay];
}

-(void)setEditable:(BOOL)editable
{
    self.userInteractionEnabled=editable;
}

-(CGRect)currentCursorPosition
{
    return [textView currentCursorPosition];
}

#pragma mark -
#pragma mark TextView Delegate

- (void)textViewDidBeginEditing:(NSNotification*)notification
{
    [self validateKeyboard];
    [self performSelector:@selector(scrollToEditingPoint) withObject:nil afterDelay:0.4];
}

- (void)textViewDidEndEditing:(NSNotification*)notification
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self saveToDatabase];
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView
{
    self.editMode = NO;

    return YES;
}

- (void)textViewDidChange:(NSNotification*)notification
{
	[self resizeTextViewAsNeeded];
    
//    if(self.representedObject && [delegate flexibleTextViewShouldSaveRealtime] && ![self.textView.attributedString isEqualToAttributedText:self.representedObject.attributedString])
    {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(saveTextEntryTemporarly) object:nil];
        [self performSelector:@selector(saveTextEntryTemporarly) withObject:nil afterDelay:2];
    }
}

static int counter = 0;
-(void)textViewDidChangeSelection:(UITextView *)inTextView
{
    CGRect rect = [self currentCursorPosition];
    //added below condition as due to internal layout issue in ios 10, the textview will take bit time to reset its caret rect.
    if(INFINITY == CGRectGetMinY(rect) && counter < 5) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(),^{
                           // Recall
                           counter++;
                           [self textViewDidChangeSelection:inTextView];
                       });
    }
    else {
        counter = 0;
        [self scrollToEditingPoint];
        [self validateKeyboard];
    }
}

-(void)validateKeyboard
{
    UITextView *inTextView = self.textView.textInputView;
    NSRange selectedRange = inTextView.selectedRange;
    NSDictionary *typingAttributes = inTextView.typingAttributes;
    if(selectedRange.length > 0)
    {
        typingAttributes = [inTextView.textStorage attributesAtIndex:selectedRange.location effectiveRange:nil];
    }
    [self.inputAccessoryViewController validateKeyboardWithAttributes:typingAttributes scale:self.textView.textInputView.scale];
}

#if SUPPORTS_BULLETS
-(BOOL)textView:(UITextView *)inTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    //Remove any submenu's in toolbar
    BOOL returnValue = YES;
    
    if ([text isEqualToString:@"\n"])
    {
        if([self.textView.textInputView hasBulletsInLineParagraphForRange:inTextView.selectedRange]) {
            returnValue =  [inTextView autoContinueBulletsForEditingRange:inTextView.selectedRange scale:self.zoomScale*self.textView.textInputView.transformScale];
        }
        else {
// Commented as no need to set default font for new line
            
//            UIFont *defaultFont = [self defaultTextFont];
//            NSRange paragraphRange = [inTextView.attributedText.string paragraphRangeForRange:range];
//            NSInteger length = NSMaxRange(paragraphRange) - range.location;
//            if(length == 1) {
//                [self.textView.textInputView setValue:[defaultFont fontWithSize:defaultFont.pointSize*self.zoomScale]
//                                         forAttribute:NSFontAttributeName inRange:NSMakeRange(range.location, 1)];
//            }
//            [self.textView.textInputView setValue:[defaultFont fontWithSize:defaultFont.pointSize*self.zoomScale]
//                                     forAttribute:NSFontAttributeName inRange:range];
        }
    }
    if ([text isEqualToString:@"\t"])
    {
        returnValue = [inTextView increaseIndentationForcibly:NO
                                               editingRange:inTextView.selectedRange
                                                      scale:self.zoomScale*self.textView.textInputView.transformScale];
    }
    if ([text isEqualToString:@""] && (range.length <= 1 || [inTextView shouldConsiderForDecrementIndentationOnDeleting:range scale:self.zoomScale*self.textView.textInputView.transformScale]))
    {
        returnValue = [inTextView decreaseIndentationForcibly:NO
                                                    editingRange:inTextView.selectedRange
                                                           scale:self.zoomScale*self.textView.textInputView.transformScale];
    }
    
    return returnValue;
}

- (BOOL)textView:(UITextView *)inTextView shouldInteractWithTextAttachment:(NSTextAttachment *)textAttachment inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction
{
    return [self textStorage:inTextView.textStorage shouldInteractWithTextAttachment:textAttachment inRange:characterRange];
}

-(BOOL)textStorage:(NSTextStorage*)textStorage shouldInteractWithTextAttachment:(NSTextAttachment *)textAttachment inRange:(NSRange)characterRange
{
    float scale = self.zoomScale*self.textView.textInputView.transformScale;
    
    NSTextAttachment *checkBoxOffAttachment = [[NSTextAttachment alloc] init];
    checkBoxOffAttachment.image = [UIImage imageNamed:@"check-off-2x.png"];
    [checkBoxOffAttachment updateFileWrapperIfNeeded];
    checkBoxOffAttachment.bounds = CGRectMake(0, CHECK_BOX_OFFSET_Y, CHECKBOX_WIDTH, CHECKBOX_HEIGHT);
    checkBoxOffAttachment.bounds = CGRectScale(checkBoxOffAttachment.bounds, scale);
    
    NSTextAttachment *checkBoxonAttachment = [[NSTextAttachment alloc] init];
    checkBoxonAttachment.image = [UIImage imageNamed:@"check-on-2x.png"];
    [checkBoxonAttachment updateFileWrapperIfNeeded];
    checkBoxonAttachment.bounds = CGRectMake(0, CHECK_BOX_OFFSET_Y, CHECKBOX_WIDTH, CHECKBOX_HEIGHT);
    checkBoxonAttachment.bounds = CGRectScale(checkBoxonAttachment.bounds, scale);
    
    NSData *contents = [textAttachment.fileWrapper regularFileContents];
    
    NSData *checkOnData = checkBoxonAttachment.fileWrapper.regularFileContents;
    NSData *checkOffData = checkBoxOffAttachment.fileWrapper.regularFileContents;
    if(nil == checkOnData || nil == checkOffData) {
        [UIAlertController showAlertForiOS12TextAttachmentIssue];
        return NO;
    }
    
    BOOL isSameAsCheckOff = [contents isEqualToData:checkOffData];
    BOOL isSameAsCheckOn = [contents isEqualToData:checkOnData];
    
    if (contents && !isSameAsCheckOff && !isSameAsCheckOn)
    {
        //isEqualToData is not working always, if isEqualToData fails checking UIImagePNGRepresentation
        NSData *contentInfo = UIImagePNGRepresentation([UIImage imageWithData:contents]);
        NSData *checkOnContentInfo = UIImagePNGRepresentation([UIImage imageWithData:checkOnData]);
        NSData *checkOffContentInfo = UIImagePNGRepresentation([UIImage imageWithData:checkOffData]);
        
        isSameAsCheckOff = [contentInfo isEqualToData:checkOffContentInfo];
        isSameAsCheckOn = [contentInfo isEqualToData:checkOnContentInfo];
    }
    
    //since in iOS12 there was an issue where the textattachment was not stored properly and the file wrapper for new textattachment creation was not having file wrapper as a work around we are depending on the data size to determine the type of check box.
    if (contents && !isSameAsCheckOff && !isSameAsCheckOn)
    {
        NSInteger contentLength = contents.length;
        if(contentLength <= checkOffData.length) {
            isSameAsCheckOff = true;
        }
        else if(contentLength > checkOffData.length && contentLength <= (checkOnData.length + 10)) {
            isSameAsCheckOn = true;
        }
    }
    
    if(isSameAsCheckOff)
    {
        NSAttributedString *str = [NSAttributedString attributedStringWithAttachment:checkBoxonAttachment];
        
        NSMutableDictionary *attrs = [[textStorage attributesAtIndex:characterRange.location effectiveRange:nil] mutableCopy];
        [attrs removeObjectForKey:NSAttachmentAttributeName];
        
        [textStorage beginEditing];
        [textStorage replaceCharactersInRange:characterRange withAttributedString:str];
        [textStorage addAttributes:attrs range:characterRange];
        [textStorage endEditing];
    }
    else if(isSameAsCheckOn)
    {
        NSAttributedString *str = [NSAttributedString attributedStringWithAttachment:checkBoxOffAttachment];
        NSMutableDictionary *attrs = [[textStorage attributesAtIndex:characterRange.location effectiveRange:nil] mutableCopy];
        [attrs removeObjectForKey:NSAttachmentAttributeName];
        
        [textStorage beginEditing];
        [textStorage replaceCharactersInRange:characterRange withAttributedString:str];
        [textStorage addAttributes:attrs range:characterRange];
        [textStorage endEditing];
    }
    return NO;
}

#endif


#pragma mark -
#pragma mark Touch Handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    
    if(touches.allObjects.count > 1)
        return;
    
    isScaling = NO;
    isMoving = NO;

    //******************************
    // Make sure the text is in the current orientation
    // else prompt to rotate
    //******************************
    self.textView.textInputView.isMoving = false;

    //Double tap to enter edit mode
    if ([[[touches allObjects] objectAtIndex:0] tapCount] >= 2) {
        self.editMode = YES;
        return;
	}
	
    //******************************
    //Single tap for selection moving and scaling
    //******************************
    
    //If not selected - select and return
    
    if (!self.selected) {
        self.selected = YES;
        [delegate flexibleTextViewBecameActive:self];
        return;
    }

    // If touch in scaling hotspot - start scaling - else, start moving
    UIView *hitView =  [self hitTest:[[touches anyObject] locationInView:self] withEvent:event];
    if(nil != hitView)
    {
        NSInteger tag = hitView.tag;
        if(tag == FTKnobPositionLeft || tag == FTKnobPositionRight)
        {
            isScaling = YES;
            isMoving = NO;
        }
        else
        {
            isScaling = NO;
            isMoving = YES;
        }
    }
    
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
	
    if(touches.allObjects.count > 1)
        return;

	if (isMoving){
		
        CGFloat xOffset = [[[touches allObjects] objectAtIndex:0] previousLocationInView:self].x - [[[touches allObjects] objectAtIndex:0] locationInView:self].x;
        CGFloat yOffset = [[[touches allObjects] objectAtIndex:0] previousLocationInView:self].y - [[[touches allObjects] objectAtIndex:0] locationInView:self].y;
        
        
        CGPoint newOrigin;
        newOrigin = CGPointMake(self.frame.origin.x - xOffset, self.frame.origin.y - yOffset);

        CGRect frameToSet = CGRectMake(newOrigin.x, newOrigin.y, self.frame.size.width, self.frame.size.height);
        frameToSet.origin = [self adjustFrameOriginWithinBoundary:frameToSet];
        self.textView.textInputView.isMoving = true;
        self.frame = frameToSet;

        isRepositionedAfterSave = YES;
	}
	
	if (isScaling) {
		
        CGPoint prevPoint = [[[touches allObjects] objectAtIndex:0] previousLocationInView:self];
        CGPoint currentPoint = [[[touches allObjects] objectAtIndex:0] locationInView:self];
        
		CGFloat xOffset = prevPoint.x - currentPoint.x;
        CGFloat yOffset = prevPoint.y - currentPoint.y;
		
		CGSize newSize;
        CGPoint newOrigin = self.frame.origin;

        newSize = CGSizeMake(self.frame.size.width - xOffset,self.frame.size.height-yOffset);

        CGSize minSize = [self minSizeToFit];
        newSize.height = MAX(minSize.height, newSize.height);

        isRepositionedAfterSave = YES;
        CGRect frameToSet = CGRectMake(newOrigin.x, newOrigin.y, MAX(newSize.width, 100), newSize.height);
        frameToSet.origin = [self adjustFrameOriginWithinBoundary:frameToSet];
        self.frame = frameToSet;
        
		[self setNeedsLayout];
		[self setNeedsDisplay];
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
	
    if(touches.allObjects.count > 1)
        return;
    
	if (isScaling) {
		[self resizeTextViewAsNeeded];
	}
	
    self.textView.textInputView.isMoving = false;
    isMoving = NO;
	isScaling = NO;
    
    if(!self.editMode)
        [self saveTextEntryAttributes];
    [self performSelector:@selector(scrollToEditingPoint) withObject:nil afterDelay:0.4];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event{
	
    if(touches.allObjects.count > 1)
        return;

    if (isScaling) {
		[self resizeTextViewAsNeeded];
	}
	
    self.textView.textInputView.isMoving = false;
    isMoving = NO;
	isScaling = NO;

    if([delegate respondsToSelector:@selector(flexibleTextViewDidCancel:)])
    {
        [delegate flexibleTextViewDidCancel:self];
    }
}

-(CGPoint)adjustFrameOriginWithinBoundary:(CGRect)frame
{
    CGPoint newOrigin = frame.origin;
    //Always keep the textbox position at least 40px inside the writing area
    CGRect windowBounds = self.superview.bounds;
    CGFloat maxWidth = CGRectGetWidth(windowBounds);
    CGFloat maxHeight = CGRectGetHeight(windowBounds);
    if (newOrigin.x > (maxWidth -40)) {
        newOrigin.x = (maxWidth -40);
    }
    
    if (newOrigin.y > (maxHeight -40)) {
        newOrigin.y = (maxHeight -40);
    }
    
    if (newOrigin.x < -frame.size.width + 40) {
        newOrigin.x = -frame.size.width + 40;
    }
    
    if (newOrigin.y < -frame.size.height + 40) {
        newOrigin.y = -frame.size.height + 40;
    }
    return newOrigin;
}

#pragma mark -
#pragma mark Helpers
-(void)scrollToEditingPoint{
    //Bring the current editing area to view if needed
    
    //The text view may have residged first responder already
    //This can happen becasue this nmethod is being called from a dalayed selector
    if (!textView.textInputView.isFirstResponder) {
        return;
    }
	[delegate flexibleTextView:self requestsRectToVisibile:self.currentCursorPosition];
}

-(void)resizeTextViewAsNeeded
{
    CGSize minSize = [self minSizeToFit];

	CGFloat newWidth = MAX((textView.textInputView.frame.size.width), self.bounds.size.width);

	CGFloat newHeight = MAX((textView.textInputView.textUsedSize.height*textView.textInputView.scale), minSize.height);
    newHeight = MAX(self.bounds.size.height, newHeight);
    
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, newWidth, newHeight);
}

-(void)saveTextEntryTemporarly
{
    [self saveTextEntryAttributes];
}

-(void)saveTextEntryAttributes
{
    [delegate flexibleTextViewDidChange:self];
}

-(CGSize)minSizeToFit
{
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:@"W" attributes:[NSDictionary dictionaryWithObjectsAndKeys:[self defaultTextFont],NSFontAttributeName, nil]];
    
    UIEdgeInsets textContainerInset = self.textView.textInputView.textContainerInset;
    CGSize minSize = CGSizeScale(attributedString.size, self.zoomScale);
    minSize.height += (textContainerInset.top +  textContainerInset.bottom);
    minSize.width += (textContainerInset.left +  textContainerInset.right);
    return minSize;
}

#pragma mark -
#pragma mark Button Actions
-(NSUndoManager*)undoManager
{
    return textView.textInputView.undoManager;
}

#pragma mark FTTextINputAccessoryDelegate
- (void)textInputAccessoryDidChangeTextAlignment:(NSTextAlignment)textAlignment
{
    [self.textView setTextAlignment:textAlignment];
    [self saveTextEntryTemporarly];
    [self validateKeyboard];
}

-(void)textInputAccessoryDidToggleUnderline
{
    NSRange selectedRange = self.textView.textInputView.selectedRange;
    NSNumber *underlineStyle = (NSNumber*)[self.textView.textInputView attribute:NSUnderlineStyleAttributeName inRange:selectedRange];
    if(underlineStyle.integerValue == 0) {
        [self.textView.textInputView setValue:[NSNumber numberWithInteger:NSUnderlineStyleSingle] forAttribute:NSUnderlineStyleAttributeName inRange:selectedRange];
    }
    else {
        [self.textView.textInputView setValue:nil forAttribute:NSUnderlineStyleAttributeName inRange:selectedRange];
    }
    [self validateKeyboard];
}

-(void)textInputAccessoryDidChangeFontTrait:(UIFontDescriptorSymbolicTraits)trait
{
    NSRange selectedRange = self.textView.textInputView.selectedRange;

    UIFont *font = (UIFont*)[self.textView.textInputView attribute:NSFontAttributeName inRange:selectedRange];
    
    BOOL removeTrait = false;
    
    if(trait == UIFontDescriptorTraitItalic) {
        if(font.isItalic) {
            removeTrait = true;
        }
    }
    else if(trait == UIFontDescriptorTraitBold) {
        if(font.isBoldTrait) {
            removeTrait = true;
        }
    }
    
    if(selectedRange.length == 0) {
        UIFont *fontToApply = [self.textView.textInputView.typingAttributes objectForKey:NSFontAttributeName];
        if(removeTrait) {
            fontToApply = [fontToApply removeTrait:trait];
        }
        else {
            fontToApply = [fontToApply addTrait:trait];
        }
        [self.textView.textInputView setValue:fontToApply forAttribute:NSFontAttributeName inRange:selectedRange];
    }
    else {
        [self.textView.textInputView.textStorage beginEditing];
        [self.textView.textInputView.textStorage enumerateAttribute:NSFontAttributeName inRange:selectedRange options:0 usingBlock:^(UIFont *currentFont, NSRange range, BOOL * _Nonnull stop) {
            UIFont *fontToApply = currentFont;
            if(removeTrait) {
                fontToApply = [fontToApply removeTrait:trait];
            }
            else {
                fontToApply = [fontToApply addTrait:trait];
            }
            [self.textView.textInputView setValue:fontToApply forAttribute:NSFontAttributeName inRange:range];
        }];
    }
    [self.textView.textInputView.textStorage endEditing];
    [self validateKeyboard];
}

- (void)textInputAccessoryDidChangeIndent:(enum FTTextInputIndent)indent
{
    switch (indent) {
        case FTTextInputIndentLeft:
        {
            [self.textView decreaseIndent];
        }
            break;
        case FTTextInputIndentRight:
        {
            [self.textView increaseIndent];
        }
            break;
    }
    [self saveTextEntryTemporarly];
}

- (void)textInputAccessoryDidChangeStyle:(UIFont * _Nonnull)styleFont
{
    [self.textView setFontStyle:styleFont];
    [self saveTextEntryTemporarly];
    [self validateKeyboard];
}
- (void)textInputAccessoryDidChangeFontFamily:(NSString * _Nonnull)fontFamily
{
    NSAttributedString *currentString = self.textView.attributedString;
    NSRange selectedRange = self.textView.textInputView.selectedRange;
    // IF TO APPLY CHANGE TO ENTIRE CURSOR's LINE
    
    //    if(selectedRange.length == 0){
    //        selectedRange = [self.textView.textInputView.text paragraphRangeForRange:selectedRange];
    //    }
    if(selectedRange.length == 0) {
        NSDictionary *typingAttributes = self.textView.textInputView.typingAttributes;
        UIFont *currentFont = typingAttributes[NSFontAttributeName];
        if(nil != currentFont) {
            UIFontDescriptor *descriptpr = [[UIFontDescriptor alloc] init];
            descriptpr = [descriptpr fontDescriptorWithFamily:fontFamily];
            UIFont *newFont = [UIFont fontWithDescriptor:descriptpr size:currentFont.pointSize];
            if(currentFont.isBoldTrait) {
                newFont = [newFont addTrait:UIFontDescriptorTraitBold];
            } 
            if(currentFont.isItalic) {
                newFont = [newFont addTrait:UIFontDescriptorTraitItalic];
            }
            [self.textView setFontStyle:newFont inRange:selectedRange];
        }
    }
    else {
        [currentString enumerateAttribute:NSFontAttributeName inRange:selectedRange
                                  options:0
                               usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
            UIFont *currentFont = (UIFont *)value;
            
            UIFontDescriptor *descriptpr = [[UIFontDescriptor alloc] init];
            descriptpr = [descriptpr fontDescriptorWithFamily:fontFamily];
            UIFont *newFont = [UIFont fontWithDescriptor:descriptpr size:currentFont.pointSize*self.zoomScale];
            if(currentFont.isBoldTrait) {
                newFont = [newFont addTrait:UIFontDescriptorTraitBold];
            }
            if(currentFont.isItalic) {
                newFont = [newFont addTrait:UIFontDescriptorTraitItalic];
            }
            [self.textView setFontStyle:newFont inRange:range];
        }];
        
    }
    
    [self saveTextEntryTemporarly];
    [self validateKeyboard];
}
- (void)textInputAccessoryDidChangeFontFamilyStyle:(NSString * _Nonnull)fontFamilyStyle
{
    NSRange selectedRange = self.textView.textInputView.selectedRange;

// IF TO APPLY CHANGE TO ENTIRE CURSOR's LINE
    
//    if(selectedRange.length == 0){
//        selectedRange = [self.textView.textInputView.text paragraphRangeForRange:selectedRange];
//    }
    if(selectedRange.length == 0) {
        NSDictionary *typingAttributes = self.textView.textInputView.typingAttributes;
        UIFont *currentFont = typingAttributes[NSFontAttributeName];
        if(nil != currentFont) {
            UIFontDescriptor *fontDescriptor = [currentFont.fontDescriptor fontDescriptorByAddingAttributes:@{UIFontDescriptorNameAttribute : fontFamilyStyle}];
            UIFont *newFont = [UIFont fontWithDescriptor:fontDescriptor size:currentFont.pointSize];
            [self.textView setFontStyle:newFont inRange:selectedRange];
        }
    }
    else
    {
        NSMutableAttributedString *newAttributedString = [[NSMutableAttributedString alloc] initWithAttributedString:self.textView.attributedString];
        [newAttributedString enumerateAttribute:NSFontAttributeName
                                        inRange:selectedRange
                                        options:0 usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
            UIFont *currentFont = (UIFont *)value;
            UIFontDescriptor *fontDescriptor = [currentFont.fontDescriptor fontDescriptorByAddingAttributes:@{UIFontDescriptorNameAttribute : fontFamilyStyle}];
            UIFont *newFont = [UIFont fontWithDescriptor:fontDescriptor size:currentFont.pointSize*self.zoomScale];
            [self.textView setFontStyle:newFont inRange:range];
        }];
    }
    [self saveTextEntryTemporarly];
    [self validateKeyboard];
}

- (void)textInputAccessoryDidChangeTextSize:(CGFloat)textSize{
    [self textInputAccessoryDidChangeTextSize:textSize canUndo:TRUE];
}
- (void)textInputAccessoryDidChangeTextSize:(CGFloat)textSize canUndo:(BOOL)canUndo{
    NSAttributedString *currentString = self.textView.attributedString;
    NSRange selectedRange = self.textView.textInputView.selectedRange;
    if(selectedRange.length == 0) {
        NSDictionary *typingAttributes = self.textView.textInputView.typingAttributes;
        UIFont *currentFont = typingAttributes[NSFontAttributeName];
        if(nil != currentFont) {
            UIFont *newFont = [currentFont fontWithSize:textSize];
            [self.textView setFontStyle:newFont inRange:selectedRange];
        }
    }
    else
    {
        [currentString enumerateAttribute:NSFontAttributeName inRange:self.textView.textInputView.selectedRange
                                  options:0
                               usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
            UIFont *currentFont = (UIFont *)value;
            
            UIFont *newFont = [currentFont fontWithSize:textSize];
            [self.textView setFontStyle:newFont inRange:range];
        }];
    }
    if(canUndo){
        [self saveTextEntryTemporarly];
        [self validateKeyboard];
    }
}

- (void)textInputAccessoryDidChangeTextColor:(UIColor *)textColor{
    [self.textView setTextColor:textColor inRange:self.textView.textInputView.selectedRange];
    [self saveTextEntryTemporarly];
}
-(void)textInputAccessoryDidChangeColor:(UIColor *)backgroundColor
{
    [self.textView setTextBackgroundColor:backgroundColor];
    [self saveTextEntryTemporarly];
}

-(void)textInputAccessoryDidChangeBullet:(FTBulletType)bulletStyle
{
    [self.textView insertBullet:nil type:bulletStyle];
    [self validateKeyboard];
}

-(void)textInputAccessoryDidChangeFavoriteFont:(FTCustomFontInfo*)fontInfo
{
    [self.textView setTextColor:fontInfo.textColor inRange:self.textView.textInputView.selectedRange];
    
    NSRange selectedRange = self.textView.textInputView.selectedRange;
    if(selectedRange.length == 0) {
        NSDictionary *typingAttributes = self.textView.textInputView.typingAttributes;
        UIFont *currentFont = typingAttributes[NSFontAttributeName];
        if(nil != currentFont) {
            UIFontDescriptor *fontDescriptor = [[UIFontDescriptor alloc] init];
            fontDescriptor = [fontDescriptor fontDescriptorWithFamily:fontInfo.fontName];
            fontDescriptor = [fontDescriptor fontDescriptorByAddingAttributes:@{UIFontDescriptorNameAttribute : fontInfo.fontStyle}];
            UIFont *newFont = [UIFont fontWithDescriptor:fontDescriptor size:fontInfo.fontSize*self.zoomScale];
            if(fontInfo.isBold) {
                newFont = [newFont addTrait:UIFontDescriptorTraitBold];
            }
            if(fontInfo.isItalic) {
                newFont = [newFont addTrait:UIFontDescriptorTraitItalic];
            }
            if(fontInfo.isUnderlined) {
                [self.textView.textInputView setValue:[NSNumber numberWithInteger:NSUnderlineStyleSingle] forAttribute:NSUnderlineStyleAttributeName inRange:selectedRange];
            }
            else{
                [self.textView.textInputView setValue:nil forAttribute:NSUnderlineStyleAttributeName inRange:selectedRange];
            }
            [self.textView setFontStyle:newFont inRange:selectedRange];
        }
    }
    else
    {
        NSMutableAttributedString *newAttributedString = [[NSMutableAttributedString alloc] initWithAttributedString:self.textView.attributedString];
        [newAttributedString enumerateAttribute:NSFontAttributeName
                                        inRange:selectedRange
                                        options:0
                                     usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
//            UIFont *currentFont = (UIFont *)value;
            UIFontDescriptor *fontDescriptor = [[UIFontDescriptor alloc] init];
            fontDescriptor = [fontDescriptor fontDescriptorWithFamily:fontInfo.fontName];
            fontDescriptor = [fontDescriptor fontDescriptorByAddingAttributes:@{UIFontDescriptorNameAttribute : fontInfo.fontStyle}];
            UIFont *newFont = [UIFont fontWithDescriptor:fontDescriptor size:fontInfo.fontSize*self.zoomScale];
            if(fontInfo.isBold) {
                newFont = [newFont addTrait:UIFontDescriptorTraitBold];
            }
            if(fontInfo.isItalic) {
                newFont = [newFont addTrait:UIFontDescriptorTraitItalic];
            }
            if(fontInfo.isUnderlined) {
                [self.textView.textInputView setValue:[NSNumber numberWithInteger:NSUnderlineStyleSingle] forAttribute:NSUnderlineStyleAttributeName inRange:selectedRange];
            }else {
                [self.textView.textInputView setValue:nil forAttribute:NSUnderlineStyleAttributeName inRange:selectedRange];
            }
            [self.textView setFontStyle:newFont inRange:range];
        }];
    }
    
    
    [self saveTextEntryTemporarly];
    [self validateKeyboard];
   
}

- (void)textInputAccessoryShouldNotResignFirstResponder {
    shouldResign = NO;
}

-(UIFont*)defaultTextFont
{
    return [[self.textView.textInputView defaultAttributes] objectForKey:NSFontAttributeName];
}

-(UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *hittest = [super hitTest:point withEvent:event];
    if(CGRectContainsPoint(CGRectInset(resizeKnobImageView.frame, -10, -10), point)) {
        hittest = resizeKnobImageView;
    }
    return hittest;
}
-(void)changeFontSizeTo:(CGFloat)textSize andTextColor:(UIColor *)textColor andFontType:(BOOL)isDefault{
    [self.textView setTextColor:textColor inRange:self.textView.textInputView.selectedRange];
    if (isDefault){
        [self textInputAccessoryDidChangeTextSize:textSize canUndo:TRUE];
    }
    else{
        [self textInputAccessoryDidChangeTextSize:textSize canUndo:FALSE];

        NSAttributedString *attributedString = self.textView.attributedString;
        UIEdgeInsets textContainerInset = self.textView.textInputView.textContainerInset;
        CGSize minSize = CGSizeScale(attributedString.size, self.zoomScale);
        minSize.height += (textContainerInset.top +  textContainerInset.bottom);
        minSize.width += (textContainerInset.left +  textContainerInset.right);
        
        CGRect windowBounds = self.superview.bounds;
        CGFloat maxWidth = CGRectGetWidth(windowBounds) - self.frame.origin.x;
        minSize.width = MIN(minSize.width, maxWidth);//Max width for textView in canvas
        
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, MAX(minSize.width, self.textView.textInputView.frame.size.width), self.textView.textInputView.frame.size.height);
        [self saveTextEntryTemporarly];
        [self validateKeyboard];
    }
}
@end
