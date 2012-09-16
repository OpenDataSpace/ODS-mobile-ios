/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is the Alfresco Mobile App.
 *
 * The Initial Developer of the Original Code is Zia Consulting, Inc.
 * Portions created by the Initial Developer are Copyright (C) 2011-2012
 * the Initial Developer. All Rights Reserved.
 *
 *
 * ***** END LICENSE BLOCK ***** */
//
//  SystemNotice.m
//

#import <QuartzCore/QuartzCore.h>

#import "SystemNotice.h"
#import "SystemNoticeGradientView.h"
#import "UILabel+Utils.h"

@interface SystemNotice ()
@property (nonatomic, assign) SystemNoticeType noticeType;
@property (nonatomic, retain) UIView *view;
@property (nonatomic, strong) UIView *noticeView;
@property (nonatomic, retain) UILabel *titleLabel;
@property (nonatomic, retain) UILabel *messageLabel;
@end

@implementation SystemNotice

CGFloat hiddenYOrigin;

@synthesize view = _view;
@synthesize noticeType = _noticeType;
@synthesize noticeView = _noticeView;
@synthesize titleLabel = _titleLabel;
@synthesize messageLabel = _messageLabel;

@synthesize message = _message;
@synthesize title = _title;
@synthesize duration = _duration;
@synthesize delay = _delay;
@synthesize alpha = _alpha;
@synthesize offsetY = offsetY;

- (void)dealloc
{
    [_noticeView release];
    [_titleLabel release];
    [_messageLabel release];
    
    [_view release];
    [_message release];
    [_title release];
    
    [super dealloc];
}

- (id)initWithView:(UIView *)view
{
    if (self = [super init])
    {
        self.view = view;
    }
    return self;
}

- (void)show
{
    [self createNotice];
    [self displayNotice];
}

- (CGFloat)duration
{
    if (_duration == 0.0)
    {
        _duration = 0.5;
    }
    return _duration;
}

- (CGFloat)delay
{
    if (_delay == 0.0)
    {
        _delay = self.themeDefaultDelay;
    }
    return _delay;
}

- (CGFloat)alpha
{
    if (_alpha == 0.0)
    {
        _alpha = 1.0;
    }
    return _alpha;
}


#pragma mark - Notice Type Theming

- (NSString *)themeIconName
{
    NSString *icon = @"system_notice_info";
    if (self.noticeType == SystemNoticeTypeError)
    {
        icon = @"system_notice_error";
    }
    return icon;
}

- (UIColor *)themeMessageColor
{
    UIColor *color = nil;
    if (self.noticeType == SystemNoticeTypeError)
    {
        color = [UIColor colorWithRed:239.0/255.0 green:167.0/255.0 blue:163.0/255.0 alpha:1.0];
    }
    else
    {
        color = [UIColor colorWithRed:213.0/255.0 green:217.0/255.0 blue:249.0/255.0 alpha:1.0];
    }
    return color;
}

- (SystemNoticeGradientView *)themeGradientViewWithFrame:(CGRect)rect
{
    SystemNoticeGradientView *view = nil;
    if (self.noticeType == SystemNoticeTypeError)
    {
        view = [[[SystemNoticeGradientView alloc] initRedGradientWithFrame:rect] autorelease];
    }
    else
    {
        view = [[[SystemNoticeGradientView alloc] initBlueGradientWithFrame:rect] autorelease];
    }
    return view;
}

- (NSString *)themeDefaultTitle
{
    NSString *title = nil;
    if (self.noticeType == SystemNoticeTypeError)
    {
        title = NSLocalizedString(@"An Error Occurred", @"Default title for error notification");
    }
    return title;
}

- (CGFloat)themeDefaultDelay
{
    CGFloat delay = 1.5;
    if (self.noticeType == SystemNoticeTypeError)
    {
        delay = 8.0;
    }
    return delay;
}

#pragma mark - Create & View methods

