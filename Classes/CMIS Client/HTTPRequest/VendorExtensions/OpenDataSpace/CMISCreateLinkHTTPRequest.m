//
//  CMISCreateLinkHTTPRequest.m
//  FreshDocs
//
//  Created by bdt on 5/23/14.
//
//

#import "CMISCreateLinkHTTPRequest.h"
#import "CMISMediaTypes.h"
#import "GTMNSString+XML.h"
#import "NSString+SHA.h"

@implementation CMISCreateLinkHTTPRequest

+ (NSString*) buildCreateLinkBody:(NSString*) linkType linkInfo:(NSDictionary*)linkInfo objectIds:(NSString*) objectIds{
    NSString *subject = [linkInfo objectForKey:@"Subject"];
    NSString *email = [linkInfo objectForKey:@"Email"];
    NSString *expirationDate = [linkInfo objectForKey:@"ExpirationDate"];
    NSString *password = [linkInfo objectForKey:@"Password"];
    NSString *message = [linkInfo objectForKey:@"Message"];
    NSString *comment = message;//[linkInfo objectForKey:@"Comment"];
    
    NSString *subjectTemplate = @"<cmis:propertyString propertyDefinitionId=\"gds:subject\"><cmis:value>%@</cmis:value></cmis:propertyString>";
    NSString *emailTemplate = @"<cmis:propertyString propertyDefinitionId=\"gds:emailAddress\"><cmis:value>%@</cmis:value></cmis:propertyString>";
    NSString *expirationDateTemplate = @"<cmis:propertyDateTime propertyDefinitionId=\"cmis:rm_expirationDate\"><cmis:value>%@</cmis:value></cmis:propertyDateTime>";
    NSString *passwordTemplate = @"<cmis:propertyString propertyDefinitionId=\"gds:password\"><cmis:value>%@</cmis:value></cmis:propertyString>";
    NSString *messageTemplate = @"<cmis:propertyId propertyDefinitionId=\"gds:message\"><cmis:value>%@</cmis:value></cmis:propertyId>";
    NSString *commentTemplate = @"<cmis:propertyString propertyDefinitionId=\"gds:comment\"><cmis:value>%@</cmis:value></cmis:propertyString>";
    NSString *objectIdsTemplate =@"<cmis:propertyId propertyDefinitionId=\"gds:objectIds\"><cmis:value>%@</cmis:value></cmis:propertyId>";
    NSString *linkTypeTemplate = @"<cmis:propertyId propertyDefinitionId=\"cmis:secondaryObjectTypeIds\"><cmis:value>cmis:rm_clientMgtRetention</cmis:value><cmis:value>%@</cmis:value></cmis:propertyId>";
    
    NSString *entryTemplate = @"<?xml version=\"1.0\" ?>"
                                "<entry xmlns=\"http://www.w3.org/2005/Atom\" xmlns:app=\"http://www.w3.org/2007/app\" xmlns:cmisra=\"http://docs.oasis-open.org/ns/cmis/restatom/200908/\">"
                                "<title type=\"text\"></title>"
                                "<cmisra:object xmlns:cmis=\"http://docs.oasis-open.org/ns/cmis/core/200908/\">"
                                "<cmis:properties>"
                                "<cmis:propertyId propertyDefinitionId=\"cmis:objectTypeId\"><cmis:value>cmis:item</cmis:value></cmis:propertyId>"
                                "%@"
                                "</cmis:properties>"
                                "</cmisra:object>"
                                "</entry>";
    
    NSMutableString *properties = [[NSMutableString alloc] init];
    
    if (linkType) {
        [properties appendString:[NSString stringWithFormat:linkTypeTemplate, linkType]];
    }
    
    if (subject) {
        [properties appendString:[NSString stringWithFormat:subjectTemplate, subject]];
    }
    
    if (email) {
        [properties appendString:[NSString stringWithFormat:emailTemplate, email]];
    }
    
    if (message) {
        [properties appendString:[NSString stringWithFormat:messageTemplate, message]];
    }
    
    if (password) {
        [properties appendString:[NSString stringWithFormat:passwordTemplate, [NSString SHA256String:password]]];
    }
    
    if (comment) {
        [properties appendString:[NSString stringWithFormat:commentTemplate, comment]];
    }
    
    if (expirationDate) {
        [properties appendString:[NSString stringWithFormat:expirationDateTemplate, expirationDate]];
    }
    
    if (objectIds) {
        [properties appendString:[NSString stringWithFormat:objectIdsTemplate, objectIds]];
    }
    
   
    NSString *postBody = [NSString stringWithFormat:entryTemplate, properties];
    
    return postBody;
}

+ (CMISCreateLinkHTTPRequest*) cmisCreateLinkRequestWithItem:(RepositoryItem*)repositoryItem destURL:(NSURL*)destUrl linkType:(NSString*) linkType linkInfo:(NSDictionary*)linkInfo  accountUUID:(NSString *)accountUUID {
    
    NSString *postBody = [CMISCreateLinkHTTPRequest buildCreateLinkBody:linkType linkInfo:linkInfo objectIds:repositoryItem.guid];
    
    CMISCreateLinkHTTPRequest *request = [CMISCreateLinkHTTPRequest requestWithURL:destUrl accountUUID:accountUUID];
    request.requestMethod = @"POST";
    [request addRequestHeader:@"Content-Type" value:kAtomEntryMediaType];
    request.shouldContinueWhenAppEntersBackground = YES;
    request.postBody = [NSMutableData dataWithData:[postBody dataUsingEncoding:NSUTF8StringEncoding]];
    request.contentLength = postBody.length;
    
    return request;
}
@end
