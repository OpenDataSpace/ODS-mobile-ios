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
#import "NSString+TokenReplacement.h"
#import "NodeRef.h"
#import "Utility.h"
#import "AlfrescoAppDelegate.h"
#import "SessionKeychainManager.h"
#import "PasswordPromptQueue.h"
#import "AccountStatusService.h"
#import "NSNotificationCenter+CustomNotification.h"
#import "ConnectivityManager.h"
#import "CertificateManager.h"
#import "FDCertificate.h"
#import <Security/SecureTransport.h>

NSString * const kBaseRequestStatusCodeKey = @"NSHTTPPropertyStatusCodeKey";

// ServerAPI Keys
NSString * const kServerAPISiteCollection = @"ServerAPISiteCollection";
NSString * const kServerAPISearchURL = @"ServerAPISearchURL";
NSString * const kServerAPICMISServiceInfo = @"ServerAPICMISServiceInfo";
NSString * const kServerAPINode = @"ServerAPINode";
NSString * const kServerAPIActivitiesUserFeed = @"ServerAPIActivitiesUserFeed";
NSString * const kServerAPIFavorites = @"ServerAPIFavorites";
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
NSString * const kServerAPIMyTaskCollection = @"ServerAPIMyTaskCollection";
NSString * const kServerAPIStartedByMeTaskCollection = @"ServerAPIStartedByMeTaskCollection";
NSString * const kServerAPITaskItemCollection = @"ServerAPITaskItemCollection";
NSString * const kServerAPITaskItemDetailsCollection = @"ServerAPITaskItemDetailsCollection";
NSString * const kServerAPITaskCreate = @"ServerAPITaskCreate";
NSString * const kServerAPITaskTakeTransition = @"ServerAPITaskTakeTransition";
NSString * const kServerAPITaskUpdate = @"ServerAPITaskUpdate";
NSString * const kServerAPIWorkflowInstance = @"ServerAPIWorkflowInstance";
NSString * const kServerAPIPersonAvatar = @"ServerAPIPersonAvatar";
NSString * const kServerAPINodeThumbnail = @"ServerAPINodeThumbnail";
NSString * const kServerAPIPeopleCollection = @"ServerAPIPeopleCollection";
NSString * const kServerAPIPersonNodeRef = @"ServerAPIPersonNodeRef";
NSString * const kServerAPISiteInvitations = @"ServerAPISiteInvitations";
NSString * const kServerAPISiteRequestToJoin = @"ServerAPISiteRequestToJoin";
NSString * const kServerAPISiteCancelJoinRequest = @"ServerAPISiteCancelJoinRequest";
NSString * const kServerAPISiteJoin = @"ServerAPISiteJoin";
NSString * const kServerAPISiteLeave = @"ServerAPISiteLeave";
NSString * const kServerAPINodeLocation = @"ServerAPINodeLocation";
NSString * const kServerAPIWorkflowDefinitions = @"ServerAPIWorkflowDefinitions";
NSString * const kServerAPIClasses = @"ServerAPIClasses";


NSTimeInterval const kBaseRequestDefaultTimeoutSeconds = 20;

@interface BaseHTTPRequest ()

+ (NSMutableDictionary *)tokenDictionaryRepresentationForAccountInfo:(AccountInfo *)info tenantID:(NSString *)aTenantID infoDictionary:(NSDictionary *)infoDictionary;
+ (NSString *)removeWebappSlashFromUrl:(NSString *)tokenizedUrl andTokens:(NSDictionary *)tokens;

- (void)addCloudRequestHeader;
- (void)presentPasswordPrompt;
- (void)applyRequestTimeOutValue;
- (void)setSuccessAccountStatus;
- (void)updateAccountStatus:(FDAccountStatus)accountStatus;
@end


@implementation BaseHTTPRequest

@synthesize ignore500StatusError = _ignore500StatusError;
@synthesize suppressAllErrors = _suppressAllErrors;
@synthesize serverAPI = _serverAPI;
@synthesize accountUUID = _accountUUID;
@synthesize accountInfo = _accountInfo;
@synthesize tenantID = _tenantID;
@synthesize willPromptPasswordSelector = _willPromptPasswordSelector;
@synthesize finishedPromptPasswordSelector = _finishedPromptPasswordSelector;
@synthesize cancelledPromptPasswordSelector = _cancelledPromptPasswordSelector;
@synthesize passwordPromptPresenter = _passwordPromptPresenter;
@synthesize promptPasswordDelegate = _promptPasswordDelegate;

