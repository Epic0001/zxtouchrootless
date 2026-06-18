//
//  ScriptListTableCell.m
//  zxtouch
//
//  Created by Jason on 2020/12/14.
//

#import "ScriptListTableCell.h"
#import "Socket.h"
#import "Util.h"

@implementation ScriptListTableCell
{
    NSString* filePath;
}

- (UIImage *)symbolNamed:(NSString *)symbolName fallback:(NSString *)fallbackName {
    UIImage *image = nil;
    if (@available(iOS 13.0, *)) {
        image = [UIImage systemImageNamed:symbolName];
    }
    if (!image) {
        image = [UIImage imageNamed:fallbackName];
    }
    return image;
}

- (UIImageView *)activeIconView {
    return self.iconImage ?: self.imageView;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.backgroundColor = [UIColor secondarySystemGroupedBackgroundColor];
    self.contentView.backgroundColor = [UIColor secondarySystemGroupedBackgroundColor];
    self.scriptTitle.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    self.scriptTitle.textColor = [UIColor labelColor];

    UIImageView *icon = [self activeIconView];
    icon.contentMode = UIViewContentModeScaleAspectFit;
    icon.tintColor = [UIColor systemBlueColor];

    UIImage *playImage = [self symbolNamed:@"play.circle.fill" fallback:@"play-icon"];
    [_playButton setBackgroundImage:nil forState:UIControlStateNormal];
    [_playButton setImage:playImage forState:UIControlStateNormal];
    _playButton.tintColor = [UIColor systemGreenColor];
    _playButton.backgroundColor = [UIColor clearColor];

    for (UIView *view in self.contentView.subviews) {
        if ([view isKindOfClass:[UIButton class]] && view != _playButton) {
            UIButton *button = (UIButton *)view;
            [button setTitle:@"" forState:UIControlStateNormal];
            [button setBackgroundImage:nil forState:UIControlStateNormal];
            [button setImage:[self symbolNamed:@"ellipsis.circle" fallback:@"gearshape"] forState:UIControlStateNormal];
            button.tintColor = [UIColor secondaryLabelColor];
            button.backgroundColor = [UIColor clearColor];
        }
    }
}

- (IBAction)playButtonClick:(id)sender {
    Socket *springBoardSocket = [[Socket alloc] init];
    [springBoardSocket connect:@"127.0.0.1" byPort:6000];
    
    [springBoardSocket send:[NSString stringWithFormat:@"19%@", filePath]];
    NSString* result = [springBoardSocket recv:1024];
    if ([result characterAtIndex:0] != '0')
    {
        [Util showAlertBoxWithOneOption:_parentViewController title:@"Error" message:[NSString stringWithFormat:@"Cannot play script. Error: %@", result] buttonString:@"OK"];
    }
    [springBoardSocket close];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) setTitle:(NSString*)title{
    _scriptTitle.text = title;
}

- (void) hideButton{
    [_playButton setHidden:YES];
}

- (void) showButton{
    [_playButton setHidden:NO];
}

- (void) setPropertyWithPath:(NSString*)path{
    filePath = path;
    
    BOOL isDir = NO;
    _scriptTitle.text = [path lastPathComponent];
    [self showButton];

    if ([[path pathExtension] isEqualToString:@"bdl"]) // is script. can play
    {
        NSString *entry = [NSDictionary dictionaryWithContentsOfFile:[path stringByAppendingPathComponent:@"info.plist"]][@"Entry"];
        NSString *entryExtension = [[entry pathExtension] lowercaseString];
        UIImage *icon = nil;
        UIColor *tint = [UIColor systemBlueColor];
        if ([entryExtension isEqualToString:@"raw"]) {
            icon = [self symbolNamed:@"waveform.path.ecg" fallback:@"script-icon"];
            tint = [UIColor systemOrangeColor];
        } else if ([entryExtension isEqualToString:@"py"]) {
            icon = [self symbolNamed:@"chevron.left.forwardslash.chevron.right" fallback:@"script-icon"];
            tint = [UIColor systemBlueColor];
        } else {
            icon = [self symbolNamed:@"play.square.stack" fallback:@"script-icon"];
        }
        [[self activeIconView] setImage:icon];
        [self activeIconView].tintColor = tint;
        
        return;
    }
    
    [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
    [self hideButton];

    if (!isDir)
    {
        NSString *extension = [[path pathExtension] lowercaseString];
        if ([extension isEqualToString:@"py"]) {
            [[self activeIconView] setImage:[self symbolNamed:@"chevron.left.forwardslash.chevron.right" fallback:@"normal-file-icon"]];
            [self activeIconView].tintColor = [UIColor systemBlueColor];
        } else if ([extension isEqualToString:@"raw"]) {
            [[self activeIconView] setImage:[self symbolNamed:@"waveform.path.ecg" fallback:@"normal-file-icon"]];
            [self activeIconView].tintColor = [UIColor systemOrangeColor];
        } else if ([extension isEqualToString:@"md"] || [extension isEqualToString:@"markdown"]) {
            [[self activeIconView] setImage:[self symbolNamed:@"doc.richtext" fallback:@"normal-file-icon"]];
            [self activeIconView].tintColor = [UIColor systemPurpleColor];
        } else {
            [[self activeIconView] setImage:[self symbolNamed:@"doc" fallback:@"normal-file-icon"]];
            [self activeIconView].tintColor = [UIColor secondaryLabelColor];
        }
    }
    else
    {
        [[self activeIconView] setImage:[self symbolNamed:@"folder.fill" fallback:@"folder-icon"]];
        [self activeIconView].tintColor = [UIColor systemBlueColor];
    }
}

@end