- (void)createNotice
{
    // Get the view width, allowing for rotations
    CGRect rotated = CGRectApplyAffineTransform(self.view.frame, self.view.transform);
    
    // Check the notice won't disappear behind the status bar
    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    if (self.view.frame.origin.y < appFrame.origin.y)
    {
        CGRect statusBarFrame = [[UIApplication sharedApplication] statusBarFrame];
        self.offsetY += statusBarFrame.size.height;
    }
    
    CGFloat viewWidth = rotated.size.width;
    
    NSInteger numberOfLines = 1;
    CGFloat messageLineHeight = 30.0;
    CGFloat originY = (self.message) ? 10.0 : 18.0;
    
    self.titleLabel = [[[UILabel alloc] initWithFrame:CGRectMake(55.0, originY, viewWidth - 70.0, 16.0)] autorelease];
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.shadowOffset = CGSizeMake(0.0, -1.0);
    self.titleLabel.shadowColor = [UIColor blackColor];
    self.titleLabel.font = [UIFont boldSystemFontOfSize:14.0];
    self.titleLabel.backgroundColor = [UIColor clearColor];
    self.titleLabel.text = (self.title != nil) ? self.title : self.themeDefaultTitle;
    
    // Message label
    if (self.message)
    {
        self.messageLabel = [[[UILabel alloc] initWithFrame:CGRectMake(55.0, 10.0 + 10.0, viewWidth - 70.0, messageLineHeight)] autorelease];
        self.messageLabel.font = [UIFont systemFontOfSize:13.0];
        self.messageLabel.textColor = self.themeMessageColor;
        self.messageLabel.backgroundColor = [UIColor clearColor];
        self.messageLabel.text = self.message;
        
        // Calculate the number of lines needed to display the text
        numberOfLines = [[self.messageLabel arrayWithLinesOfText] count];
        self.messageLabel.numberOfLines = numberOfLines;
        
        CGRect rect = self.messageLabel.frame;
        rect.origin.y = self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height;
        
        // Prevent UILabel centering the text in the middle
        [self.messageLabel sizeToFit];
        
        // Determine the height of one line of text
        messageLineHeight = self.messageLabel.frame.size.height;
        rect.size.height = self.messageLabel.frame.size.height * numberOfLines;
        rect.size.width = viewWidth - 70.0;
        self.messageLabel.frame = rect;
    }
    
    // Calculate the notice view height
    float noticeViewHeight = 40.0;
    hiddenYOrigin = 0.0;
    if (numberOfLines > 1)
    {
        noticeViewHeight += (numberOfLines - 1) * messageLineHeight;
    }
    
    // Allow for shadow when hiding
    hiddenYOrigin = 0.0 - noticeViewHeight - 20.0;
    
    // Gradient view dependant on notice type
    CGRect gradientRect = CGRectMake(0.0, hiddenYOrigin, viewWidth, noticeViewHeight + 10.0);
    self.noticeView = [self themeGradientViewWithFrame:gradientRect];
    self.noticeView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
    self.noticeView.contentMode = UIViewContentModeRedraw;
    [self.view addSubview:self.noticeView];
    
    // Icon view
    UIImageView *iconView = [[[UIImageView alloc] initWithFrame:CGRectMake(10.0, 10.0, 20.0, 30.0)] autorelease];
    iconView.image = [UIImage imageNamed:self.themeIconName];
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    iconView.alpha = 0.8;
    [self.noticeView addSubview:iconView];
    
    // Title label
    [self.noticeView addSubview:self.titleLabel];
    
    // Message label
    [self.noticeView addSubview:self.messageLabel];
    
    // Drop shadow
    CALayer *noticeLayer = self.noticeView.layer;
    noticeLayer.shadowColor = [[UIColor blackColor]CGColor];
    noticeLayer.shadowOffset = CGSizeMake(0.0, 3);
    noticeLayer.shadowOpacity = 0.50;
    noticeLayer.masksToBounds = NO;
    noticeLayer.shouldRasterize = YES;
    
    // Invisible button to manually dismiss the notice
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0.0, 0.0, self.noticeView.frame.size.width, self.noticeView.frame.size.height);
    [button addTarget:self action:@selector(dismissNotice) forControlEvents:UIControlEventTouchUpInside];
    [self.noticeView addSubview:button];
}

- (void)displayNotice
{
    [UIView animateWithDuration:self.duration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        CGRect newFrame = self.noticeView.frame;
        newFrame.origin.y = self.offsetY;
        self.noticeView.frame = newFrame;
        self.noticeView.alpha = self.alpha;
    } completion:^(BOOL finished){
        [self performSelector:@selector(dismissNotice) withObject:nil afterDelay:self.delay];
    }];
}

- (void)dismissNotice
{
    [self dismissNoticeAnimated:YES];
}

- (void)dismissNoticeAnimated:(BOOL)animated
{
    if (animated)
    {
        [UIView animateWithDuration:self.duration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            CGRect newFrame = self.noticeView.frame;
            newFrame.origin.y = hiddenYOrigin;
            self.noticeView.frame = newFrame;
        } completion:^(BOOL finished){
            [self.noticeView removeFromSuperview];
        }];
    }
    else
    {
        [self.noticeView removeFromSuperview];
    }
}

+ (SystemNotice *)showInformationNoticeInView:(UIView *)view message:(NSString *)message
{
    // We use the title for a simple information message type
    SystemNotice *notice = [SystemNotice systemNoticeOfType:SystemNoticeTypeInformation inView:view message:nil title:message];
    [notice show];
    return notice;
}

+ (SystemNotice *)showInformationNoticeInView:(UIView *)view message:(NSString *)message title:(NSString *)title
{
    SystemNotice *notice =  [SystemNotice systemNoticeOfType:SystemNoticeTypeInformation inView:view message:message title:title];
    [notice show];
    return notice;
}

+ (SystemNotice *)showErrorNoticeInView:(UIView *)view message:(NSString *)message
{
    // An error type without specified title will be given a generic "An Error Occurred" title
    SystemNotice *notice =  [SystemNotice systemNoticeOfType:SystemNoticeTypeError inView:view message:message title:nil];
    [notice show];
    return notice;
}

+ (SystemNotice *)showErrorNoticeInView:(UIView *)view message:(NSString *)message title:(NSString *)title
{
    SystemNotice *notice =  [SystemNotice systemNoticeOfType:SystemNoticeTypeError inView:view message:message title:title];
    [notice show];
    return notice;
}

+ (SystemNotice *)systemNoticeOfType:(SystemNoticeType)type inView:(UIView *)view message:(NSString *)message title:(NSString *)title
{
    SystemNotice *notice =  [[[SystemNotice alloc] initWithView:view] autorelease];
    notice.noticeType = type;
    notice.message = message;
    notice.title = title;
    return notice;
}

@end
