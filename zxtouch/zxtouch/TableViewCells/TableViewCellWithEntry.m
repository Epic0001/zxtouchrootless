//
//  TableViewCellWithEntry.m
//  zxtouch
//
//  Created by Jason on 2021/1/20.
//

#import "TableViewCellWithEntry.h"

@implementation TableViewCellWithEntry

- (void)awakeFromNib {
    [super awakeFromNib];
    self.iconView = [[UIImageView alloc] init];
    self.iconView.translatesAutoresizingMaskIntoConstraints = NO;
    self.iconView.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentView addSubview:self.iconView];

    [NSLayoutConstraint activateConstraints:@[
        [self.iconView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
        [self.iconView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [self.iconView.widthAnchor constraintEqualToConstant:24],
        [self.iconView.heightAnchor constraintEqualToConstant:24],
    ]];

    for (NSLayoutConstraint *constraint in self.contentView.constraints) {
        if ((constraint.firstItem == self.title && constraint.firstAttribute == NSLayoutAttributeLeading) ||
            (constraint.secondItem == self.title && constraint.secondAttribute == NSLayoutAttributeLeading)) {
            constraint.constant = 52;
        }
        if (constraint.firstItem == self.subTitle && constraint.firstAttribute == NSLayoutAttributeTrailing) {
            constraint.constant = 14;
        }
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
