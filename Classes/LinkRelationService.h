//
//  LinkRelationService.h
//  FreshDocs
//
//  Created by Gi Hyun Lee on 10/12/10.
//  Copyright 2010 Zia Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RepositoryItem.h"

typedef enum {
	kSelfLinkRelation,
	kServiceLinkRelation,
	kDescribedByLinkRelation,
	kViaLinkRelation,
	kEditMediaLinkRelation,
	kEditLinkRelation,
	kAlternateLinkRelation,
	kPagingFirstLinkRelation,
	kPagingPreviousLinkRelation,
	kPagingNextLinkRelation,
	kPagingLastLinkRelation
} LinkRelation;

typedef enum {
	kUp,
	kDown
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
- (NSString *)hrefForLinkRelation:(LinkRelation)linkRelation onCMISObject:(RepositoryItem *)cmisObject;

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
