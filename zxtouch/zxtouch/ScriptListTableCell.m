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

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
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
        if ([entryExtension isEqualToString:@"raw"]) {
            icon = [self symbolNamed:@"waveform.path.ecg" fallback:@"script-icon"];
        } else if ([entryExtension isEqualToString:@"py"]) {
            icon = [self symbolNamed:@"chevron.left.forwardslash.chevron.right" fallback:@"script-icon"];
        } else {
            icon = [UIImage imageNamed:@"script-icon"];
        }
        [[self imageView] setImage:icon];
        if (@available(iOS 13.0, *)) {
            [self imageView].tintColor = [UIColor systemBlueColor];
        }
        
        return;
    }
    
    [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
    [self hideButton];

    if (!isDir)
    {
        NSString *extension = [[path pathExtension] lowercaseString];
        if ([extension isEqualToString:@"py"]) {
            [[self imageView] setImage:[self symbolNamed:@"chevron.left.forwardslash.chevron.right" fallback:@"normal-file-icon"]];
        } else if ([extension isEqualToString:@"raw"]) {
            [[self imageView] setImage:[self symbolNamed:@"waveform.path.ecg" fallback:@"normal-file-icon"]];
        } else if ([extension isEqualToString:@"md"] || [extension isEqualToString:@"markdown"]) {
            [[self imageView] setImage:[self symbolNamed:@"doc.richtext" fallback:@"normal-file-icon"]];
        } else {
            [[self imageView] setImage:[UIImage imageNamed:@"normal-file-icon"]];
        }
    }
    else
    {
        [[self imageView] setImage:[UIImage imageNamed:@"folder-icon"]];
    }
}

@end
