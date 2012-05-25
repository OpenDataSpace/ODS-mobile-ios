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
//  BaseHTTPRequest.m
//
// Provides standard bahaviour for an error code in the headers and a base for the ASIHTTPRequest descendants

#import "BaseHTTPRequest.h"
#import "AccountManager.h"
#import "AccountInfo+URL.h"
#import "NSString+TokenReplacement.h"
#import "NodeRef.h"
#import "Utility.h"
#import "ASIAuthenticationDialog.h"
#import "AlfrescoAppDelegate.h"
#import "SessionKeychainManager.h"

NSString * const kBaseRequestStatusCodeKey = @"NSHTTPPropertyStatusCodeKey";

// ServerAPI Keys
NSString * const kServerAPISiteCollection = @"ServerAPISiteCollection";
NSString * const kServerAPISearchURL = @"ServerAPISearchURL";
NSString * const kServerAPICMISServiceInfo = @"ServerAPICMISServiceInfo";
NSString * const kServerAPINode = @"ServerAPINode";
NSString * const kServerAPIActivitiesUserFeed = @"ServerAPIActivitiesUserFeed";
NSString * const kServerAPIComments = @"ServerAPIComments";
NSString * const kServerAPIRatings = @"ServerAPIRatings";
NSString * const kServerAPITagCollection = @"ServerAPITagCollection";
NSString * const kServerAPIListAllTags = @"ServerAPIListAllTags";
NSString * const kServerAPINodeTagCollection = @"ServerAPINodeTagCollection";
NSString * const kServerAPIUserPreferenceSet = @"ServerAPIUserPreferenceSet";
NSString * const kServerAPIPersonsSiteCollection = @"ServerAPIPersonsSiteCollection";
NSString * const kServerAPINetworksCollection = @"ServerAPINetworksCollection";
NSString * const kServerAPICloudSignup = @"ServerAPICloudSignup";
NSString * const kServerAPICloudAccountStatus = @"ServerAPICloudAccountStatus";
NSString * const kServerAPIActionService = @"ServerAPIActionService";

@interface BaseHTTPRequest ()

+ (NSMutableDictionary *)tokenDictionaryRepresentationForAccountInfo:(AccountInfo *)info tenantID:(NSString *)aTenantID infoDictionary:(NSDictionary *)infoDictionary;
+ (NSString *)removeWebappSlashFromUrl:(NSString *)tokenizedUrl andTokens:(NSDictionary *)tokens;

- (void)addCloudRequestHeader;
- (void)presentPasswordPrompt;
@end


@implementation BaseHTTPRequest

@synthesize show500StatusError = _show500StatusError;
@synthesize suppressAllErrors = _suppressAllErrors;
@synthesize serverAPI = _serverAPI;
@synthesize accountUUID = _accountUUID;
@synthesize accountInfo = _accountInfo;
@synthesize tenantID = _tenantID;
@synthesize passwordPrompt = _passwordPrompt;
@synthesize presentingController = _presentingController;
@synthesize willPromptPasswordSelector = _willPromptPasswordSelector;
@synthesize finishedPromptPasswordSelector = _finishedPromptPasswordSelector;

- (void)dealloc
{
    [_serverAPI release];
    [_accountUUID release];
    [_accountInfo release];
    [_tenantID release];
    [_passwordPrompt release];
    [_presentingController  release];
    
    [super dealloc];
}

#pragma mark -
#pragma mark Initializers

+ (id)requestForServerAPI:(NSString *)apiKey accountUUID:(NSString *)uuid
{
    return [self requestForServerAPI:apiKey accountUUID:uuid tenantID:nil];
}

+ (id)requestForServerAPI:(NSString *)apiKey accountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID
{
    return [self requestForServerAPI:apiKey accountUUID:uuid tenantID:aTenantID infoDictionary:nil];
}

+ (id)requestForServerAPI:(NSString *)apiKey accountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID infoDictionary:(NSDictionary *)infoDictionary;
{
    return [self requestForServerAPI:apiKey accountUUID:uuid tenantID:aTenantID infoDictionary:infoDictionary useAuthentication:YES];
}

