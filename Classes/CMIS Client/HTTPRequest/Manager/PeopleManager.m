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
//  PeopleManager.m
//

#import "PeopleManager.h"
#import "PeopleHTTPRequest.h"
#import "PersonNodeRefHTTPRequest.h"

@interface PeopleManager () 

@property (nonatomic, retain) PeopleHTTPRequest *peopleRequest;
@property (nonatomic, retain) PersonNodeRefHTTPRequest *nodeRefRequest;

@end

@implementation PeopleManager

@synthesize peopleRequest = _peopleRequest;
@synthesize nodeRefRequest = _nodeRefRequest;
@synthesize delegate = _delegate;

- (void)startPeopleSearchRequestWithQuery:(NSString *)query accountUUID:(NSString *)uuid tenantID:(NSString *)tenantID
{
    self.peopleRequest = [PeopleHTTPRequest peopleRequestWithFilter:query accountUUID:uuid tenantID:tenantID];
    [self.peopleRequest setShouldContinueWhenAppEntersBackground:YES];
    [self.peopleRequest setSuppressAllErrors:YES];
    [self.peopleRequest setDelegate:self];
    
    [self.peopleRequest startAsynchronous];
}

- (NSString *)getPersonNodeRefSearchWithUsername:(NSString *)username accountUUID:(NSString *)uuid tenantID:(NSString *)tenantID
{
    self.nodeRefRequest = [PersonNodeRefHTTPRequest personRequestWithUsername:username accountUUID:uuid tenantID:tenantID];
    [self.nodeRefRequest setShouldContinueWhenAppEntersBackground:YES];
    [self.nodeRefRequest setSuppressAllErrors:YES];
    
    [self.nodeRefRequest startSynchronous];
    
    return self.nodeRefRequest.nodeRef;
}

#pragma mark - ASIHTTPRequest delegate methods

- (void)requestFinished:(ASIHTTPRequest *)request 
{
    if ([request isEqual:self.peopleRequest])
    {
        if(self.delegate)
        {
            [self.delegate peopleRequestFinished:self.peopleRequest.people];
            self.delegate = nil;
        }
        self.peopleRequest = nil;
    }
}

- (void)requestFailed:(ASIHTTPRequest *)request 
{
    NSLog(@"People Request Failed: %@", [request error]);
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(peopleRequestFailed:)])
    {
        [self.delegate peopleRequestFailed:self];
        self.delegate = nil;
    }
}

#pragma mark - Singleton

+ (PeopleManager *)sharedManager
{
    static dispatch_once_t predicate = 0;
    __strong static id sharedObject = nil;
    dispatch_once(&predicate, ^{
        sharedObject = [[self alloc] init];
    });
    return sharedObject;
}

@end
