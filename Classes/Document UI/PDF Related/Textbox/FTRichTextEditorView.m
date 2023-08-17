//
//  FTRichTextEditorView.m
//  Noteshelf
//
//  Created by Amar Udupa on 27/5/13.
//
//

#import "FTRichTextEditorView.h"
#import <CoreText/CoreText.h>
#import "UIColorAdditions.h"
#import <QuartzCore/QuartzCore.h>
#import "Noteshelf-Swift.h"
#import "UITextView_BulletsAndIndentation.h"
#import "NSAttributedString_Extended.h"
#import "FTBulletsConstants.h"
#import "FTTextList.h"

@interface FTRichTextEditorView()

@property (weak)     FTTextView *textInputView;
@property (strong,readwrite) FTFontStyles *fontStyles;

@end

@implementation FTRichTextEditorView

@synthesize textInputView = _textInputView;

- (id)initWithFrame:(CGRect)frame
           delegate:(id)delegate
  annotationVersion:(NSInteger)version
     transformScale:(CGFloat)transformScale
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
        self.clipsToBounds = NO;

        self.fontStyles = [[FTFontStyles alloc] init];

        FTTextView *inputView = [[FTTextView alloc] initWithFrame:self.bounds
                                         annotationVersion:version
                                            transformScale:transformScale];
        _textInputView = inputView;
        _textInputView.delegate = delegate;
        _textInputView.attributedText = [[NSAttributedString alloc] initWithString:@""];
        _textInputView.scrollEnabled = NO;
        //[_textInputView setValue:self.fontStyles.bodyFont forAttribute:NSFontAttributeName inRange:_textInputView.selectedRange];
        [_textInputView setValue:[FTCustomFontManager shared].defaultBodyFont forAttribute:NSFontAttributeName inRange:_textInputView.selectedRange];
        [self addSubview:_textInputView];
    }
    return self;
}

#pragma mark instance method
-(void)setTextAlignment:(NSTextAlignment)allignment
{
    [self.textInputView setTextAlignment:allignment forEditingRange:self.textInputView.selectedRange];
}

-(void)setFontStyle:(UIFont*)fontStyle
{
    fontStyle = [UIFont fontWithName:fontStyle.fontName size:fontStyle.pointSize];
    NSRange selectedRange = [[self textInputView] selectedRange];
    [self.textInputView setValue:fontStyle forAttribute:NSFontAttributeName inRange:selectedRange];
}
-(void)setFontStyle:(UIFont*)fontStyle inRange:(NSRange)range{
    [self.textInputView setValue:fontStyle forAttribute:NSFontAttributeName inRange:range];
}
-(void)increaseIndent
{
    [self.textInputView increaseIndentationForcibly:true editingRange:[self textInputView].selectedRange scale:self.textInputView.scale*self.textInputView.transformScale];
}

-(void)decreaseIndent
{
    [self.textInputView decreaseIndentationForcibly:true editingRange:[self textInputView].selectedRange scale:self.textInputView.scale*self.textInputView.transformScale];
}
-(void)setTextColor:(UIColor *)textColor inRange:(NSRange)range
{
    [self.textInputView setValue:textColor forAttribute:NSForegroundColorAttributeName inRange:range];
}

-(void)setTextBackgroundColor:(UIColor *)inBackgroundColor
{
    [self.textInputView setValue:inBackgroundColor forAttribute:NSBackgroundColorAttributeName inRange:NSMakeRange(0, self.textInputView.attributedText.length)];
    [self.textInputView setValue:inBackgroundColor forAttribute:NSBackgroundColorAttributeName inRange:NSMakeRange(0, 0)];
    self.textInputView.backgroundColor = inBackgroundColor;
}

#pragma mark -
#pragma mark autocorrection
#pragma mark -

-(UITextAutocorrectionType)autocorrectionType
{
    return _textInputView.autocorrectionType;
}

-(void)setAutocorrectionType:(UITextAutocorrectionType)autocorrectionType
{
    self.textInputView.autocorrectionType = autocorrectionType;
}

