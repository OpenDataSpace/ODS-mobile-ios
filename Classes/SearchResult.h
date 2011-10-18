//
//  SearchResult.h
//  Alfresco
//
//  Created by Michael Muller on 10/23/09.
//  Copyright 2009 Michael J Muller. All rights reserved.
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
