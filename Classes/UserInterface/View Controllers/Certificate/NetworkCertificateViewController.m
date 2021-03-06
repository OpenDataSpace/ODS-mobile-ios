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
//  NetworkCertificateViewController.m
//
//

#import "NetworkCertificateViewController.h"
#import "Utility.h"
#import "IFTextCellController.h"
#import "IFTemporaryModel.h"
#import "NSString+Utils.h"
#import "ASIHTTPRequest.h"
#import "MBProgressHUD.h"
#import "FileUtils.h"

NSString * const kCertificateFileExtension = @"p12";
NSString * const kNetworkCertificateURLKey = @"certificateURL";
NSString * const kNetworkCertificateUsernameKey = @"urlUsername";
NSString * const kNetworkCertificatePasswordKey = @"urlPassword";

@interface NetworkCertificateViewController ()

@end

@implementation NetworkCertificateViewController
@synthesize target = _target;
@synthesize action = _action;

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIBarButtonItem *saveButton = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"certificate-network.next", @"Network certificate next button")
                                                                    style:UIBarButtonItemStyleDone
                                                                   target:self
                                                                   action:@selector(saveButtonAction:)] autorelease];
    styleButtonAsDefaultAction(saveButton);
    [self.navigationItem setRightBarButtonItem:saveButton];
    [saveButton setEnabled:NO];
    
    [self setTitle:NSLocalizedString(@"certificate-network.title", @"Download From Server")];
}

- (void)saveButtonAction:(id)sender
{
    NSString *urlString = [self.model objectForKey:@"certificateURL"];
    NSURL *url = nil;
    NSString *username = [self.model objectForKey:@"urlUsername"];
    NSString *password = [self.model objectForKey:@"urlPassword"];
    
    // Validate if the url specifies a protocol, if not the http:// should be added
    if ([urlString hasPrefix:@"http://"] || [urlString hasPrefix:@"https://"])
    {
        url = [NSURL URLWithString:urlString];
    }
    else
    {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@",urlString]];
        // Reflecting the url change in the UI
        [self.model setObject:[url absoluteString] forKey:@"certificateURL"];
        [self updateAndRefresh];
    }
    
    ASIHTTPRequest *certificateRequest = [ASIHTTPRequest requestWithURL:url];
    [certificateRequest setCachePolicy:ASIDoNotReadFromCacheCachePolicy|ASIDoNotWriteToCacheCachePolicy];
    // We try to use the last part of the URL to as the filename for the certificate
    NSString *filename = [url lastPathComponent];
    if (![filename isNotEmpty])
    {
        // If non could be determined, a UUID is used for the filename
        filename = [NSString generateUUID];
    }
    
    // If the file does not have the .p12 extension, we append it
    if (![[filename pathExtension] isEqualToCaseInsensitiveString:kCertificateFileExtension])
    {
        [filename stringByAppendingPathExtension:kCertificateFileExtension];
    }
    
    [certificateRequest setDownloadDestinationPath:[FileUtils pathToTempFile:filename]];
    if ([username isNotEmpty] || [password isNotEmpty])
    {
        [certificateRequest addBasicAuthenticationHeaderWithUsername:username andPassword:password];
    }
    
    __block MBProgressHUD *hud = createAndShowProgressHUDForView(self.navigationController.view);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [certificateRequest startSynchronous];
        NSData *fileData = [NSData dataWithContentsOfFile:certificateRequest.downloadDestinationPath];
        
        // Only 2XX responses are successful responses
        if (certificateRequest.responseStatusCode / 100 != 2 || [fileData length] == 0)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                stopProgressHUD(hud);
                displayErrorMessageWithTitle(NSLocalizedString(@"certificate-network.connection-error.message", @"Connection error message when downloading a certificate"), NSLocalizedString(@"certificate-network.title", @"Install From Network"));
            });
        }
        // We validate the request's content type against the supportedMIMETypes in the NetworkCertificateViewController
        // report the error accordingly
        else if(![[NetworkCertificateViewController supportedMIMETypes] containsObject:[[certificateRequest responseHeaders] objectForKey:@"Content-Type"]])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                stopProgressHUD(hud);
                displayErrorMessageWithTitle(NSLocalizedString(@"certificate-network.wrong-contentType.message", @"Wrong content type message when downloading a certificate"), NSLocalizedString(@"certificate-network.title", @"Install From Network"));
            });
        }
        // The OK case, the action is delegated to a target and the downloaded certificate path is
        // provided
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                stopProgressHUD(hud);
                if (self.target && [self.target respondsToSelector:self.action])
                {
                    [self.target performSelector:self.action withObject:certificateRequest.downloadDestinationPath];
                }
            });
        }
    });
}

