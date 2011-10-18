//
//  RepositoryItem.h
//  Alfresco
//
//  Created by Michael Muller on 10/21/09.
//  Copyright 2009 Michael J Muller. All rights reserved.
//

#import <Foundation/Foundation.h>

// TODO: Rename this class to a more appropriate class?  CMISAtomEntry? CMISAtomObject?
// TODO: Refactor me so that I better represent the Atom Entry/Feed that I am being populated into

@interface RepositoryItem : NSObject {
@private
	NSString *identLink; // children feed // TODO: DEPRECATE ME USE linkRelations Array with Predicates
	NSString *title;
	NSString *guid;
	NSString *fileType;
	NSString *lastModifiedBy;
	NSString *lastModifiedDate;
	NSString *contentLocation;
	NSString *contentStreamLengthString;
	BOOL      canCreateDocument; // REFACTOR: into allowable actions?
	BOOL      canCreateFolder;
	NSMutableDictionary *metadata;
	NSString *describedByURL; // TODO: implement using linkRelations Array with Predicates
	NSString *selfURL; // TODO: implement using linkRelations Array with Predicates
	NSMutableArray *linkRelations;
	
	NSString *node; // !!!: Legacy purposes....
}

@property (nonatomic, retain) NSString *identLink; //__attribute__ ((deprecated));
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *guid;
@property (nonatomic, retain) NSString *fileType;
@property (nonatomic, retain) NSString *lastModifiedBy;
@property (nonatomic, retain) NSString *lastModifiedDate;
@property (nonatomic, retain) NSString *contentLocation;
@property (nonatomic, retain) NSString *contentStreamLengthString;
@property (nonatomic) BOOL canCreateDocument;
@property (nonatomic) BOOL canCreateFolder;
@property (nonatomic, retain) NSMutableDictionary *metadata;
@property (nonatomic, retain) NSString *describedByURL; //REFACTOR & DEPRECATE __attribute__ ((deprecated));
@property (nonatomic, retain) NSString *selfURL; //REFACTOR & DEPRECATE__attribute__ ((deprecated));
@property (nonatomic, retain) NSMutableArray *linkRelations;
@property (nonatomic, retain) NSString *node;

- (BOOL) isFolder;
- (NSComparisonResult) compareTitles:(id) other;
- (NSNumber*) contentStreamLength;
@end
