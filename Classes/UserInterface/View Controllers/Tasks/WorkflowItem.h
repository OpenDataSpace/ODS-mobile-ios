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
// WorkflowItem 
//
#import <Foundation/Foundation.h>
#import "TaskItem.h"


@interface WorkflowItem : NSObject

@property (nonatomic, retain) NSString *id;
@property (nonatomic) AlfrescoWorkflowType workflowType;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *description;
@property (nonatomic, retain) NSString *message;
@property (nonatomic, retain) NSDate *startDate;
@property (nonatomic, retain) NSDate *dueDate;
@property (nonatomic) int priority;
@property (nonatomic, retain) NSString *initiatorUserName;
@property (nonatomic, retain) NSString *initiatorFullName;
@property (nonatomic, retain) NSArray *documents; // array of DocumentItem objects
@property (nonatomic, retain) NSArray *tasks; // array of TaskItem objects

@property (nonatomic, retain) NSString *accountUUID;
@property (nonatomic, retain) NSString *tenantId;

- (id)initWithJsonDictionary:(NSDictionary *)jsonDictionary;

@end
