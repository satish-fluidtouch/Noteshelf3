//
//  StickersView.m
//  Noteshelf
//
//  Created by Rama Krishna on 8/17/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "StickerSelectionView.h"
#import "UIImageAdditions.h"
#import "DataServices.h"

#import "UIButtonAdditions.h"
#import "FTEmojiCharManager.h"
#import "Noteshelf-Swift.h"

@protocol FTEmojiCollectionViewCellDelegate <NSObject>

-(void)collectionViewCell:(UICollectionViewCell*)cell didTappedOnEmojiTag:(NSInteger)tag;

@end

@interface FTEmojiCollectionViewCell : UICollectionViewCell

@property (strong) UIButton *emojiButton;
@property (nonatomic, weak) id<FTEmojiCollectionViewCellDelegate> delegate;

-(void)setRow:(NSUInteger)row section:(NSUInteger)section;

@end

@interface StickerSelectionView () <UICollectionViewDataSource,UICollectionViewDelegate,FTEmojiCollectionViewCellDelegate>

-(void)loadStickersScrollView;
-(void)changeStickersPage;

@property (nonatomic, strong) UIScrollView *stickersScrollView;
@property (nonatomic, strong) UIPageControl *pageControl;


@property (nonatomic, strong) NSMutableArray *emojiSectionCollectionViews;

@end


@implementation StickerSelectionView

@synthesize delegate, panelState, categoryLabels;

@synthesize stickersScrollView, pageControl;

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self loadSubViews];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        [self loadSubViews];
    }
    return self;
}

- (void)layoutSubviews {
    self.stickersScrollView.contentSize = CGSizeMake(CGRectGetWidth(self.stickersScrollView.bounds)*[[FTEmojiCharManager sharedInstance] numberOfSections], stickersScrollView.bounds.size.height);
}

#pragma mark - Custom
- (void)loadSubViews {    
    self.rackContentView = [[UIView alloc] initWithFrame:self.bounds];
    self.rackContentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:self.rackContentView];
    
    [self loadStickersScrollView];
}

-(void)loadStickersScrollView{
	
	//Setup the scroll view
	stickersScrollView = [[UIScrollView alloc] initWithFrame:self.rackContentView.bounds];
	stickersScrollView.pagingEnabled = YES;
	stickersScrollView.showsHorizontalScrollIndicator = NO;
	stickersScrollView.showsVerticalScrollIndicator = NO;
	stickersScrollView.scrollsToTop = NO;
	stickersScrollView.delegate = self;
    stickersScrollView.contentSize = CGSizeMake(CGRectGetWidth(self.stickersScrollView.bounds)*[[FTEmojiCharManager sharedInstance] numberOfSections], stickersScrollView.bounds.size.height);
    stickersScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.rackContentView addSubview:stickersScrollView];
    
	//Setup the page control
	pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.rackContentView.bounds) - 30, CGRectGetWidth(self.rackContentView.bounds), 30)];
	pageControl.numberOfPages = [[FTEmojiCharManager sharedInstance] numberOfSections];
    pageControl.pageIndicatorTintColor = [UIColor colorNamed:@"titleColor"];
    pageControl.currentPageIndicatorTintColor = [UIColor colorNamed:@"toolSizeColor"];
	pageControl.currentPage = 0;
	[pageControl addTarget:self action:@selector(changeStickersPage) forControlEvents:UIControlEventValueChanged];
    pageControl.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    [self.rackContentView addSubview:pageControl];
    
    //This is not needed but just in case
    if (categoryLabels) {
        self.categoryLabels = nil;
    }
    
    categoryLabels = [[NSMutableArray alloc] init];
    self.emojiSectionCollectionViews = [NSMutableArray array];
    
    NSInteger sections = [[FTEmojiCharManager sharedInstance] numberOfSections];
    for (NSInteger i = 0; i < sections; i++)
    {
        CGRect frame = self.stickersScrollView.frame;
        CGFloat x = i * CGRectGetWidth(frame) + 35;
        CGFloat width = frame.size.width - 70;
        
        FTStyledLabel *stampsCategoryLabel = [[FTStyledLabel alloc] initWithFrame:CGRectMake(x, 8, width, 20)];
        stampsCategoryLabel.textColor = [UIColor colorNamed:@"headerColor"];
        stampsCategoryLabel.backgroundColor = [UIColor clearColor];
        stampsCategoryLabel.style = FTLabelStyleStyle5;
        stampsCategoryLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
        stampsCategoryLabel.styleText = [[FTEmojiCharManager sharedInstance] sectionTitleForSection:i];
        [stickersScrollView addSubview:stampsCategoryLabel];
        [categoryLabels addObject:stampsCategoryLabel];

        frame.origin.x = x;
        frame.origin.y = CGRectGetMaxY(stampsCategoryLabel.frame) + 10;
        frame.size.width = width;
        frame.size.height -= frame.origin.y + 30;
        
        UICollectionViewFlowLayout *layout=[[UICollectionViewFlowLayout alloc] init];
        [layout setItemSize:CGSizeMake(31, 31)];
        [layout setMinimumInteritemSpacing:23];
        [layout setMinimumLineSpacing:15];
        [layout setSectionInset:UIEdgeInsetsZero];
        
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:frame collectionViewLayout:layout];
        collectionView.backgroundColor = [UIColor colorNamed:@"lightTitleColor_70"];
        
        collectionView.delegate = self;
        collectionView.dataSource = nil;
        [self.emojiSectionCollectionViews addObject:collectionView];
        [collectionView registerClass:[FTEmojiCollectionViewCell class] forCellWithReuseIdentifier:@"collectionViewIdentifier"];
        collectionView.backgroundColor = [UIColor clearColor];
        collectionView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleRightMargin;
        [stickersScrollView addSubview:collectionView];
    }
    [self loadPage:0];
    [self loadPage:1];

    [self setNeedsLayout];
}

