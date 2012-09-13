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
//  SiteTableViewCell.h
//

#import <UIKit/UIKit.h>

@class RepositoryItem;
@class SiteTableViewCell;

extern NSString * const kSiteTableViewCellIdentifier;
extern CGFloat kSiteTableViewCellUnexpandedHeight;
extern CGFloat kSiteTableViewCellExpandedHeight;

@protocol SiteTableViewCellDelegate <NSObject>

@optional
- (void)tableCell:(SiteTableViewCell *)tableCell siteAction:(NSDictionary *)buttonInfo;

@end

@interface SiteTableViewCell : UITableViewCell <UIGestureRecognizerDelegate>
{
@private
    BOOL isFavorite;
    BOOL isMember;
    BOOL isPendingMember;
    CGFloat maxTitleWidth;
}
@property (nonatomic, assign) id<SiteTableViewCellDelegate> delegate;
@property (nonatomic, retain) RepositoryItem *site;

@end
