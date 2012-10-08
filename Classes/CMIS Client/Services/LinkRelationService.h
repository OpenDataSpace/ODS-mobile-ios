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
//  LinkRelationService.h
//

#import <Foundation/Foundation.h>
#import "RepositoryItem.h"

typedef enum
{
    LinkRelationTypeSelf,
    LinkRelationTypeService,
    LinkRelationTypeDescribedBy,
    LinkRelationTypeVia,
    LinkRelationTypeEditMedia,
    LinkRelationTypeEdit,
    LinkRelationTypeAlternate,
    LinkRelationTypePagingFirst,
    LinkRelationTypePagingPrevious,
    LinkRelationTypePagingNext,
    LinkRelationTypePagingLast
} LinkRelationType;

typedef enum
{
    HierarchyNavigationLinkRelationUp,
    HierarchyNavigationLinkRelationDown
} HierarchyNavigationLinkRelation;


// TODO: Implement Implement Hierarchy Navigation Link Relations
// TODO: Implement Versioning Link Relations
// TODO: Implement CMIS Specific Link Relations


// CMIS Link Relations Documentation
// http://docs.oasis-open.org/cmis/CMIS/v1.0/os/cmis-spec-v1.0.html#_Toc243905521
@interface LinkRelationService : NSObject


// Returns the link destination for the given Link Relation on the given CMIS Object. If the link
// destination cannot be resolved, nil is returned.
// Note: this implementation only supports and guarentees CMIS 1.0
- (NSString *)hrefForLinkRelation:(LinkRelationType)linkRelation onCMISObject:(RepositoryItem *)cmisObject;
- (NSString *)hrefForLinkRelationString:(NSString *)linkRelationStr onCMISObject:(RepositoryItem *)cmisObject;
- (NSString *)hrefForLinkRelationString:(NSString *)linkRelationStr cmisMediaType:(NSString *)cmisMediaType onCMISObject:(RepositoryItem *)cmisObject;

// !!!: Document Me
- (NSString *)hrefForHierarchyNavigationLinkRelation:(HierarchyNavigationLinkRelation)linkRelation 
										 cmisService:(NSString *)cmisService cmisObject:(RepositoryItem *)cmisObject;



// Returns the getChildren link destination and encodes the optional arguments as URL encoded parameters
// Note: This method supports CMIS 1.0 and several draft versions of CMIS
- (NSURL *)getChildrenURLForCMISFolder:(RepositoryItem *)cmisFolder withOptionalArguments:(NSDictionary *)optionalArgumentsDictionary;
- (NSDictionary *)optionalArgumentsForFolderChildrenCollectionWithMaxItems:(NSNumber *)maxItemsOrNil
																 skipCount:(NSNumber *)skipCountOrNil 
																	filter:(NSString *)filterOrNil 
												   includeAllowableActions:(BOOL)includeAllowableActions 
													  includeRelationships:(BOOL)includeRelationships 
														   renditionFilter:(NSString *)renditionFilterOrNil 
																   orderBy:(NSString *)orderByOrNil 
														includePathSegment:(BOOL)includePathSegment;
- (NSDictionary *)defaultOptionalArgumentsForFolderChildrenCollection;


// Singleton Methods
+ (id)shared;
@end
