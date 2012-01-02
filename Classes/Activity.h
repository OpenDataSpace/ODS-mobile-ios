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
 * Portions created by the Initial Developer are Copyright (C) 2011
 * the Initial Developer. All Rights Reserved.
 *
 *
 * ***** END LICENSE BLOCK ***** */
//
//  Activity.h
//

#import <Foundation/Foundation.h>
@class AccountInfo;

@interface Activity : NSObject {
    @private
    NSString *itemTitle;
    NSString *user;
    NSString *custom1;
    NSString *custom2;
    NSString *siteLink;
    NSString *activityType;
    NSDate *postDate;
    NSString *replacedActivityText;
    NSString *objectId;
    NSMutableAttributedString *mutableString;
    NSString *accountUUID;
    NSString *tenantID;
    
    BOOL isDocument;
}

@property (nonatomic, readonly) NSString *activityType;
@property (nonatomic, retain) NSString *accountUUID;
@property (nonatomic, retain) NSString *tenantID;

- (Activity *) initWithJsonDictionary:(NSDictionary *) json;

- (NSString *)activityText;
- (NSString *)activityDate;
- (NSString *)groupHeader;
- (NSArray *) replacements;
- (UIImage *) iconImage;
- (NSString *) objectId;
- (BOOL) isDocument;

- (NSString *) replaceIndexPointsIn:(NSString *)string withValues:(NSArray *) replacements;

- (NSMutableAttributedString *) boldReplacements:(NSArray *) replacements inString:(NSMutableAttributedString *)attributed;

@end
