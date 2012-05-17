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
//  AttributedLabelCellController.m
//

#import "AttributedLabelCellController.h"
#import "AttributedLabelTableViewCell.h"
#import "TTTAttributedLabel.h"

static CGFloat const kTextFontSize = 17;
static CGFloat const kAttributedCellControllerVerticalMargin = 20.0f;

@implementation AttributedLabelCellController
@synthesize textColor = _textColor;
@synthesize backgroundColor = _backgroundColor;
@synthesize textAlignment = _textAlignment;
@synthesize text = _text;
@synthesize block = _block;
@synthesize delegate = _delegate;


- (void)dealloc
{
    [_textColor release];
    [_backgroundColor release];
    [_text release];
    [urls release];
    [ranges release];
    [super dealloc];
}

- (id)init
{
    self = [super init];
    if(self)
    {
        urls = [[NSMutableArray alloc] init];
        ranges = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)addLinkToURL:(NSURL *)url withRange:(NSRange)range
{
    [urls addObject:url];
    [ranges addObject:[NSValue valueWithRange:range]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    AttributedLabelTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AttributedLabelCellController"];
	if (cell == nil)
	{
		cell = [[[AttributedLabelTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"AttributedLabelCellController"] autorelease];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
	}
    
    if(self.backgroundColor)
    {
        [cell setBackgroundColor:self.backgroundColor];
        [cell.attributedLabel setBackgroundColor:self.backgroundColor];
    }
    
    if(self.textColor)
    {
        [cell.attributedLabel setTextColor:self.textColor];
    }
    
    [cell.attributedLabel setTextAlignment:self.textAlignment];
    
    [cell.attributedLabel setText:self.text afterInheritingLabelAttributesAndConfiguringWithBlock:self.block];
    for(NSInteger i = 0; i<[ranges count]; i++)
    {
        NSRange range = [[ranges objectAtIndex:i] rangeValue];
        NSURL *url = [urls objectAtIndex:i];
        [cell.attributedLabel addLinkToURL:url withRange:range];
    }
    
    [cell.attributedLabel setDelegate:self.delegate];
    return cell;
}

//Determines the margin of the tablecell
//http://stackoverflow.com/questions/4708085/how-to-determine-margin-of-a-grouped-uitableview-or-better-how-to-set-it
- (float)groupedCellMarginWithTableWidth:(float)tableViewWidth
{
    float marginWidth;
    if(tableViewWidth > 20)
    {
        if(tableViewWidth < 400)
        {
            // Changed from "10"
            // The reason is, that only in the iphone in portrait the title spans 2 lines
            // QUick fix for that since it is only the special case dependant on the content it may break other content (text)
            // trying to use this cell.
            marginWidth = 27;
        }
        else
        {
            marginWidth = MAX(31, MIN(45, tableViewWidth*0.06));
        }
    }
    else
    {
        marginWidth = tableViewWidth - 10;
    }
    return marginWidth;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = 10.0f;
    CGFloat margin = [self groupedCellMarginWithTableWidth:tableView.bounds.size.width];
    height += ceilf([_text sizeWithFont:[UIFont systemFontOfSize:kTextFontSize] constrainedToSize:CGSizeMake(tableView.bounds.size.width-(margin*2), CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap].height);
    height += kAttributedCellControllerVerticalMargin;
    return height;
}

@end