+ (id)requestForServerAPI:(NSString *)apiKey accountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID infoDictionary:(NSDictionary *)infoDictionary useAuthentication:(BOOL)useAuthentication
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"ServerURLs" ofType:@"plist"];
    NSDictionary *dictionary = [[[NSDictionary alloc] initWithContentsOfFile:path] autorelease];
    
    NSString *tokenizedURLString = [dictionary objectForKey:apiKey];
    NSMutableDictionary *tokens = [self tokenDictionaryRepresentationForAccountInfo:[[AccountManager sharedManager] accountInfoForUUID:uuid] 
                                                                           tenantID:aTenantID infoDictionary:infoDictionary];
    tokenizedURLString = [self removeWebappSlashFromUrl:tokenizedURLString andTokens:tokens];
    
    NSString *urlString = [tokenizedURLString stringBySubstitutingTokensInDict:tokens];
    NSURL *newURL = [NSURL URLWithString:urlString];
    
    NSLog(@"\nAPIKEY: %@\n\t%@\n\t%@\n\t",apiKey,tokenizedURLString,urlString);
    
    id base = [self requestWithURL:newURL accountUUID:uuid useAuthentication:useAuthentication];
    [base addCloudRequestHeader];
    [base setServerAPI:apiKey];
    [base setTenantID:aTenantID];
    [base setValidatesSecureCertificate:userPrefValidateSSLCertificate()];
    
    if (infoDictionary)
        [base setUserInfo:infoDictionary];
    
    return base;
}

/*
 * Used to remove the extra slash in the cases the parameter for the webapp token is empty
 */
+ (NSString *)removeWebappSlashFromUrl:(NSString *)tokenizedUrl andTokens:(NSDictionary *)tokens
{
    NSString *webappKey = @"WEBAPP";
    NSString *token = @"$";
    NSString *webapp = [tokens objectForKey:webappKey];
    
    if(!webapp || [webapp isEqualToString:[NSString string]])
    {
        tokenizedUrl = [tokenizedUrl stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"/%@%@", token, webappKey] withString:@""];
    }
    
    return tokenizedUrl;
}

+ (id)requestWithURL:(NSURL *)newURL accountUUID:(NSString *)uuid
{
    return [self requestWithURL:newURL accountUUID:uuid useAuthentication:YES];
}

+ (id)requestWithURL:(NSURL *)newURL accountUUID:(NSString *)uuid useAuthentication:(BOOL)useAuthentication
{
    id base = [[[self alloc] initWithURL:newURL accountUUID:uuid useAuthentication:useAuthentication] autorelease];
    return base;
}

- (id)initWithURL:(NSURL *)newURL accountUUID:(NSString *)uuid
{
    return [self initWithURL:newURL accountUUID:uuid useAuthentication:YES];
}

- (id)initWithURL:(NSURL *)newURL accountUUID:(NSString *)uuid useAuthentication:(BOOL)useAuthentication
{
    if (uuid == nil) {
        uuid = [[[[AccountManager sharedManager] allAccounts] lastObject] uuid];
        NSLog(@"-- WARNING -- Request encountered nil uuid, using last configured account");
    }
    
    
    self = [super initWithURL:newURL];
    
    if(self)
    {
        [self setAccountUUID:uuid];
        [self setAccountInfo:[[AccountManager sharedManager] accountInfoForUUID:uuid]];
        
        [self addCloudRequestHeader];
        NSString *passwordForAccount = [BaseHTTPRequest passwordForAccount:self.accountInfo];
        if(passwordForAccount && useAuthentication)
        {
            [self addBasicAuthenticationHeaderWithUsername:[self.accountInfo username] andPassword:passwordForAccount];
        }
        [self setShouldContinueWhenAppEntersBackground:YES];
        [self setTimeOutSeconds:20];
        [self setValidatesSecureCertificate:userPrefValidateSSLCertificate()];
        [self setUseSessionPersistence:NO];
        
        [self setAuthenticationNeededBlock:^{
            [self performSelectorOnMainThread:@selector(presentPasswordPrompt) withObject:nil waitUntilDone:NO];
        }];
    }
    
    return self;    
}

