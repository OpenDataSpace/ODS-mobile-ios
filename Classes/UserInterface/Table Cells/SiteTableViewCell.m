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
 *
 * ***** END LICENSE BLOCK ***** */
//
//  SiteTableViewCell.m
//

#import "SiteTableViewCell.h"
#import "RepositoryItem.h"

#define BUTTON_LEFT_MARGIN 10.0
#define BUTTON_SPACING 25.0

NSString * const kSiteTableViewCellIdentifier = @"SiteTableViewCell";
CGFloat kSiteTableViewCellUnexpandedHeight = 60.0f;
CGFloat kSiteTableViewCellExpandedHeight = 120.0f;

@interface SiteTableViewCell ()
@property (nonatomic, retain) NSDictionary *allAvailableActions;
@property (nonatomic, retain) NSMutableArray *siteActions;
@property (nonatomic, retain) NSMutableArray *siteActionButtons;
@property (nonatomic, retain) UIImage *accessoryDownImage;
@property (nonatomic, retain) UIImage *accessoryUpImage;
@property (nonatomic, retain) UIView *expandView;
@end

@implementation SiteTableViewCell

@synthesize delegate = _delegate;
@synthesize expanded = _expanded;
@synthesize isFavorite = _isFavorite;
@synthesize isMember = _isMember;
@synthesize site = _site;
@synthesize allAvailableActions = _allAvailableActions;
@synthesize siteActions = _siteActions;
@synthesize siteActionButtons = _siteActionButtons;
@synthesize accessoryDownImage = _accessoryDownImage;
@synthesize accessoryUpImage = _accessoryUpImage;
@synthesize expandView = _expandView;

- (void)dealloc
{
    _delegate = nil;
    
    [_allAvailableActions release];
    [_siteActions release];
    [_siteActionButtons release];
    [_site release];
    [_accessoryDownImage release];
    [_accessoryUpImage release];
    [_expandView release];
    
    [super dealloc];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self)
    {
        // Avoid property setter
        _expanded = NO;
        
        // Accessory images
        self.accessoryDownImage = [UIImage imageNamed:@"accessory-down"];
        self.accessoryUpImage = [UIImage imageNamed:@"accessory-up"];
        
        // Default subviews
        self.textLabel.shadowColor = [UIColor clearColor];
        self.imageView.image = [UIImage imageNamed:@"site"];
        [self setAccessoryView:[self makeSiteDetailDisclosureButton]];
        [self setSelectionStyle:UITableViewCellSelectionStyleBlue];
        
        // Expanded view background
        UIView *expandView = [[[UIView alloc] initWithFrame:CGRectMake(0, kSiteTableViewCellUnexpandedHeight, self.frame.size.width, kSiteTableViewCellUnexpandedHeight)] autorelease];
        [expandView setBackgroundColor:[UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0]];
        self.expandView = expandView;
        
        // Add shadow to expanded view
        UIImage *shadow = [[UIImage imageNamed:@"site-actions-inner-shadow"] stretchableImageWithLeftCapWidth:0 topCapHeight:0];
        UIImageView *shadowImageView = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, expandView.frame.size.width, expandView.frame.size.height)] autorelease];
        shadowImageView.alpha = 0.6;
        shadowImageView.image = shadow;
        shadowImageView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [expandView addSubview:shadowImageView];

        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] init];
        tapGestureRecognizer.numberOfTapsRequired = 1;
        tapGestureRecognizer.cancelsTouchesInView = YES;
        tapGestureRecognizer.delegate = self;
        [expandView addGestureRecognizer:tapGestureRecognizer];
        [tapGestureRecognizer release];
        
        [self addSubview:expandView];
        [self setClipsToBounds:YES];
        [self setAutoresizesSubviews:NO];

        self.allAvailableActions = [NSDictionary dictionaryWithObjectsAndKeys:
                [NSDictionary dictionaryWithObjectsAndKeys:@"Favorite", @"title", @"site-favorite-off", @"image", nil], @"favorite",
                [NSDictionary dictionaryWithObjectsAndKeys:@"Unfavorite", @"title", @"site-favorite-on", @"image", nil], @"unfavorite",
                [NSDictionary dictionaryWithObjectsAndKeys:@"Join", @"title", @"site-member-off", @"image", nil], @"join",
                [NSDictionary dictionaryWithObjectsAndKeys:@"Request to Join", @"title", @"site-member-off", @"image", nil], @"requestJoin",
                [NSDictionary dictionaryWithObjectsAndKeys:@"Leave", @"title", @"site-member-on", @"image", nil], @"leave",
                nil];
        self.siteActions = [[NSMutableArray alloc] initWithCapacity:self.allAvailableActions.count];
        self.siteActionButtons = [[NSMutableArray alloc] initWithCapacity:self.allAvailableActions.count];
    }
    return self;
}

