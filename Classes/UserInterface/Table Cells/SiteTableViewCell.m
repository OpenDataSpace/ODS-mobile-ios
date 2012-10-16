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
#define BUTTON_SPACING 10.0

NSString * const kSiteTableViewCellIdentifier = @"SiteTableViewCell";
CGFloat kSiteTableViewCellUnexpandedHeight = 60.0f;
CGFloat kSiteTableViewCellExpandedHeight = 100.0f;

@interface SiteTableViewCell ()
@property (nonatomic, retain) NSDictionary *allAvailableActions;
@property (nonatomic, retain) NSMutableArray *siteActions;
@property (nonatomic, retain) NSMutableArray *siteActionButtons;
@property (nonatomic, retain) UIView *expandView;
@end

@implementation SiteTableViewCell

@synthesize delegate = _delegate;
@synthesize site = _site;
@synthesize allAvailableActions = _allAvailableActions;
@synthesize siteActions = _siteActions;
@synthesize siteActionButtons = _siteActionButtons;
@synthesize expandView = _expandView;

typedef enum
{
    SiteActionFavorite = 0,
    SiteActionMembership,
    SiteActionsMax // Last entry, used for array sizing
} SiteActions;

- (void)dealloc
{
    _delegate = nil;
    
    [_allAvailableActions release];
    [_siteActions release];
    [_siteActionButtons release];
    [_site release];
    [_expandView release];
    
    [super dealloc];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self)
    {
        // Default subviews
        self.imageView.image = [UIImage imageNamed:@"site"];
        
        // Expanded view background
        UIView *expandView = [[[UIView alloc] initWithFrame:CGRectMake(0, kSiteTableViewCellUnexpandedHeight, self.frame.size.width, kSiteTableViewCellExpandedHeight - kSiteTableViewCellUnexpandedHeight)] autorelease];
        [expandView setBackgroundColor:[UIColor whiteColor]];
        [expandView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        self.expandView = expandView;
        
        // Add shadow to expanded view
        UIImage *shadow = [[UIImage imageNamed:@"cell-actions-inner-shadow"] stretchableImageWithLeftCapWidth:0 topCapHeight:0];
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
        
        self.allAvailableActions = [NSDictionary dictionaryWithObjectsAndKeys:
                [NSDictionary dictionaryWithObjectsAndKeys:@"favorite", @"id", NSLocalizedString(@"site.action.favorite", @"Favorite"), @"title", @"site-action-favorite", @"image", nil], @"favorite",
                [NSDictionary dictionaryWithObjectsAndKeys:@"unfavorite", @"id", NSLocalizedString(@"site.action.unfavorite", @"Unfavorite"), @"title", @"site-action-unfavorite", @"image", nil], @"unfavorite",
                [NSDictionary dictionaryWithObjectsAndKeys:@"join", @"id", NSLocalizedString(@"site.action.join", @"Join"), @"title", @"site-action-join", @"image", nil], @"join",
                [NSDictionary dictionaryWithObjectsAndKeys:@"requestToJoin", @"id", NSLocalizedString(@"site.action.requestToJoin", @"Request to Join"), @"title", @"site-action-requesttojoin", @"image", nil], @"requestToJoin",
                [NSDictionary dictionaryWithObjectsAndKeys:@"cancelRequest", @"id", NSLocalizedString(@"site.action.cancelRequest", @"Cancel Request"), @"title", @"site-action-cancelrequest", @"image", nil], @"cancelRequest",
                [NSDictionary dictionaryWithObjectsAndKeys:@"leave", @"id", NSLocalizedString(@"site.action.leave", @"Leave"), @"title", @"site-action-leave", @"image", nil], @"leave",
                nil];

        maxTitleWidth = [self maxTitleWidth];

        // Initial placeholder buttons
        self.siteActions = [[[NSMutableArray alloc] initWithObjects:@"favorite", @"join", nil] autorelease];

        // Placeholder Favorite/unfavorite button
        CGFloat leftPosition = BUTTON_LEFT_MARGIN;
        UIButton *favoriteButton = [self makeButtonForActionInfo:[self.allAvailableActions objectForKey:@"favorite"] atLeftPosition:leftPosition];
        [self.expandView addSubview:favoriteButton];
        
        // Placeholder Site membership button
        leftPosition += favoriteButton.frame.size.width + BUTTON_SPACING;
        UIButton *membershipButton = [self makeButtonForActionInfo:[self.allAvailableActions objectForKey:@"join"] atLeftPosition:leftPosition];
        [self.expandView addSubview:membershipButton];

        self.siteActionButtons = [[[NSMutableArray alloc] initWithObjects:favoriteButton, membershipButton, nil] autorelease];
    }
    return self;
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

- (void)setSite:(RepositoryItem *)site
{
    [_site autorelease];
    _site = [site retain];
    
    self.textLabel.text = site.title;
    
    // Favorite/unfavorite
    isFavorite = [[site.metadata objectForKey:@"isFavorite"] boolValue];
    [self.siteActions replaceObjectAtIndex:SiteActionFavorite withObject:(isFavorite ? @"unfavorite" : @"favorite")];
    [self updateActionButton:SiteActionFavorite];

    // Membership
    isMember = [[site.metadata objectForKey:@"isMember"] boolValue];
    isPendingMember =[[site.metadata objectForKey:@"isPendingMember"] boolValue];

    NSString *memberActionKey = nil;
    if (isMember)
    {
        memberActionKey = @"leave";
    }
    else
    {
        NSString *visibility = [self.site.metadata objectForKey:@"visibility"];
        if ([visibility isEqualToCaseInsensitiveString:@"PUBLIC"])
        {
            memberActionKey = @"join";
        }
        else if ([visibility isEqualToCaseInsensitiveString:@"MODERATED"])
        {
            if (isPendingMember)
            {
                memberActionKey = @"cancelRequest";
            }
            else
            {
                memberActionKey = @"requestToJoin";
            }
        }
    }
    [self.siteActions replaceObjectAtIndex:SiteActionMembership withObject:memberActionKey];
    [self updateActionButton:SiteActionMembership];
    
    [self.expandView setNeedsDisplay];
}

- (CGFloat)maxTitleWidth
{
    CGFloat maxWidth = 0;
    for (NSDictionary *actionInfo in self.allAvailableActions.allValues)
    {
        CGSize size = [[actionInfo objectForKey:@"title"] sizeWithFont:[UIFont boldSystemFontOfSize:13.0f]];
        maxWidth = MAX(maxWidth, size.width);
    }
    return maxWidth;
}

- (UIButton *)makeButtonForActionInfo:(NSDictionary *)actionInfo atLeftPosition:(CGFloat)leftPosition
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *buttonTemplate = [UIImage imageNamed:@"black-cell-action-button"];

    // Background image
    UIImage *stretchedButtonImage = [buttonTemplate resizableImageWithCapInsets:UIEdgeInsetsMake(6.0f, 5.0f, 6.0f, 5.0f)];
    [button setBackgroundImage:stretchedButtonImage forState:UIControlStateNormal];
    
    if (actionInfo != nil)
    {
        // Button image
        UIImage *buttonImage = [UIImage imageNamed:[actionInfo objectForKey:@"image"]];
        [button setImage:buttonImage forState:UIControlStateNormal];
        
        // Button title
        [button setTitle:[actionInfo objectForKey:@"title"] forState:UIControlStateNormal];
        [button.titleLabel setFont:[UIFont boldSystemFontOfSize:13.0f]];
        [button.titleLabel setTextColor:[UIColor whiteColor]];
    }

    button.frame = CGRectMake(leftPosition, self.expandView.center.y - kSiteTableViewCellUnexpandedHeight - floor(buttonTemplate.size.height/2.0), maxTitleWidth + buttonTemplate.size.width + 30, buttonTemplate.size.height);

    // Tap action
    [button addTarget:self action:@selector(handleSiteAction:) forControlEvents:UIControlEventTouchUpInside];
    
    return button;
}

- (void)updateActionButton:(SiteActions)siteActionIndex
{
    NSString *actionKey = [self.siteActions objectAtIndex:siteActionIndex];
    NSDictionary *actionInfo = [self.allAvailableActions objectForKey:actionKey];
    UIButton *existingButton = [self.siteActionButtons objectAtIndex:siteActionIndex];
    UIButton *button = [self makeButtonForActionInfo:actionInfo atLeftPosition:existingButton.frame.origin.x];
    [self.expandView addSubview:button];
    [self.siteActionButtons replaceObjectAtIndex:siteActionIndex withObject:button];
    [existingButton removeFromSuperview];
}

- (void)handleSiteAction:(id)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(tableCell:siteAction:)])
    {
        [(UIButton *)sender setEnabled:NO];
        NSUInteger index = [self.siteActionButtons indexOfObject:sender];
        NSString *actionKey = [self.siteActions objectAtIndex:index];
        NSDictionary *actionInfo = [self.allAvailableActions objectForKey:actionKey];
        [self.delegate tableCell:self siteAction:actionInfo];
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
