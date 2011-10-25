//
//  ***** BEGIN LICENSE BLOCK *****
//  Version: MPL 1.1
//
//  The contents of this file are subject to the Mozilla Public License Version
//  1.1 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at
//  http://www.mozilla.org/MPL/
//
//  Software distributed under the License is distributed on an "AS IS" basis,
//  WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
//  for the specific language governing rights and limitations under the
//  License.
//
//  The Original Code is the Alfresco Mobile App.
//  The Initial Developer of the Original Code is Zia Consulting, Inc.
//  Portions created by the Initial Developer are Copyright (C) 2011
//  the Initial Developer. All Rights Reserved.
//
//
//  ***** END LICENSE BLOCK *****
//
//
//  SearchResult.h
//

#import <Foundation/Foundation.h>


@interface SearchResult : NSObject {
    NSString *cmisObjectId;
	NSString *title;
	NSString *contentStreamFileName;
	NSString *relevance;
	NSString *contentLocation;
    NSString *lastModifiedDateStr;
    NSString *contentStreamLength;
    NSString *contentStreamMimeType;
    NSString *contentAuthor;
    NSString *updated;
}

@property (nonatomic, retain) NSString *cmisObjectId;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *contentStreamFileName;
@property (nonatomic, retain) NSString *relevance;
@property (nonatomic, retain) NSString *contentLocation;
@property (nonatomic, retain) NSString *lastModifiedDateStr;
@property (nonatomic, retain) NSString *contentStreamLength;
@property (nonatomic, retain) NSString *contentStreamMimeType;
@property (nonatomic, retain) NSString *contentAuthor;
@property (nonatomic, retain) NSString *updated;

@end