- (void)dealloc
{
    if (shouldStreamPostDataFromDisk && postBodyFilePath != nil)
    {
        [self removeTemporaryUploadFile];
    }
    _willPromptPasswordSelector = nil;
    _finishedPromptPasswordSelector = nil;
    _cancelledPromptPasswordSelector = nil;
    _passwordPromptPresenter = nil;
    _promptPasswordDelegate = nil;

    [_serverAPI release];
    [_accountUUID release];
    [_accountInfo release];
    [_tenantID release];
    
    [super dealloc];
}

#pragma mark - Initializers

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
    NSString *pathServerURLs = @"ServerURLs";
    
#ifdef OPEN_DATA_SPACE
    pathServerURLs = @"ServerURLs_OpenDataSpace";  //for open data space
#endif
    
    NSString * path = [[NSBundle mainBundle] pathForResource:pathServerURLs ofType:@"plist"];
    
    NSDictionary *dictionary = [[[NSDictionary alloc] initWithContentsOfFile:path] autorelease];
    
    NSString *tokenizedURLString = [dictionary objectForKey:apiKey];

    if (tokenizedURLString == nil)
    {
        AlfrescoLogDebug(@"-- WARNING -- did not find URL entry for key '%@'", apiKey);
    }

    NSMutableDictionary *tokens = [self tokenDictionaryRepresentationForAccountInfo:[[AccountManager sharedManager] accountInfoForUUID:uuid] 
                                                                           tenantID:aTenantID infoDictionary:infoDictionary];
    tokenizedURLString = [self removeWebappSlashFromUrl:tokenizedURLString andTokens:tokens];
    
    NSString *urlString = [tokenizedURLString stringBySubstitutingTokensInDict:tokens];
    urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *newURL = [NSURL URLWithString:urlString];
    
    AlfrescoLogDebug(@"\nAPIKEY: %@\n\t%@\n\t%@\n\t",apiKey,tokenizedURLString,urlString);
    
    id base = [self requestWithURL:newURL accountUUID:uuid useAuthentication:useAuthentication];
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
    
    if (!webapp || [webapp isEqualToString:[NSString string]])
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
    AlfrescoLogTrace(@"BaseHTTPRequest for URL: %@", newURL);

    if (uuid == nil)
    {
        uuid = [[[[AccountManager sharedManager] allAccounts] lastObject] uuid];
        AlfrescoLogDebug(@"-- WARNING -- Request encountered nil uuid, using last configured account");
    }
    
    self = [super initWithURL:newURL];
    
    if (self)
    {
        [self setAccountUUID:uuid];
        [self setAccountInfo:[[AccountManager sharedManager] accountInfoForUUID:uuid]];
        
        [self addCloudRequestHeader];
        [self addAcceptLanguageHeader];
        NSString *passwordForAccount = [BaseHTTPRequest passwordForAccount:self.accountInfo];
        if (passwordForAccount && useAuthentication)
        {
            //We are causing that, in the case the stored credentials are wrong, the user gets an alert saying that
            //the credentials were wrong, so it knows why is being presented with a password prompt
            hasPresentedPrompt = YES;
            [self addBasicAuthenticationHeaderWithUsername:[self.accountInfo username] andPassword:passwordForAccount];
        }
        [self setShouldContinueWhenAppEntersBackground:YES];
        [self applyRequestTimeOutValue];
        [self setValidatesSecureCertificate:userPrefValidateSSLCertificate()];
        [self setUseSessionPersistence:NO];
        
        if (useAuthentication)
        {
            [BaseHTTPRequest addClientCertificatesFromAccount:self.accountInfo toRequest:self];
        }
        
        __block id blockSelf = self;
        [self setAuthenticationNeededBlock:^{
            [blockSelf performSelectorOnMainThread:@selector(presentPasswordPrompt) withObject:nil waitUntilDone:NO];
        }];
    }
    
    return self;    
}

- (void)presentPasswordPrompt
{
    //If there's a password saved for the account it means that the authentication failed
    //We mark the account status as Invalid Credentials
    NSString *passwordForAccount = [BaseHTTPRequest passwordForAccount:self.accountInfo];
    if (passwordForAccount)
    {
        [self updateAccountStatus:FDAccountStatusInvalidCredentials];
    }
    
    if (hasPresentedPrompt)
    {
        //This is not the first time we are going to present the prompt, this means the last credentials supplied were wrong
        //We should show an alert and also clear the past credentials
        displayErrorMessageWithTitle(NSLocalizedString(@"accountdetails.alert.save.validationerror", @"Validation Error"), NSLocalizedString(@"passwordPrompt.title", "Secure Credentials"));
        [[SessionKeychainManager sharedManager] removePasswordForAccountUUID:self.accountInfo.uuid];
    }
    [[PasswordPromptQueue sharedInstance] addPromptForRequest:self];
}

