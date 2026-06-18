//
//  TableViewCellWithSwitch.m
//  zxtouch
//
//  Created by Jason on 2021/1/20.
//

#import "TableViewCellWithSwitch.h"

@implementation TableViewCellWithSwitch

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
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setTitleText:(NSString *)title {
    self.title.text = title;
}


- (void)setBtnInitStatus:(BOOL)status {
    [_switchBtn setOn:status animated:NO];
}




@end

