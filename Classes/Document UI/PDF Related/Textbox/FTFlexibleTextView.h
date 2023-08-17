//
//  FTFlexibleTextView.h
//  Noteshelf
//
//  Created by Ashok Prabhu on 23/3/13.
//
//

#define TEXT_AREA_BORDER_SIZE	10

@class FTFlexibleTextView;
@class FTRichTextEditorView;
@class FTTextAnnotation;

@protocol FTFlexibleTextViewDelegate <NSObject>

//Perform action
-(void)flexibleTextViewCreateManagedObject:(FTFlexibleTextView *)flexibleTextView;
-(void)flexibleTextView:(FTFlexibleTextView *)flexibleTextView requestsRectToVisibile:(CGRect)targetRect;

//Notification
-(void)flexibleTextViewBecameActive:(FTFlexibleTextView *)flexibleTextView;
-(void)flexibleTextViewDidChange:(FTFlexibleTextView *)flexibleTextView;

//Get information
-(BOOL)flexibleTextViewShouldSaveRealtime;

@optional
-(void)flexibleTextViewDidCancel:(FTFlexibleTextView *)flexibleTextView;

@end

@interface FTFlexibleTextView : UIView <UITextViewDelegate>

@property (nonatomic, weak) FTRichTextEditorView *textView;

@property (nonatomic, weak) FTTextAnnotation *representedObject;

@property (nonatomic) BOOL editMode;
@property (nonatomic) BOOL selected;
@property (nonatomic, readonly) int debuggingRandomID;
@property (nonatomic) CGFloat zoomScale;

@property (nonatomic, weak) id<FTFlexibleTextViewDelegate> delegate;

- (id)initWithFrame:(CGRect)frame
          zoomScale:(CGFloat)inZoomScale
     textAnnotation:(FTTextAnnotation*)annotation;

-(void)scrollToEditingPoint;

-(void)saveToDatabase;
-(void)setEditable:(BOOL)editable;

-(UIFont*)defaultTextFont;
-(void)changeFontSizeTo:(CGFloat)textSize andTextColor:(UIColor *)textColor andFontType:(BOOL)isDefault;
@end
