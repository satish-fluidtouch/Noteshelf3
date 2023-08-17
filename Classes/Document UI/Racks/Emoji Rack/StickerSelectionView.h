//
//  StickersView.h
//  Noteshelf
//
//  Created by Rama Krishna on 8/17/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

typedef enum {
	kStickersPanelShowRecent,
	kStickersPanelShowFull,
	kStickersPanelHide
} RKStickersPanelAnimation;


@protocol StickerSelectionDelegate;


@interface StickerSelectionView : UIView <UIScrollViewDelegate>

@property (nonatomic, readonly) RKStickersPanelAnimation panelState;
@property (nonatomic, strong) UIView *rackContentView;

@property (nonatomic, strong) NSMutableArray *categoryLabels;
@property (nonatomic, strong) NSMutableArray *recentButtonsArray;

@property (nonatomic, weak) id <StickerSelectionDelegate> delegate;

-(void)animateStickersView:(RKStickersPanelAnimation)animationType;

@end


@protocol StickerSelectionDelegate <NSObject>

-(void) stickerSelected:(UIImage *)stickerImage emojiID:(NSUInteger)emojiID;

@end
