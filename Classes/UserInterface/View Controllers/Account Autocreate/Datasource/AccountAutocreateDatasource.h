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
//  AccountAutocreateDatasource.h
//

#import <Foundation/Foundation.h>
#import "FDGenericTableViewController.h"

@interface AccountAutocreateDatasource : NSObject <FDDatasourceProtocol>
@property (nonatomic, assign) FDGenericTableViewController *delegate;
@property (nonatomic, assign) SEL action;
@property (nonatomic, retain) NSDictionary *data;

@end
