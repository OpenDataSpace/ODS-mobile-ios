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
//  TableViewNode.h
//

#import <Foundation/Foundation.h>

@interface TableViewNode : NSObject {
    id value;
    id parent;
    NSInteger indentationLevel;
    BOOL canExpand;
    BOOL isExpanded;
    NSString *accountUUID;
}

@property (nonatomic, retain) id value;
@property (nonatomic, retain) id parent;
@property (nonatomic, assign) NSInteger indentationLevel;
@property (nonatomic, assign) BOOL canExpand;
@property (nonatomic, assign) BOOL isExpanded;
@property (nonatomic, copy) NSString *accountUUID;

//Abstract properties
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSString *breadcrumb;
@property (nonatomic, readonly) UIImage *cellImage;
@property (nonatomic, readwrite, copy) NSString *tenantID;

@end
