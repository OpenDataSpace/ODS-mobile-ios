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
//  CMISQueryDownload.h
//

#import <Foundation/Foundation.h>
#import "AsynchonousDownload.h"
@class RepositoryItemsParser;

@protocol NSXMLParserDelegate;

@interface CMISQueryDownload : AsynchonousDownload<NSXMLParserDelegate> {
	NSMutableArray *results;
	NSString *elementBeingParsed;
    NSString *namespaceBeingParsed;
	NSString *currentCMISProperty;
	NSString *currentCMISPropertyValue;
	NSString *postData;
    RepositoryItemsParser *itemsParser;
}

@property (nonatomic, retain) NSMutableArray *results;
@property (nonatomic, retain) NSString *currentCMISProperty;
@property (nonatomic, retain) NSString *currentCMISPropertyValue;
@property (nonatomic, retain) NSString *elementBeingParsed;
@property (nonatomic, retain) NSString *namespaceBeingParsed;
@property (nonatomic, retain) NSString *postData;
@property (nonatomic, retain) RepositoryItemsParser *itemsParser;

- (id)initWithQuery:(NSString *)cql delegate:(id <AsynchronousDownloadDelegate>)del;


@end
