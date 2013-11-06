//
//  CMISMoveObjectHTTPRequest.m
//  FreshDocs
//
//  Created by bdt on 11/4/13.
//
//

#import "CMISMoveObjectHTTPRequest.h"
#import "CMISMediaTypes.h"

@implementation CMISMoveObjectHTTPRequest

- (id) initWithURL:(NSURL *)u  moveParam:(NSDictionary*) moveParam accountUUID:(NSString *)uuid {
    self = [self initWithURL:u accountUUID:uuid];
    if(self) {
        NSMutableString *propertyElements = [NSMutableString stringWithString:@""];
        
        NSString *stringPropertyTemplate = @"<cmis:properties><cmis:propertyId propertyDefinitionId=\"cmis:objectId\"><cmis:value>%@</cmis:value></cmis:propertyId></cmis:properties>";
        
        NSString *entryTemplate= @"<atom:entry xmlns:ns5=\"http://docs.oasis-open.org/ns/cmis/restatom/200908/\" xmlns:ns3=\"http://www.w3.org/2005/Atom\" xmlns=\"http://docs.oasis-open.org/ns/cmis/core/200908/\"><atom:title></atom:title><atom:updated></atom:updated><cmisra:object xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:xsi=\"http://w3.org/2001/XMLSchema-instance\">%@</cmisra:object></atom:entry>";
        
        NSString *targetFolderId = [moveParam objectForKey:@"cmis:objectId"];//the file or folder would be moved
        if (targetFolderId) {
            [propertyElements appendFormat:stringPropertyTemplate, targetFolderId];
        }
        
        NSString *body = [[NSString alloc] initWithFormat:entryTemplate, propertyElements];
        AlfrescoLogDebug(@"POST: %@", body);
        // create a post request
        NSData *d = [body dataUsingEncoding:NSUTF8StringEncoding];
        
        [self addRequestHeader:@"Content-Type" value:kAtomEntryMediaType];
        [self setPostBody:[NSMutableData dataWithData:d]];
        [self setContentLength:[d length]];
        [self setRequestMethod:@"POST"];
        
        [self setShouldContinueWhenAppEntersBackground:YES];
    }
    
    return self;
}

@end