#pragma mark -
#pragma mark attributed string
#pragma mark -
-(BOOL)isEmpty
{
    if([self.textInputView.attributedText.string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length > 0) {
        return false;
    }
    return true;
}

-(NSAttributedString*)attributedString
{
    NSMutableAttributedString *attr = [self.textInputView.attributedText mutableDeepCopy];
    [attr applyScale:1/self.textInputView.scale originalScaleToApply:1*self.textInputView.transformScale];
    return attr;
}

-(void)setAttributedString:(NSAttributedString*)attributedString
{
    NSMutableAttributedString *str = [[attributedString mapAttributesToMatchWithLineHeight:-1] mutableDeepCopy];    
    [str applyScale:self.textInputView.scale originalScaleToApply:self.textInputView.scale*self.textInputView.transformScale];
    self.textInputView.attributedText = str;
    self.textInputView.backgroundColor = (UIColor*)[self.textInputView attribute:NSBackgroundColorAttributeName inRange:NSMakeRange(0, 0)];
    if(attributedString.length > 0 && self.textInputView.selectedRange.location == attributedString.length) {
        UIFont *font = [str attribute:NSFontAttributeName atIndex:attributedString.length-1 effectiveRange:nil];
        if(nil != font) {
            [self.textInputView setValue:font forAttribute:NSFontAttributeName inRange:self.textInputView.selectedRange];
        }
    }
}

#pragma mark applyScale
-(void)applyScale:(CGFloat)scale
{
    [_textInputView setScale:scale];
}

#pragma mark UIResponder

- (BOOL)becomeFirstResponder
{
    return [_textInputView becomeFirstResponder];
}

-(BOOL)resignFirstResponder
{
    [super resignFirstResponder];
    return [_textInputView resignFirstResponder];
}

-(BOOL)isFirstResponder
{
    return [_textInputView isFirstResponder];
}

#pragma mark helper methods
-(CGRect)currentCursorPosition
{
   return [_textInputView boundsOfRange:_textInputView.selectedTextRange];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    [self.nextResponder touchesBegan: touches withEvent:event];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    [self.nextResponder touchesMoved: touches withEvent:event];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    [self.nextResponder touchesEnded: touches withEvent:event];
}

#pragma mark -
#pragma mark Bullets
#pragma mark -
-(FTBulletType)currentBulletType
{
    FTBulletType currentType = FTBulletTypeNone;
    NSParagraphStyle *style = [self.textInputView.typingAttributes objectForKey:NSParagraphStyleAttributeName];
    if(style.hasBullet)
    {
        FTTextList *list = [style currentTextListWithScale:self.textInputView.scale*self.textInputView.transformScale];
        if(list)
        {
            if([list.markerFormat isEqualToString:@"{checkbox}"])
            {
                currentType = FTBulletTypeCheckBox;
            }
            else if([list.markerFormat isEqualToString:@"{decimal}"])
            {
                currentType = FTBulletTypeNumbers;
            }
            else
            {
                currentType = FTBulletTypeOne;
            }
        }
    }
    return currentType;
}

-(void)insertBullet:(id)sender type:(FTBulletType)type
{
    if([self currentBulletType] == type) {
        [self removeBullets:nil];
    }
    else {
        switch (type) {
            case FTBulletTypeOne:
            {
                FTTextList *box = [FTTextList textListWithMarkerFormat:@"{disc}" option:0];
#if CIRCLE_DIAMOND
                FTTextList *circle = [FTTextList textListWithMarkerFormat:@"{circle}" option:0];
                FTTextList *diamond = [FTTextList textListWithMarkerFormat:@"{diamond}" option:0];
                [self.textInputView.textView replaceBulletsWithTextLists:@[box,circle,diamond] forRange:self.textInputView.textView.selectedRange];
#else
                FTTextList *hyphen = [FTTextList textListWithMarkerFormat:@"{hyphen}" option:0];
                [self.textInputView replaceBulletsWithTextLists:@[box,hyphen]
                                                       forRange:self.textInputView.selectedRange
                                                          scale:self.textInputView.scale*self.textInputView.transformScale];
#endif
            }
                break;
            case FTBulletTypeTwo:
            {
                FTTextList *box = [FTTextList textListWithMarkerFormat:@"{box}" option:0];
                FTTextList *circle = [FTTextList textListWithMarkerFormat:@"{square}" option:0];
                FTTextList *diamond = [FTTextList textListWithMarkerFormat:@"{octal}" option:0];
                
                [self.textInputView replaceBulletsWithTextLists:@[box,circle,diamond]
                                                       forRange:self.textInputView.selectedRange
                                                          scale:self.textInputView.scale*self.textInputView.transformScale];
            }
                break;
            case FTBulletTypeCheckBox:
            {
                FTTextList *box = [FTTextList textListWithMarkerFormat:@"{checkbox}" option:0];
                [self.textInputView replaceBulletsWithTextLists:@[box]
                                                       forRange:self.textInputView.selectedRange
                                                          scale:self.textInputView.scale*self.textInputView.transformScale];
            }
                break;
            case FTBulletTypeNumbers:
            {
                FTTextList *decimal = [FTTextList textListWithMarkerFormat:@"{decimal}" option:0];
                FTTextList *alpha = [FTTextList textListWithMarkerFormat:@"{upper-alpha}" option:0];
                
                [self.textInputView replaceBulletsWithTextLists:@[decimal,alpha]
                                                       forRange:self.textInputView.selectedRange
                                                          scale:self.textInputView.scale*self.textInputView.transformScale];
            }
                break;
        }
    }
    if([self.textInputView.delegate conformsToProtocol:@protocol(FTTextViewDelegate)]) {
        [(id<FTTextViewDelegate>)self.textInputView.delegate saveTextEntryTemporarly];
    }
}

-(void)removeBullets:(id)sender
{
    [self.textInputView replaceBulletsWithTextLists:nil
                             forRange:self.textInputView.selectedRange
                                scale:self.textInputView.scale*self.textInputView.transformScale];
    if([self.textInputView.delegate conformsToProtocol:@protocol(FTTextViewDelegate)]) {
        [(id<FTTextViewDelegate>)self.textInputView.delegate saveTextEntryTemporarly];
    }
}

@end
