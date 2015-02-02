//
//  LogoItem.m
//  FreshDocs
//
//  Created by  Tim Lei on 12/16/14.
//
//

#import "LogoItem.h"
#import "RepositoryItem.h"

static NSString * const kLogoItemAccountUUIDIdentifier = @"kLogoItemAccountUUIDIdentifier";
static NSString * const kLogoItemFileNameIdentifier = @"kLogoItemFileNameIdentifier";
static NSString * const kLogoItemUrlIdentifier = @"kLogoItemUrlIdentifier";
static NSString * const kLogoItemChangeTokenIdentifier = @"kLogoItemChangeTokenIdentifier";
static NSString * const kLogoImageIdentifier = @"LogoImageIdentifier";
static NSString * const kLogoLastModifiedDateIdentifier = @"LogoLastModifiedDateIdentifier";

@implementation LogoItem
@synthesize accountUUID = _accountUUID;
@synthesize fileName = _fileName;
@synthesize urlString = _urlString;
@synthesize changeToken = _changeToken;
@synthesize logoImage = _logoImage;
@synthesize lastModifiedDate = _lastModifiedDate;

- (id) initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _accountUUID = [aDecoder decodeObjectForKey:kLogoItemAccountUUIDIdentifier];
        _fileName = [aDecoder decodeObjectForKey:kLogoItemFileNameIdentifier];
        _urlString = [aDecoder decodeObjectForKey:kLogoItemUrlIdentifier];
        _changeToken = [aDecoder decodeObjectForKey:kLogoItemChangeTokenIdentifier];
        _logoImage = [aDecoder decodeObjectForKey:kLogoImageIdentifier];
        _lastModifiedDate = [aDecoder decodeObjectForKey:kLogoLastModifiedDateIdentifier];
    }
    
    return self;
}
- (void) encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_accountUUID forKey:kLogoItemAccountUUIDIdentifier];
    [aCoder encodeObject:_fileName forKey:kLogoItemFileNameIdentifier];
    [aCoder encodeObject:_urlString forKey:kLogoItemUrlIdentifier];
    [aCoder encodeObject:_changeToken forKey:kLogoItemChangeTokenIdentifier];
    [aCoder encodeObject:_logoImage forKey:kLogoImageIdentifier];
    [aCoder encodeObject:_lastModifiedDate forKey:kLogoLastModifiedDateIdentifier];
}

+ (id) logoItemWithAccountUUID:(NSString*) acctUUID repositoryItem:(RepositoryItem*) repoItem {
    LogoItem *newItem = [[self alloc] init];
    
    [newItem setAccountUUID:acctUUID];
    [newItem setFileName:[repoItem title]];
    [newItem setUrlString:[repoItem contentLocation]];
    [newItem setChangeToken:[repoItem changeToken]];
    [newItem setLastModifiedDate:[repoItem lastModifiedDate]];
    
    return newItem;
}

- (void) setValue:(id)value forUndefinedKey:(NSString *)key {
    NSLog(@"key:%@ === value:%@", key, value);
}

/* Icon url */
- (NSURL *) logoURL {
    return [NSURL URLWithString:_urlString];
}

@end
