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
//  RepositoryItem.h
//

#import <Foundation/Foundation.h>

// TODO: Rename this class to a more appropriate class?  CMISAtomEntry? CMISAtomObject?
// TODO: Refactor me so that I better represent the Atom Entry/Feed that I am being populated into

@interface RepositoryItem : NSObject

@property (nonatomic, retain) NSString *identLink; //__attribute__ ((deprecated));
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *guid;
@property (nonatomic, retain) NSString *fileType;
@property (nonatomic, retain) NSString *lastModifiedBy;
@property (nonatomic, retain) NSString *lastModifiedDate;
@property (nonatomic, retain) NSString *contentLocation;
@property (nonatomic, retain) NSString *contentStreamLengthString;
@property (nonatomic, retain) NSString *versionSeriesId;
@property (nonatomic, retain) NSString *changeToken;
@property (nonatomic) BOOL canCreateDocument;
@property (nonatomic) BOOL canCreateFolder;
@property (nonatomic) BOOL canDeleteObject;
@property (nonatomic) BOOL canMoveObject;
@property (nonatomic) BOOL canSetContentStream;
@property (nonatomic, retain) NSMutableDictionary *metadata;
@property (nonatomic, retain) NSString *describedByURL; //REFACTOR & DEPRECATE __attribute__ ((deprecated));
@property (nonatomic, retain) NSString *selfURL; //REFACTOR & DEPRECATE__attribute__ ((deprecated));
@property (nonatomic, readonly) NSString *deleteURL;
@property (nonatomic, retain) NSMutableArray *linkRelations;
@property (nonatomic, retain) NSString *node;
@property (nonatomic, readonly) NSString *contentStreamMimeType;
@property (nonatomic, retain) NSMutableArray *aspects;

- (BOOL) isFolder;
- (NSComparisonResult) compareTitles:(id) other;
- (NSNumber*) contentStreamLength;
- (id) initWithDictionary:(NSDictionary*)dict;

@end