-(void)loadPage:(NSInteger)pageIndex
{
    if(pageIndex < 0 || pageIndex >= (int)[self.emojiSectionCollectionViews count])
        return;
    
    UICollectionView *collectionView = [self.emojiSectionCollectionViews objectAtIndex:(uint)pageIndex];
    if(collectionView.dataSource == nil)
    {
        collectionView.dataSource = self;
        [collectionView reloadData];
    }
}

#pragma mark scroll view delegate
-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    CGFloat pageWidth = stickersScrollView.bounds.size.width;
    int pageIndex = ((int)floor((self.stickersScrollView.contentOffset.x - pageWidth / 2.f) / pageWidth) + 1);
    
    if(scrollView == self.stickersScrollView)
    {
        [self setScrollEnabledAllTableViews:NO];
        
        [self loadPage:pageIndex-1];
        [self loadPage:pageIndex];
        [self loadPage:pageIndex+1];
    }
    else
        [self.stickersScrollView setScrollEnabled:NO];
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self setScrollEnabledAllTableViews:YES];
    [self.stickersScrollView setScrollEnabled:YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)sender{
    // Switch the indicator when more than 50% of the previous/next page is visible
    CGFloat pageWidth = stickersScrollView.bounds.size.width;
    int page = floor((stickersScrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    pageControl.currentPage = page;
}

-(void)setScrollEnabledAllTableViews:(BOOL)enabled
{
    for(UICollectionView *collectionView in self.emojiSectionCollectionViews)
        [collectionView setScrollEnabled:enabled];
}

#pragma mark collection view datasource
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSInteger collectionIndex = [self.emojiSectionCollectionViews indexOfObject:collectionView];
    return [[FTEmojiCharManager sharedInstance] numberOfEmojisInSection:collectionIndex];
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    FTEmojiCollectionViewCell *cell = (FTEmojiCollectionViewCell*)[collectionView dequeueReusableCellWithReuseIdentifier:@"collectionViewIdentifier" forIndexPath:indexPath];
    
    NSUInteger page = [self.emojiSectionCollectionViews indexOfObject:collectionView];
    [cell setRow:indexPath.row section:page];
    cell.delegate = self;
    
    return cell;
}

#pragma mark cell delegate
-(void)collectionViewCell:(UICollectionViewCell*)cell didTappedOnEmojiTag:(NSInteger)tag;
{
    FTEmojiCollectionViewCell *emojiCell = (FTEmojiCollectionViewCell*)cell;
    NSString *emojiText = emojiCell.emojiButton.titleLabel.text;
    [[FTEmojiCharManager sharedInstance] addEmojiToRecent:emojiText];
    [delegate stickerSelected:[[FTEmojiCharManager sharedInstance] imageForEmojiString:emojiText size:32]
                      emojiID:emojiText.hash];
}

#pragma mark - 
-(void)changeStickersPage{
	
	NSInteger page = pageControl.currentPage;
	
	// update the scroll view to the appropriate page
    CGRect frame = stickersScrollView.bounds;
    frame.origin.x = frame.size.width * page;
    frame.origin.y = 0;
    [stickersScrollView scrollRectToVisible:frame animated:YES];
}


-(void)stickerButtonTapped:(UIButton *)stickerButton
{
    NSString *emojiText = stickerButton.titleLabel.text;
    [delegate stickerSelected:[[FTEmojiCharManager sharedInstance] imageForEmojiString:emojiText size:32]
                      emojiID:emojiText.hash];
    [self animateStickersView:kStickersPanelHide];
    [[FTEmojiCharManager sharedInstance] addEmojiToRecent:emojiText];
}

-(void)animateStickersView:(RKStickersPanelAnimation)animationType{
	
	if (animationType == kStickersPanelShowFull && !stickersScrollView) {
		[self loadStickersScrollView];
	}
	
    CGRect contentViewFrame = self.rackContentView.frame;
    
	[UIView animateWithDuration:0.3 animations:^{
        CGFloat yPosition = -10;
        if (contentViewFrame.size.height > CGRectGetHeight(self.bounds))
        {
            yPosition =  CGRectGetHeight(self.bounds)-contentViewFrame.size.height;
        }
        self.rackContentView.frame = CGRectMake( contentViewFrame.origin.x, yPosition, contentViewFrame.size.width, contentViewFrame.size.height);
        
        [UIView setAnimationDuration:0.5];
        self.userInteractionEnabled = YES;
        
        panelState = animationType;
    } completion:^(BOOL finished)
    {
        if (panelState == kStickersPanelHide)
        {
            [self.stickersScrollView removeFromSuperview];
            self.stickersScrollView = nil;
            [self.pageControl removeFromSuperview];
            self.pageControl = nil;
            self.emojiSectionCollectionViews = nil;
        }
        if (panelState == kStickersPanelShowFull) {
            [self setNeedsLayout];
        }
    }];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
	
	//Ignore the touch if it is on the stickers panel
	CGPoint currentTouchPosition = [[touches anyObject] locationInView:self];
	
	CGRect targetRect = CGRectInset(self.rackContentView.frame, 38, 18);
	
	if (CGRectContainsPoint(targetRect, currentTouchPosition)){
		return;
	}
	
	//Just hide the panel if it is open
	if (panelState != kStickersPanelHide) {
		[self animateStickersView:kStickersPanelHide];
		return;
	}
}

@end

@implementation FTEmojiCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.emojiButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.emojiButton.showsTouchWhenHighlighted = YES;
        self.emojiButton.frame = self.bounds;
        self.emojiButton.titleLabel.font = [UIFont fontWithName:@"Apple Color Emoji" size:31];
        [self addSubview:self.emojiButton];
        [self.emojiButton addTarget:self action:@selector(didTapped:) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

-(void)layoutSubviews
{
    self.emojiButton.frame = self.bounds;
}

-(void)setRow:(NSUInteger)row section:(NSUInteger)section
{
    NSString *character = [[FTEmojiCharManager sharedInstance] emojiAtRow:row andSection:section];
    [self.emojiButton setTitle:character forState:UIControlStateNormal];
}

-(void)didTapped:(id)sender
{
    [self.delegate collectionViewCell:self didTappedOnEmojiTag:self.tag];
}
@end