- (void)presentPasswordPrompt
{
    if(self.delegate && self.willPromptPasswordSelector && [self.delegate respondsToSelector:self.willPromptPasswordSelector])
    {
        [self.delegate performSelector:self.willPromptPasswordSelector withObject:self];
    }
    self.passwordPrompt = [[[PasswordPromptViewController alloc] initWithAccountInfo:self.accountInfo] autorelease];
    [self.passwordPrompt setDelegate:self];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:self.passwordPrompt];
    [nav setModalPresentationStyle:UIModalPresentationFormSheet];
    [nav setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    
    AlfrescoAppDelegate *appDelegate = (AlfrescoAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.presentingController = [appDelegate mainViewController];
    [self.presentingController presentModalViewController:nav animated:YES];
    [nav release];

}

+ (NSString *)passwordForAccount:(AccountInfo *)anAccountInfo
{
    if([anAccountInfo password] && ![[anAccountInfo password] isEqualToString:[NSString string]])
    {
        return [anAccountInfo password];
    }
    
    NSString *sessionPassword = [[SessionKeychainManager sharedManager] passwordForAccountUUID:[anAccountInfo uuid]];
    return sessionPassword;
}

#pragma mark -
#pragma mark METHODS TO DEPRECATE

- (id)initWithURL:(NSURL *)newURL 
{
    NSLog(@"-- WARNING -- INCORRECT METHOD BEING USED !!! -(id)initWithURL:");
    return [self initWithURL:newURL accountUUID:nil];
}
+ (id)requestWithURL:(NSURL *)newURL
{
    NSLog(@"-- WARNING -- INCORRECT METHOD BEING USED !!! +(id)requestWithURL:");
    return [self requestWithURL:newURL accountUUID:nil];
}
+ (id)requestWithURL:(NSURL *)newURL usingCache:(id <ASICacheDelegate>)cache
{
    NSLog(@"-- WARNING -- INCORRECT METHOD BEING USED !!! +(id)requestWithURL:usingCache:");
    return [super requestWithURL:newURL usingCache:cache];
}
+ (id)requestWithURL:(NSURL *)newURL usingCache:(id <ASICacheDelegate>)cache andCachePolicy:(ASICachePolicy)policy
{
    NSLog(@"-- WARNING -- INCORRECT METHOD BEING USED !!! +(id)requestWithURL:usingCache:andCachePolicy:");
    return [super requestWithURL:newURL usingCache:cache andCachePolicy:policy];
}


#pragma mark - 
#pragma mark ASIHTTPRequest Delegate Methods

- (void)requestFinishedWithSuccessResponse
{
    
}

- (void)requestFinished
{
#if MOBILE_DEBUG
    NSLog(@"%d: %@", self.responseStatusCode, self.responseString);
#endif
    if ([self responseStatusCode] >= 400) 
    {
        NSInteger theCode = ASIUnhandledExceptionError;
        switch ([self responseStatusCode]) {
            case 401:
                theCode = ASIAuthenticationErrorType;
                break;
                
            default:
                break;
        }
        
        [self failWithError:[NSError errorWithDomain:NetworkRequestErrorDomain code:theCode userInfo:nil]];
        return;
        
    }
    
    [self requestFinishedWithSuccessResponse];
    [super requestFinished];
}

- (void)failWithError:(NSError *)theError 
{
    #if MOBILE_DEBUG
    NSLog(@"\n\n***\nRequestFailure\t%@: StatusCode:%d StatusMessage:%@\n\t%@\nURL:%@\n***\n\n", 
          self.class, [self responseStatusCode], [self responseStatusMessage], theError, self.url);
    NSLog(@"%@", [self responseString]);
    #endif
    
    if (self.suppressAllErrors)
    {
        // just log the error if we're supressing all errors
        NSLog(@"%@: %d %@\r\n%@", self.class, [self responseStatusCode], [self responseStatusMessage], theError);
    }
    else
    {
        // if it's an auth failure
        if ([[theError domain] isEqualToString:NetworkRequestErrorDomain])
        {
            if ([theError code] == ASIAuthenticationErrorType)
            {
                NSString *authenticationFailureMessageForAccount = [NSString stringWithFormat:NSLocalizedString(@"authenticationFailureMessageForAccount", @"Please check your username and password in the iPhone settings for Fresh Docs"), 
                                                                    self.accountInfo.description];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"authenticationFailureTitle", @"Authentication Failure Title Text 'Authentication Failure'")
                                                                message:authenticationFailureMessageForAccount
                                                               delegate:nil 
                                                      cancelButtonTitle:NSLocalizedString(@"okayButtonText", @"OK button text")
                                                      otherButtonTitles:nil];
                [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
                [alert release];
            }
            else if ((([self responseStatusCode] == 500) && self.show500StatusError) 
                     || ((self.responseStatusCode >= 400) && (self.responseStatusCode != 500))) 
            {
                NSString *msg = [[NSString alloc] initWithFormat:@"%@ %@\n\n%@", 
                                 NSLocalizedString(@"connectionErrorMessage", @"The server returned an error connecting to URL. Localized Error Message"), 
                                 [self.url absoluteURL], [theError localizedDescription]];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"connectionErrorTitle", @"Connection error")
                                                                message:msg delegate:nil 
                                                      cancelButtonTitle:NSLocalizedString(@"okayButtonText", @"OK button text")
                                                      otherButtonTitles:nil];
                [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
                [alert release];
                [msg release];
            }
            else if([theError code] == ASIConnectionFailureErrorType || [theError code] == ASIRequestTimedOutErrorType)
            {
                NSString *failureMessage = [NSString stringWithFormat:NSLocalizedString(@"serviceDocumentRequestFailureMessage", @"Failed to connect to the repository"),
                                            [self url]];
                
                UIAlertView *sdFailureAlert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"serviceDocumentRequestFailureTitle", @"Error")
                                                                          message:failureMessage
                                                                         delegate:nil 
                                                                cancelButtonTitle:NSLocalizedString(@"Continue", nil)
                                                                otherButtonTitles:nil] autorelease];
                [sdFailureAlert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
            }
        }
        else 
        {
            NSLog(@"%@", theError);
        }
    }
    

    [super failWithError:theError];
}

