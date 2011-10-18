//
//  CMISMediaTypes.h
//  FreshDocs
//
//  Created by Gi Hyun Lee on 10/11/10.
//  Copyright 2010 Zia Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kAtomPubServiceMediaType; // AtomPub Service
extern NSString * const kAtomEntryMediaType; // Atom Entry
extern NSString * const kAtomFeedMediaType; // Atom Feed
extern NSString * const kCMISAtomMediaType; // an Atom Document (Entry or Feed) with any CMIS Markup 
extern NSString * const kCMISQueryMediaType; // CMIS Query Document
extern NSString * const kCMISAllowableActionsMediaType; // CMIS Allowable Actions Document
extern NSString * const kCMISTreeMediaType; // an Atom Feed Document with CMIS Hierarchy extensions 
extern NSString * const kCMISACLMediaType; // a CMIS ACL Document

@interface CMISMediaTypes

@end
