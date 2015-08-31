//
//  TableViewCell.m
//
//  Created by M.Satori on 15.02.04.
//  Copyright (c) 2015 usagimaru.
//

#import "TableViewCell.h"

@interface TableViewCell ()

@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageView;
@property (weak, nonatomic) IBOutlet UILabel *label;

@end

@implementation TableViewCell

- (void)awakeFromNib {
	// Initialization code
	self.thumbnailImageView.alpha = 0.0;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (UIEdgeInsets)layoutMargins
{
	return UIEdgeInsetsZero;
}

- (void)setImage:(UIImage *)image
{
	self.thumbnailImageView.image = image;
	
	if (image) {
		[UIView animateWithDuration:0.25
						 animations:^{
							 
							 self.thumbnailImageView.alpha = 1.0;
						 }
						 completion:^(BOOL finished) {
							 
						 }];
	}
	else {
		self.thumbnailImageView.alpha = 0.0;
	}
}
- (UIImage*)image
{
	return self.thumbnailImageView.image;
}

- (void)setText:(NSString *)text
{
	self.label.text = text;
}
- (NSString*)text
{
	return self.label.text;
}

@end