+ (void)clearPasswordPromptQueue
{
    [[PasswordPromptQueue sharedInstance] clearRequestQueue];
}

+ (NSString *)passwordForAccount:(AccountInfo *)anAccountInfo
{
    if ([anAccountInfo password] && ![[anAccountInfo password] isEqualToString:[NSString string]])
    {
        return [anAccountInfo password];
    }
    
    NSString *sessionPassword = [[SessionKeychainManager sharedManager] passwordForAccountUUID:[anAccountInfo uuid]];
    return sessionPassword;
}

#pragma mark - ASIHTTPRequest Delegate Methods

- (void)requestFinishedWithSuccessResponse
{
}

- (void)requestFinished
{
    AlfrescoLogTrace(@"%d: %@", self.responseStatusCode, self.responseString);

    if ([self responseStatusCode] >= 400)
    {
        NSInteger theCode = ASIUnhandledExceptionError;
        [self failWithError:[NSError errorWithDomain:NetworkRequestErrorDomain code:theCode userInfo:nil]];
        return;
    }
    
    [self setSuccessAccountStatus];
    [self requestFinishedWithSuccessResponse];
    [super requestFinished];
}

- (void)failWithError:(NSError *)theError
{
    if (![NSThread isMainThread])
    {
        [self performSelectorOnMainThread:@selector(failWithError:) withObject:theError waitUntilDone:NO];
        return;
    }
    
    AlfrescoLogTrace(@"\n\n***\nRequestFailure\t%@: StatusCode:%d StatusMessage:%@\n\t%@\nURL:%@\n***\n\n", self.class, [self responseStatusCode], [self responseStatusMessage], theError, self.url);
    AlfrescoLogTrace(@"%@", [self responseString]);
    
    BOOL hasNetworkConnection = [[ConnectivityManager sharedManager] hasInternetConnection];
    // When no connection is available we should not mark any account with error
    if (!self.suppressAccountStatusUpdateOnError
       && [self.accountInfo accountStatus] != FDAccountStatusAwaitingVerification
       && hasNetworkConnection
       && self.responseStatusCode != 401
       && self.responseStatusCode != 404
       && self.responseStatusCode != 409
       && theError.code != ASIRequestCancelledErrorType
       && !(self.responseStatusCode == 500 && self.ignore500StatusError))
    {
        FDAccountStatus errorStatus = FDAccountStatusConnectionError;
        // Try to determine if the certificate has expired
        // the priority is to mark an account as with expired certificate
        AlfrescoLogDebug(@"Error code: %d", theError.code);
        
        NSError *underlyingError = [theError.userInfo objectForKey:NSUnderlyingErrorKey];
        
        if ([theError.domain isEqualToString:NetworkRequestErrorDomain] && underlyingError.code == errSSLPeerCertExpired)
        { 
            errorStatus = FDAccountStatusInvalidCertificate;
        }
        [self updateAccountStatus:errorStatus];
    }
    
    if (self.suppressAllErrors)
    {
        // just log the error if we're supressing all errors
        AlfrescoLogDebug(@"%@: %d %@\r\n%@", self.class, [self responseStatusCode], [self responseStatusMessage], theError);
    }
    else
    {
        // if it's an auth failure
        if ([theError.domain isEqualToString:NetworkRequestErrorDomain])
        {
            //The first check is for internet connection, we show the Offline Mode AlertView in those cases
            if (!hasNetworkConnection || (theError.code == ASIConnectionFailureErrorType || theError.code == ASIRequestTimedOutErrorType))
            {
                showConnectionErrorMessageWithError(self, theError);
            }
            else if (theError.code == ASIAuthenticationErrorType)
            {
                NSString *authenticationFailureMessageForAccount = [NSString stringWithFormat:NSLocalizedString(@"authenticationFailureMessageForAccount", @"Please check your username and password in the iPhone settings for Fresh Docs"), self.accountInfo.description];
                displayErrorMessageWithTitle(authenticationFailureMessageForAccount, NSLocalizedString(@"authenticationFailureTitle", @"Authentication Failure Title Text 'Authentication Failure'"));
            }
            else if (self.responseStatusCode >= 400 && (self.responseStatusCode != 500 || !self.ignore500StatusError))
            {
                if (self.responseStatusCode == 404)
                {
                    displayErrorMessageWithTitle(@"Unable to locate content for requested resource", @"Resource Unavailable");
                }
                else
                {
                    showConnectionErrorMessageWithError(self, theError);
                }
            }
        }
        else 
        {
            AlfrescoLogDebug(@"%@", theError);
        }
    }

    [super failWithError:theError];
}