- (void)cancel
{
    [super cancel];
}

#pragma mark -
#pragma mark PasswordPromptDelegate methods
- (void)passwordPrompt:(PasswordPromptViewController *)passwordPrompt savedWithPassword:(NSString *)newPassword
{
    if(self.delegate && self.finishedPromptPasswordSelector && [self.delegate respondsToSelector:self.finishedPromptPasswordSelector])
    {
        [self.delegate performSelector:self.finishedPromptPasswordSelector withObject:self];
    }
    [[SessionKeychainManager sharedManager] savePassword:newPassword forAccountUUID:self.accountInfo.uuid];
    
    [self setUsername:self.accountInfo.username];
    [self setPassword:newPassword];
    [self retryUsingSuppliedCredentials];

    [self.presentingController dismissModalViewControllerAnimated:YES];
    self.presentingController = nil;
}

- (void)passwordPromptWasCancelled:(PasswordPromptViewController *)passwordPrompt
{
    if(self.delegate && self.finishedPromptPasswordSelector && [self.delegate respondsToSelector:self.finishedPromptPasswordSelector])
    {
        [self.delegate performSelector:self.finishedPromptPasswordSelector withObject:self];
    }
    [self cancelAuthentication];
    [self.presentingController dismissModalViewControllerAnimated:YES];
    self.presentingController = nil;
}

#pragma mark -
#pragma mark Utility Methods

- (BOOL)responseSuccessful
{
	return ((self.responseStatusCode >= 200) && (self.responseStatusCode <= 299));
}