- (void)prepareForReuse
{
    self.site = nil;
    self.expanded = NO;
    [self.siteActions removeAllObjects];
    [self.siteActionButtons removeAllObjects];
    
    for (UIView *view in self.expandView.subviews)
    {
        if ([view isKindOfClass:UIButton.class])
        {
            [view removeFromSuperview];
        }
    }

    [super prepareForReuse];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGFloat y = (kSiteTableViewCellUnexpandedHeight - 1) / 2.0f;
    self.textLabel.center = CGPointMake(self.textLabel.center.x, y);
    self.imageView.center = CGPointMake(self.imageView.center.x, y);
    self.accessoryView.center = CGPointMake(self.frame.size.width - 20.0f, y);
    self.selectedBackgroundView.frame = CGRectMake(0, 0, self.frame.size.width, kSiteTableViewCellUnexpandedHeight);
}

- (UIButton *)makeSiteDetailDisclosureButton
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setFrame:CGRectMake(0, 0, 30, 44)];
    [button setImage:self.accessoryDownImage forState:UIControlStateNormal];
    [button setAdjustsImageWhenHighlighted:NO];
    return button;
}

- (void)setSite:(RepositoryItem *)site
{
    [_site autorelease];
    _site = [site retain];
    
    self.textLabel.text = site.title;
    [self setupSiteActions];
}

- (void)setIsFavorite:(BOOL)isFavorite
{
    _isFavorite = isFavorite;
    [self setupSiteActions];
}

- (void)setIsMember:(BOOL)isMember
{
    _isMember = isMember;
    [self setupSiteActions];
}

- (void)setExpanded:(BOOL)expanded
{
    if (_expanded != expanded)
    {
        [(UIButton *)self.accessoryView setImage:(expanded ? self.accessoryUpImage : self.accessoryDownImage) forState:UIControlStateNormal];
        _expanded = expanded;
    }
}

- (CGFloat)cellHeight
{
    return kSiteTableViewCellUnexpandedHeight + (self.expanded ? kSiteTableViewCellUnexpandedHeight : 0);
}

- (void)setupSiteActions
{
    [self.siteActions removeAllObjects];

    // Favorite/unfavorite
    [self.siteActions addObject:[self.allAvailableActions objectForKey:(self.isFavorite ? @"unfavorite" : @"favorite")]];
    
    if (self.isMember)
    {
        [self.siteActions addObject:[self.allAvailableActions objectForKey:@"leave"]];
    }
    else
    {
        NSString *visibility = [self.site.metadata objectForKey:@"visibility"];
        if ([visibility isEqualToCaseInsensitiveString:@"PUBLIC"])
        {
            [self.siteActions addObject:[self.allAvailableActions objectForKey:@"join"]];
        }
        else if ([visibility isEqualToCaseInsensitiveString:@"MODERATED"])
        {
            [self.siteActions addObject:[self.allAvailableActions objectForKey:@"requestJoin"]];
        }
    }
    
    [self generateActionButtons];
}

- (void)generateActionButtons
{
    [self.siteActionButtons removeAllObjects];

    CGFloat leftEdge = BUTTON_LEFT_MARGIN;
    for (NSDictionary *buttonInfo in self.siteActions)
    {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
        
        UIImage *buttonImage = [UIImage imageNamed:[buttonInfo objectForKey:@"image"]];
        button.frame = CGRectMake(leftEdge, self.expandView.center.y - kSiteTableViewCellUnexpandedHeight - buttonImage.size.height/2.0, buttonImage.size.width, buttonImage.size.height);
        [button setBackgroundImage:buttonImage forState:UIControlStateNormal];
        [button addTarget:self action:@selector(handleSiteAction:) forControlEvents:UIControlEventTouchUpInside];

        [self.siteActionButtons addObject:button];
        [self.expandView addSubview:button];
        
        leftEdge = leftEdge + buttonImage.size.width + BUTTON_SPACING;
    }
}

- (void)handleSiteAction:(id)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(tableCell:siteAction:)])
    {
        NSUInteger index = [self.siteActionButtons indexOfObject:sender];
        NSDictionary *buttonInfo = [self.siteActions objectAtIndex:index];
        [self.delegate tableCell:self siteAction:buttonInfo];
    }
}

#pragma mark - UIGestureRecognizerDelegate methods

/**
 * The gesture recognizer is configured to cancel touches in view. We don't want that to happen if
 * the touch was within an action button.
 */
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    for (UIView *view in self.siteActionButtons)
    {
        CGPoint touchLocation = [touch locationInView:self.expandView];
        if (CGRectContainsPoint(view.frame, touchLocation))
        {
            return NO;
        }
    }
    
    return YES;
}

@end