- (void)cancel
{
    [super cancel];
}



#pragma mark - Utility Methods

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
#ifdef OPEN_DATA_SPACE
    [dict setObject:[self safeValueForObject:info.serviceDocumentRequestPath] forKey:@"SERVICE"];  //for open data space
#endif
    
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
        [self addRequestHeader:@"key" value:externalAPIKey(APIKeyAlfrescoCloud)];
    }
}

- (void)addAcceptLanguageHeader
{
    NSString *preferredLanguageCodes = [[NSLocale preferredLanguages] componentsJoinedByString:@", "];
    [self addRequestHeader:@"Accept-Language" value:[NSString stringWithFormat:@"%@, en-us;q=0.8", preferredLanguageCodes]];
}

- (void)applyRequestTimeOutValue
{
    NSTimeInterval timeout = kBaseRequestDefaultTimeoutSeconds;
    if ([self.accountInfo isMultitenant])
    {
        timeout += timeout;
    }
    [self setTimeOutSeconds:timeout];

    AlfrescoLogTrace(@"Using timeOut value: %f for request to URL %@", timeout, self.url);
}

- (void)setSuccessAccountStatus
{
    FDAccountStatus accountStatus = self.accountInfo.accountStatus;
    if (accountStatus != FDAccountStatusAwaitingVerification)
    {
        [self.accountInfo.accountStatusInfo setSuccessTimestamp:[[NSDate date] timeIntervalSince1970]];
        if (accountStatus != FDAccountStatusInactive)
        {
            [self updateAccountStatus:FDAccountStatusActive];
            [[AccountStatusService sharedService] synchronize];
        }
    }
}

- (void)updateAccountStatus:(FDAccountStatus)accountStatus
{
    if (accountStatus != [self.accountInfo accountStatus])
    {
        [self.accountInfo setAccountStatus:accountStatus];
        [[AccountStatusService sharedService] synchronize];
        [[NSNotificationCenter defaultCenter] postAccountListUpdatedNotification:
            [NSDictionary dictionaryWithObjectsAndKeys:[self.accountInfo uuid],@"uuid", [self.accountInfo accountStatusInfo], @"accountStatus",nil]];
        [[NSNotificationCenter defaultCenter] postAccountStatusChangedNotification:
            [NSDictionary dictionaryWithObjectsAndKeys:[self.accountInfo uuid],@"uuid", [self.accountInfo accountStatusInfo], @"accountStatus",nil]];
    }
}

+ (void)addClientCertificatesFromAccount:(AccountInfo *)accountInfo toRequest:(ASIHTTPRequest *)request
{
    FDCertificate *certificateWrapper = [accountInfo certificateWrapper];
    if (certificateWrapper)
    {
        [request setClientCertificateIdentity:[certificateWrapper identityRef]];
        [request setClientCertificates:[certificateWrapper certificateChain]];
    }
}

/**
 * Note: The following functions don't really adhere to DRY principles but are deliberately so for performance reasons
 */
- (NSDictionary *)dictionaryFromJSONResponse
{
    NSError *jsonError = nil;
    NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:[self.responseString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&jsonError];
    
    return (jsonError == nil) ? jsonObject : nil;
}

- (NSArray *)arrayFromJSONResponse
{
    NSError *jsonError = nil;
    NSArray *jsonObject = [NSJSONSerialization JSONObjectWithData:[self.responseString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&jsonError];
    
    return (jsonError == nil) ? jsonObject : nil;
}

- (NSMutableDictionary *)mutableDictionaryFromJSONResponseWithOptions:(NSJSONReadingOptions)options
{
    NSError *jsonError = nil;
    NSMutableDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:[self.responseString dataUsingEncoding:NSUTF8StringEncoding] options:options error:&jsonError];
    
    return (jsonError == nil) ? jsonObject : nil;
}

- (NSMutableArray *)mutableArrayFromJSONResponseWithOptions:(NSJSONReadingOptions)options
{
    NSError *jsonError = nil;
    NSMutableArray *jsonObject = [NSJSONSerialization JSONObjectWithData:[self.responseString dataUsingEncoding:NSUTF8StringEncoding] options:options error:&jsonError];
    
    return (jsonError == nil) ? jsonObject : nil;
}

- (NSMutableData *)mutableDataFromJSONObject:(id)jsonObject
{
    NSError *jsonError = nil;
    if ([NSJSONSerialization isValidJSONObject:jsonObject])
    {
        NSData *data = [NSJSONSerialization dataWithJSONObject:jsonObject options:0 error:&jsonError];
        if (jsonError == nil)
        {
            return [NSMutableData dataWithData:data];
        }
    }
    return nil;
}


@end
