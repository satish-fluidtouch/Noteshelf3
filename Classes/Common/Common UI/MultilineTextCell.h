//
//  TaskNameCell.h
//  All My Days
//
//  Created by Rama Krishna on 1/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#define GROUP_NAME_ROW_TAG		100
#define GROUP_NAPKIN_ROW_TAG	101
#define GROUP_PASSWORD_ROW_TAG	102
#define UNGROUP_TAG             103
#define REMOVE_PASSWORD         104

@class FTStyledLabel;

@interface MultilineTextCell : UITableViewCell

@property (nonatomic, strong) FTStyledLabel *captionLabel;
@property (nonatomic, strong) FTStyledLabel *contentLabel;
@property (nonatomic, strong) UIImageView *contentImageView;

-(void)getHeight;

@end
