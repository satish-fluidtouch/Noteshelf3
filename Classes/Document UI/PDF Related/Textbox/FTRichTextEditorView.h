//
//  FTRichTextEditorView.h
//  Noteshelf
//
//  Created by Amar Udupa on 27/5/13.
//
//

#import "FTTextView.h"
#import "FTBulletsConstants.h"

@protocol FTTextViewDelegate <NSObject>

-(void)saveTextEntryTemporarly;

@end

@class FTFontStyles;

@interface FTRichTextEditorView : UIView

@property (readonly,weak)     FTTextView *textInputView;

@property(nonatomic) UITextAutocorrectionType autocorrectionType;         // default is UITextAutocorrectionTypeDefault
@property (strong,readonly) FTFontStyles *fontStyles;

- (id)initWithFrame:(CGRect)frame
           delegate:(id<UITextViewDelegate,FTTextViewDelegate>)delegate
  annotationVersion:(NSInteger)version
     transformScale:(CGFloat)transformScale;

-(void)setAttributedString:(NSAttributedString*)attributedString;
-(NSAttributedString*)attributedString;
-(BOOL)isEmpty;

-(void)setTextBackgroundColor:(UIColor*)backgroundColor;
-(void)setTextColor:(UIColor *)textColor inRange:(NSRange)range;

-(void)increaseIndent;
-(void)decreaseIndent;
-(void)insertBullet:(id)sender type:(FTBulletType)type;
-(void)setTextAlignment:(NSTextAlignment)textAlignment;
-(void)setFontStyle:(UIFont*)fontStyle;
-(void)setFontStyle:(UIFont*)fontStyle inRange:(NSRange)range;

-(CGRect)currentCursorPosition;
-(void)applyScale:(CGFloat)scale;

@end