+ (NSObject *)safeValueForObject:(NSObject *)object
{
    if (nil == object) {
        return @"";
    }
    
    return object;
}

+ (NSMutableDictionary *)tokenDictionaryRepresentationForAccountInfo:(AccountInfo *)info tenantID:(NSString *)aTenantID infoDictionary:(NSDictionary *)infoDictionary
{
    if (info.serviceDocumentRequestPath == nil) 
    {
        [info setServiceDocumentRequestPath:@""];
    }
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    if (info.port == nil || ([info.port length] == 0))
    {
        info.port = ((NSOrderedSame == [info.protocol caseInsensitiveCompare:kFDHTTP_Protocol]) ? kFDHTTP_DefaultPort : kFDHTTPS_DefaultPort);
    }
    
    [dict setObject:[self safeValueForObject:info.vendor] forKey:@"VENDOR"];
    [dict setObject:[self safeValueForObject:info.description] forKey:@"DESCRIPTION"];
    [dict setObject:[self safeValueForObject:info.protocol] forKey:@"PROTOCOL"];
    [dict setObject:[self safeValueForObject:info.hostname] forKey:@"HOSTNAME"];
    [dict setObject:[self safeValueForObject:info.port] forKey:@"PORT"];
    [dict setObject:[self safeValueForObject:info.username] forKey:@"USERNAME"];
    [dict setObject:[self safeValueForObject:info.serviceDocumentRequestPath] forKey:@"SERVICE_DOC"];
    
    if ([info.vendor isEqualToString:kFDAlfresco_RepositoryVendorName]) 
    {
        static NSString *cmis = @"cmis";
        
        // Determine webapp value
        NSString *webappValue = nil;
        NSRange range = [[info.serviceDocumentRequestPath lastPathComponent] rangeOfString:cmis options:NSCaseInsensitiveSearch];
        if (NSNotFound == range.location) 
        {
            // we did not find 'cmis' in the last path component of the URL, assume
            // that the URL is the path to the alfresco webapp
            webappValue = info.serviceDocumentRequestPath;
        }
        else 
        {
            // Assume standard request path to the cmis service document
            NSArray *components = [[info.serviceDocumentRequestPath substringFromIndex:1] componentsSeparatedByString:@"/"];
            webappValue = (([components count] == 2) ? @"" : [components objectAtIndex:0]);
        }
        if ([webappValue hasPrefix:@"/"]) 
        {
            webappValue = [webappValue substringFromIndex:1];
        }
        [dict setObject:[self safeValueForObject:webappValue] forKey:@"WEBAPP"];
        
        
        // Determine the service component of the request path
        NSString *serviceComponent = @"service";
        if ([info isMultitenant] && aTenantID)
        {
            serviceComponent = [NSString stringWithFormat:@"%@/%@", @"a", aTenantID];
        }
        [dict setObject:[self safeValueForObject:serviceComponent] forKey:@"SERVICE"];
    }
    
    NSArray *allKeysFromInfoDict = [infoDictionary allKeys];
    for (NSString *key in allKeysFromInfoDict) 
    {
        if ([key isEqualToString:@"NodeRef"]) 
        {
            NodeRef *nodeRef = [infoDictionary objectForKey:key];
            [dict setObject:[self safeValueForObject:nodeRef.storeId] forKey:@"STOREID"];
            [dict setObject:[self safeValueForObject:nodeRef.storeType] forKey:@"STORETYPE"];
            [dict setObject:[self safeValueForObject:nodeRef.objectId] forKey:@"ID"];
        }
        else
        {
            [dict setObject:[infoDictionary objectForKey:key] forKey:key];
        }
    }
    
    return dict;
}

- (void)addCloudRequestHeader
{
    if ([self.accountInfo isMultitenant])
    {
        NSString *cloudKeyValue = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"AlfrescoCloudAPIKey"];
        [self addRequestHeader:@"key" value:cloudKeyValue];
    }
}

@end