//
//  TaskNameCell.m
//  All My Days
//
//  Created by Rama Krishna on 1/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MultilineTextCell.h"
#import "Noteshelf-Swift.h"

@implementation MultilineTextCell

@synthesize captionLabel, contentLabel, contentImageView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
		
        captionLabel = [[FTStyledLabel alloc] initWithFrame:CGRectMake(0, 0, 100, 50)];
		captionLabel.backgroundColor = [UIColor clearColor];
        captionLabel.style = FTLabelStyleStyle7;
		captionLabel.textColor = [UIColor colorNamed:@"headerColor"];
		captionLabel.adjustsFontSizeToFitWidth = YES;
		[self.contentView addSubview:captionLabel];
		
		contentLabel = [[FTStyledLabel alloc] initWithFrame:CGRectMake(0, 0, 300, 50)];
		contentLabel.backgroundColor = [UIColor clearColor];
        contentLabel.style = FTLabelStyleStyle7;
        contentLabel.textAlignment = NSTextAlignmentRight;
		contentLabel.textColor = [UIColor blackColor];
		contentLabel.adjustsFontSizeToFitWidth = YES;
		contentLabel.numberOfLines = 0;
		[self.contentView addSubview:contentLabel];
        
        contentImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        [self.contentView addSubview:contentImageView];
		
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
	
	captionLabel.frame = CGRectMake(16, 8, 110, self.contentView.bounds.size.height - 16);

    if(self.accessoryType != UITableViewCellAccessoryNone)
    {   contentLabel.frame = CGRectMake(CGRectGetMaxX(captionLabel.frame), 8, self.contentView.bounds.size.width-CGRectGetMaxX(captionLabel.frame), self.contentView.bounds.size.height - 16);
        contentImageView.frame = CGRectMake(self.contentView.bounds.size.width - 100, 8, 100, 28);
    }
    else
    {    contentLabel.frame = CGRectMake(CGRectGetMaxX(captionLabel.frame), 8, self.contentView.bounds.size.width-CGRectGetMaxX(captionLabel.frame)-10-8, self.contentView.bounds.size.height - 16);
        contentImageView.frame = CGRectMake(self.contentView.bounds.size.width - 100 - 10-8, 8, 100, 28);
    }
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    
    [super setSelected:selected animated:animated];
	
	
//    if (selected) {
//		captionLabel.textColor = [UIColor whiteColor];
//		contentLabel.textColor = [UIColor whiteColor];
//	}else {
//		captionLabel.textColor = [UIColor colorWithRed:0.0 green:66.0/255.0 blue:129.0/255.0 alpha:1.0];
//		contentLabel.textColor = [UIColor blackColor];
//	}

	
}

-(void)getHeight{
	
}


@end