- (void)constructTableGroups
{
    if (!self.model)
    {
        [self setModel:[[[IFTemporaryModel alloc] init] autorelease]];
    }
    
    NSMutableArray *headers = [NSMutableArray array];
    NSMutableArray *groups = [NSMutableArray array];
    NSMutableArray *mainGroup = [NSMutableArray array];
    
    [headers addObject:@""];
    [groups addObject:mainGroup];
    
    IFTextCellController *urlCell = [[[IFTextCellController alloc] initWithLabel:NSLocalizedString(@"certificate-network.fields.url", @"Label for the URL field")
                                                                  andPlaceholder:NSLocalizedString(@"accountdetails.placeholder.required", @"required")
                                                                           atKey:@"certificateURL"
                                                                         inModel:self.model] autorelease];
    [urlCell setKeyboardType:UIKeyboardTypeURL];
    [urlCell setBackgroundColor:[UIColor whiteColor]];
    [urlCell setReturnKeyType:UIReturnKeyNext];
    [urlCell setUpdateTarget:self];
    [urlCell setEditChangedAction:@selector(urlChanged:)];
    [mainGroup addObject:urlCell];
    IFTextCellController *usernameCell = [[[IFTextCellController alloc] initWithLabel:NSLocalizedString(@"certificate-network.fields.username", @"Label for the Username field")
                                                                       andPlaceholder:NSLocalizedString(@"accountdetails.placeholder.optional", @"optional")
                                                                                atKey:@"urlUsername"
                                                                              inModel:self.model] autorelease];
    [usernameCell setKeyboardType:UIKeyboardTypeAlphabet];
    [usernameCell setBackgroundColor:[UIColor whiteColor]];
    [usernameCell setReturnKeyType:UIReturnKeyNext];
    [mainGroup addObject:usernameCell];
    IFTextCellController *passwordCell = [[[IFTextCellController alloc] initWithLabel:NSLocalizedString(@"certificate-network.fields.password", @"Label for the password field")
                                                                       andPlaceholder:NSLocalizedString(@"accountdetails.placeholder.optional", @"optional")
                                                                                atKey:@"urlPassword"
                                                                              inModel:self.model] autorelease];
    [passwordCell setKeyboardType:UIKeyboardTypeAlphabet];
    [passwordCell setSecureTextEntry:YES];
    [passwordCell setBackgroundColor:[UIColor whiteColor]];
    [passwordCell setReturnKeyType:UIReturnKeyDone];
    [mainGroup addObject:passwordCell];
    
    tableHeaders = [headers retain];
    tableGroups = [groups retain];
}

- (void)urlChanged:(id)sender
{
    NSString *url = [self.model objectForKey:@"certificateURL"];
    // No validation, other than a non empty string
    [self.navigationItem.rightBarButtonItem setEnabled:[url isNotEmpty]];
}

#pragma mark - IFCellControllerFirstResponder

- (void)lastResponderIsDone: (NSObject<IFCellController> *)cellController
{
	[super lastResponderIsDone:cellController];
    
    if ([self.navigationItem.rightBarButtonItem isEnabled])
    {
        [self saveButtonAction:cellController];
    }
}

/*
 Snippet from the Apple's AdvancedURLConnections sample project
 */
+ (NSSet *)supportedMIMETypes
{
    static NSSet *  sSupportedCredentialTypes;
    
    if (sSupportedCredentialTypes == nil)
    {
        sSupportedCredentialTypes = [[NSSet alloc] initWithObjects:@"application/x-pkcs12", @"application/x-x509-ca-cert", @"application/pkix-cert", nil];
        assert(sSupportedCredentialTypes != nil);
    }
    return sSupportedCredentialTypes;
}

@end
