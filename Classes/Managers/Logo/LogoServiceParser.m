//
//  LogoServiceParser.m
//  FreshDocs
//
//  Created by  Tim Lei on 1/6/15.
//
//

#import "LogoServiceParser.h"
#import "CMISMediaTypes.h"
#import "CMISUtils.h"

@interface LogoServiceParser(){
    BOOL isUriTemplate;
}
@end

@implementation LogoServiceParser
@synthesize serviceDocData = _serviceDocData;
@synthesize currentRepositoryInfo = _currentRepositoryInfo;
@synthesize repositoryInfoDictionary = _repositoryInfoDictionary;
@synthesize currentCollectionHref = _currentCollectionHref;
@synthesize elementBeingParsed = _elementBeingParsed;
@synthesize namespaceBeingParsed = _namespaceBeingParsed;
@synthesize collectionType = _collectionType;
@synthesize collectionMediaTypeAcceptArray = _collectionMediaTypeAcceptArray;
@synthesize inCMISRepositoryInfoElement = _inCMISRepositoryInfoElement;
@synthesize currentTemplateValue = _currentTemplateValue;
@synthesize currentTemplateType = _currentTemplateType;
@synthesize accountUuid = _accountUuid;
@synthesize tenantID = _tenantID;

@synthesize parserResult = _parserResult;

- (id)initWithAtomPubServiceDocumentData:(NSData *)appData
{
    if ((self = [super init])) {
        _serviceDocData = [appData copy];
        _inCMISRepositoryInfoElement = NO;
        _parserResult = [NSMutableArray array];
    }
    return self;
}

- (void)parse {
    // create a parser and parse the xml
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:_serviceDocData];
    [parser setShouldProcessNamespaces:YES];
    [parser setDelegate:self];
    [parser parse];
}

#pragma mark -
#pragma mark NSXMLParser delegate methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    
    if ([elementName isEqualToString:@"workspace"] && [CMISUtils isAtomPubNamespace:namespaceURI]) {
        [self setCurrentRepositoryInfo:[[RepositoryInfo alloc] init]];
    }
    else if ([elementName isEqualToString:@"repositoryInfo"]
             && ([CMISUtils isCmisRestAtomNamespace:namespaceURI] // CMIS 1.0 uses cmis rest atom NS
                 || [CMISUtils isCmisNamespace:namespaceURI])) // !!!: draft CMIS versions use cmis NS
    {
        _inCMISRepositoryInfoElement = YES;
        [self setRepositoryInfoDictionary:[NSMutableDictionary dictionary]];
    }
    else if ([elementName isEqualToString:@"collection"] && [CMISUtils isAtomPubNamespace:namespaceURI]) {
        [self setCurrentCollectionHref:[attributeDict objectForKey:@"href"]];
        [self setCollectionMediaTypeAcceptArray:[NSMutableArray array]];
        
        // !!!: for backwards compatibility with cmis .6 (as shipped in alfresco community 3.2.0)
        NSString *type = [attributeDict objectForKey:@"cmis:collectionType"];
        if ([type isEqualToString:@"rootchildren"]) {
            [_currentRepositoryInfo setRootFolderHref:[attributeDict objectForKey:@"href"]];
        }
    }
    else if ([elementName isEqualToString:@"uritemplate"] && [CMISUtils isCmisRestAtomNamespace:namespaceURI]) {
        isUriTemplate = YES;
        [self setCurrentTemplateType:@""];
        [self setCurrentTemplateValue:@""];
    }
    
    
    [self setElementBeingParsed:elementName];
    [self setNamespaceBeingParsed:namespaceURI];
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    
    if ([self.elementBeingParsed isEqualToString:@"collectionType"] && [CMISUtils isCmisRestAtomNamespace:_namespaceBeingParsed]) {
        self.collectionType = self.collectionType ? [self.collectionType stringByAppendingString:string] : string;
    }
    //	else if ([self.elementBeingParsed isEqualToString:@"cmisVersionSupported"] && [CMISUtils isCmisNamespace:namespaceBeingParsed]) {
    //		self.cmisVersion = self.cmisVersion ? [self.cmisVersion stringByAppendingString:string] : string;
    //	}
    else if ([_elementBeingParsed isEqualToString:@"accept"] && [CMISUtils isAtomPubNamespace:_namespaceBeingParsed]) {
        [_collectionMediaTypeAcceptArray addObject:string];
    }
    else if (_inCMISRepositoryInfoElement && [CMISUtils isCmisNamespace:_namespaceBeingParsed])
    {
        if ([_elementBeingParsed isEqualToString:@"capabilities"]) {
            // TODO: Skip Capabilities for now but implementation needed
        }
        else {
            // We're going to use key-value coding to populate the RepositoryInfo class
            NSString *object = [_repositoryInfoDictionary objectForKey:_elementBeingParsed];
            [_repositoryInfoDictionary setObject:((object) ? [object stringByAppendingString:string] : string)
                                         forKey:_elementBeingParsed];
        }
    }
    else if (isUriTemplate && [CMISUtils isCmisRestAtomNamespace:_namespaceBeingParsed]) {
        if ([_elementBeingParsed isEqualToString:@"template"]) {
            [self setCurrentTemplateValue:[_currentTemplateValue stringByAppendingString:string]];
        } else if ([_elementBeingParsed isEqualToString:@"type"]) {
            [self setCurrentTemplateType:[_currentTemplateType stringByAppendingString:string]];
        }
    }
    else if ([_elementBeingParsed isEqualToString:@"productVersion"] && [CMISUtils isCmisNamespace:_namespaceBeingParsed]) {
        [_repositoryInfoDictionary setObject:string forKey:@"productVersion"];
    }
    else if ([_elementBeingParsed isEqualToString:@"productName"] && [CMISUtils isCmisNamespace:_namespaceBeingParsed]) {
        [_repositoryInfoDictionary setObject:string forKey:@"productName"];
    }
}


- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    [self setElementBeingParsed:nil];
    [self setNamespaceBeingParsed:nil];
    
    if ([elementName isEqualToString:@"collectionType"] && [CMISUtils isCmisRestAtomNamespace:namespaceURI]) {
        
        if ([self.collectionType isEqualToString:@"root"]) {
            [_currentRepositoryInfo setRootFolderHref:_currentCollectionHref];
        }
        
        [self setCollectionType:nil];
    }
    else if ([elementName isEqualToString:@"collection"] && [CMISUtils isAtomPubNamespace:namespaceURI]) {
        if ([_collectionMediaTypeAcceptArray containsObject:kCMISQueryMediaType]) {
            [_currentRepositoryInfo setCmisQueryHref:_currentCollectionHref];
        }
        
        [self setCurrentCollectionHref:nil];
        [_collectionMediaTypeAcceptArray removeAllObjects];
    }
    else if ([elementName isEqualToString:@"repositoryInfo"]
             && ([CMISUtils isCmisRestAtomNamespace:namespaceURI] // CMIS 1.0 uses cmis rest atom NS
                 || [CMISUtils isCmisNamespace:namespaceURI])) // !!!: draft CMIS versions use cmis NS
    {
        [_currentRepositoryInfo setValuesForKeysWithDictionary:_repositoryInfoDictionary];
        
        _inCMISRepositoryInfoElement = NO;
        [self setRepositoryInfoDictionary:nil];
    }
    else if ([elementName isEqualToString:@"workspace"] && [CMISUtils isAtomPubNamespace:namespaceURI]) {
        [_parserResult addObject:_currentRepositoryInfo];
    }
    else if ([elementName isEqualToString:@"uritemplate"] && [CMISUtils isCmisRestAtomNamespace:namespaceURI]) {
        if (_currentTemplateType) {
            if ([_currentTemplateType isEqualToString:@"objectbyid"]) {
                [_currentRepositoryInfo setObjectByIdUriTemplate:_currentTemplateValue];
            } else if ([_currentTemplateType isEqualToString:@"objectbypath"]) {
                [_currentRepositoryInfo setObjectByPathUriTemplate:_currentTemplateValue];
            } else if ([_currentTemplateType isEqualToString:@"typebyid"]) {
                [_currentRepositoryInfo setTypeByIdUriTemplate:_currentTemplateValue];
            } else if ([_currentTemplateType isEqualToString:@"query"]) {
                [_currentRepositoryInfo setQueryUriTemplate:_currentTemplateValue];
            }
        }
        
        [self setCurrentTemplateValue:nil];
        [self setCurrentTemplateType:nil];
        isUriTemplate = NO;
    }
}

@end
