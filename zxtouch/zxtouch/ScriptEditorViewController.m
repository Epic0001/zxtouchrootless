//
//  ScriptEditorViewController.m
//  zxtouch
//
//  Created by Jason on 2020/12/17.
//

#import "ScriptEditorViewController.h"

@interface ScriptEditorViewController ()

@end

@implementation ScriptEditorViewController
{
    NSString *currentFilePath;
    BOOL isSaveButtonShown;
    BOOL isApplyingHighlight;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSString* content = [NSString stringWithContentsOfFile:currentFilePath
                                                  encoding:NSUTF8StringEncoding
                                                     error:NULL];
    _textInput.text = content;
    _textInput.font = [UIFont monospacedSystemFontOfSize:14 weight:UIFontWeightRegular];
    _textInput.autocorrectionType = UITextAutocorrectionTypeNo;
    _textInput.autocapitalizationType = UITextAutocapitalizationTypeNone;
    [self applySyntaxHighlightingPreservingSelection:NO];
    isSaveButtonShown = NO;
}

- (void) setFile:(NSString*)file {
    currentFilePath = [file stringByStandardizingPath];
}

- (void) showSaveButton {
    if (!isSaveButtonShown)
    {
        UIBarButtonItem *save = [[UIBarButtonItem alloc] initWithTitle:@"Save"
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(saveFile)];
        
        [self.navigationItem setRightBarButtonItem:save animated:YES];
        isSaveButtonShown = YES;
    }
}

- (void) hideSaveButton {
    if (isSaveButtonShown)
    {
        [self.navigationItem setRightBarButtonItem:nil animated:YES];
        isSaveButtonShown = NO;
    }
}

- (void)textViewDidChange:(UITextView *)textView {
    if (isApplyingHighlight) return;
    [self applySyntaxHighlightingPreservingSelection:YES];
    [self showSaveButton];
}

- (void)applyColor:(UIColor *)color pattern:(NSString *)pattern options:(NSRegularExpressionOptions)options inString:(NSString *)content attributedString:(NSMutableAttributedString *)attributed {
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:options error:&error];
    if (error) return;

    NSRange fullRange = NSMakeRange(0, content.length);
    [regex enumerateMatchesInString:content options:0 range:fullRange usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        if (result.range.location != NSNotFound && NSMaxRange(result.range) <= attributed.length) {
            [attributed addAttribute:NSForegroundColorAttributeName value:color range:result.range];
        }
    }];
}

- (void)applySyntaxHighlightingPreservingSelection:(BOOL)preserveSelection {
    NSString *content = _textInput.text ?: @"";
    NSString *extension = [[currentFilePath pathExtension] lowercaseString];
    NSRange selectedRange = _textInput.selectedRange;
    UIColor *baseColor = UIColor.labelColor ?: UIColor.blackColor;
    UIFont *font = _textInput.font ?: [UIFont monospacedSystemFontOfSize:14 weight:UIFontWeightRegular];
    NSMutableAttributedString *highlighted = [[NSMutableAttributedString alloc] initWithString:content attributes:@{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: baseColor
    }];

    if ([extension isEqualToString:@"py"]) {
        [self applyColor:[UIColor systemGreenColor] pattern:@"#.*$" options:NSRegularExpressionAnchorsMatchLines inString:content attributedString:highlighted];
        [self applyColor:[UIColor systemRedColor] pattern:@"(@?\\\"\\\"\\\"[\\s\\S]*?\\\"\\\"\\\"|@?'''[\\s\\S]*?'''|\\\"([^\\\"\\\\]|\\\\.)*\\\"|'([^'\\\\]|\\\\.)*')" options:0 inString:content attributedString:highlighted];
        [self applyColor:[UIColor systemPurpleColor] pattern:@"\\b(False|None|True|and|as|assert|async|await|break|class|continue|def|del|elif|else|except|finally|for|from|global|if|import|in|is|lambda|nonlocal|not|or|pass|raise|return|try|while|with|yield)\\b" options:0 inString:content attributedString:highlighted];
        [self applyColor:[UIColor systemOrangeColor] pattern:@"\\b[0-9]+(\\.[0-9]+)?\\b" options:0 inString:content attributedString:highlighted];
    } else if ([extension isEqualToString:@"raw"]) {
        [self applyColor:[UIColor systemBlueColor] pattern:@"^\\d{2}" options:NSRegularExpressionAnchorsMatchLines inString:content attributedString:highlighted];
        [self applyColor:[UIColor systemOrangeColor] pattern:@"\\b\\d+(\\.\\d+)?\\b" options:0 inString:content attributedString:highlighted];
    } else if ([extension isEqualToString:@"md"] || [extension isEqualToString:@"markdown"]) {
        [self applyColor:[UIColor systemPurpleColor] pattern:@"^#{1,6} .*$" options:NSRegularExpressionAnchorsMatchLines inString:content attributedString:highlighted];
        [self applyColor:[UIColor systemBlueColor] pattern:@"`[^`]+`" options:0 inString:content attributedString:highlighted];
        [self applyColor:[UIColor systemGreenColor] pattern:@"\\[[^\\]]+\\]\\([^\\)]+\\)" options:0 inString:content attributedString:highlighted];
    }

    isApplyingHighlight = YES;
    _textInput.attributedText = highlighted;
    if (preserveSelection && NSMaxRange(selectedRange) <= _textInput.text.length) {
        _textInput.selectedRange = selectedRange;
    }
    isApplyingHighlight = NO;
}

- (void) saveFile {
    NSError *err = nil;
    [[_textInput text] writeToFile:currentFilePath atomically:YES encoding:NSUTF8StringEncoding error:&err];
    
    if (err)
    {
        NSLog(@"Error while saving file. Error: %@", err);
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error"
                                       message:[NSString stringWithFormat:@"Error saving file. Error message: %@", err]
                                       preferredStyle:UIAlertControllerStyleAlert];
         
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
           handler:^(UIAlertAction * action) {}];
         
        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
    [self hideSaveButton];
}

@end
