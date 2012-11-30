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
//  CertificateManager.m
//
//

#import "CertificateManager.h"
#import "FDCertificate.h"

@implementation CertificateManager

- (ImportCertificateStatus)validatePKCS12:(NSData *)pkcs12Data withPasscode:(NSString *)passcode
{
    ImportCertificateStatus status = ImportCertificateStatusFailed;
    CFArrayRef importedItems = NULL;
    OSStatus err = SecPKCS12Import(
                          (CFDataRef) pkcs12Data,
                          (CFDictionaryRef) [NSDictionary dictionaryWithObjectsAndKeys:
                                             passcode,        kSecImportExportPassphrase,
                                             nil
                                             ],
                          &importedItems
                          );
    if (err == noErr)
    {
        status = ImportCertificateStatusSucceeded;
    }
    else if (err == errSecAuthFailed)
    {
        status = ImportCertificateStatusCancelled;
    }
    
    if (importedItems != NULL) {
        CFRelease(importedItems);
    }
    return status;
}

- (ImportCertificateStatus)validateCertificate:(NSData *)certificateData
{
    SecCertificateRef cert = SecCertificateCreateWithData(NULL, (CFDataRef) certificateData);
    ImportCertificateStatus status = ImportCertificateStatusFailed;
    if (cert != NULL)
    {
        status = ImportCertificateStatusSucceeded;
    }
    return status;
}

- (NSData *)importCertificateData:(NSData *)certificateData importStatus:(ImportCertificateStatus *)status;
{
    OSStatus err;
    SecCertificateRef cert;
    CFDataRef persistentData = nil;
    
    *status = ImportCertificateStatusFailed;
    
    cert = SecCertificateCreateWithData(NULL, (CFDataRef) certificateData);
    if (cert != NULL)
    {
        
        persistentData = [self persistentRefForCertificate:cert andReturnStatus:&err];
        if ( (err == errSecSuccess) || (err == errSecDuplicateItem) ) {
            *status = ImportCertificateStatusSucceeded;
        }
    }
    if (cert != NULL) {
        CFRelease(cert);
    }
    return (NSData *)persistentData;
}

- (CFDataRef)persistentRefForCertificate:(SecCertificateRef)certificate andReturnStatus:(OSStatus *)status
{
    CFTypeRef  persistent_ref = NULL;
    const void *keys[] =   { kSecReturnPersistentRef, kSecValueRef, kSecClass };
    const void *values[] = { kCFBooleanTrue,          certificate, kSecClassCertificate };
    CFDictionaryRef dict = CFDictionaryCreate(NULL, keys, values,
                                              2, NULL, NULL);
    *status = SecItemAdd(dict, &persistent_ref);
    
    if (dict)
        CFRelease(dict);
    
    [(NSData *)persistent_ref autorelease];
    return (CFDataRef)persistent_ref;
}

- (NSData *)importIdentityData:(NSData *)identityData withPasscode:(NSString *)passcode importStatus:(ImportCertificateStatus *)status
{
    OSStatus    err;
    CFArrayRef importedItems;
    NSDictionary  *itemDict = NULL;
    CFDataRef persistentData;
    
    *status = ImportCertificateStatusFailed;
    
    importedItems = NULL;
    
    err = SecPKCS12Import(
                          (CFDataRef) identityData,
                          (CFDictionaryRef) [NSDictionary dictionaryWithObjectsAndKeys:
                                             passcode,        kSecImportExportPassphrase,
                                             nil
                                             ],
                          &importedItems
                          );
    if (err == noErr)
    {
        // +++ If there are multiple identities in the PKCS#12, we only use the first one
        itemDict = [[(NSArray *)importedItems objectAtIndex:0] retain];
        
        assert([itemDict isKindOfClass:[NSDictionary class]]);
        
        SecIdentityRef identity = (SecIdentityRef) [itemDict objectForKey:(NSString *) kSecImportItemIdentity];
        assert(identity != NULL);
        assert( CFGetTypeID(identity) == SecIdentityGetTypeID() );
        OSStatus importStatus;
        
        
        persistentData = [self persistentRefForIdentity:identity andReturnStatus:&importStatus];
        
        if (err == noErr)
        {
            *status = ImportCertificateStatusSucceeded;
        }
    }
    else if (err == errSecAuthFailed)
    {
        *status = ImportCertificateStatusCancelled;
    }
    
    if (importedItems != NULL) {
        CFRelease(importedItems);
    }
    
    return (NSData *)persistentData;
}

- (CFDataRef)persistentRefForIdentity:(SecIdentityRef)identity andReturnStatus:(OSStatus *)status
{
    CFTypeRef  persistent_ref = NULL;
    const void *keys[] =   { kSecReturnPersistentRef, kSecValueRef };
    const void *values[] = { kCFBooleanTrue,          identity };
    CFDictionaryRef dict = CFDictionaryCreate(NULL, keys, values,
                                              2, NULL, NULL);
    *status = SecItemAdd(dict, &persistent_ref);
    
    if (dict)
        CFRelease(dict);
    
    [(NSData *)persistent_ref autorelease];
    return (CFDataRef)persistent_ref;
}

- (FDCertificate *)identityForPersistenceData:(NSData *)persistenceData returnAttributes:(NSDictionary **)attributes;
{
    OSStatus err;
    NSDictionary *identityAttrb = nil;
    
    NSDictionary *queryDict = [NSDictionary dictionaryWithObjectsAndKeys:
                               persistenceData, kSecValuePersistentRef,
                               kCFBooleanTrue, kSecReturnAttributes,
                               kCFBooleanTrue, kSecReturnRef, nil];
    err = SecItemCopyMatching((CFDictionaryRef)queryDict,
                              (CFTypeRef *) &identityAttrb
                              );
    
    if (identityAttrb)
    {
        SecIdentityRef identity = (SecIdentityRef)[identityAttrb objectForKey:kSecValueRef];
        if (attributes)
        {
            *attributes = identityAttrb;
        }
        FDCertificate *certificate = [[[FDCertificate alloc] initWithIdentity:identity andAttributes:identityAttrb] autorelease];
        return certificate;
    }
    else
    {
        return nil;
    }
}

- (FDCertificate *)certificateForPersistenceData:(NSData *)persistenceData returnAttributes:(NSDictionary **)attributes;
{
    OSStatus err;
    NSDictionary *certificateAttrb = nil;
    
    NSDictionary *queryDict = [NSDictionary dictionaryWithObjectsAndKeys:
                               persistenceData, kSecValuePersistentRef,
                               kCFBooleanTrue, kSecReturnAttributes,
                               kCFBooleanTrue, kSecReturnRef, nil];
    err = SecItemCopyMatching((CFDictionaryRef)queryDict,
                              (CFTypeRef *) &certificateAttrb
                              );
    
    if (certificateAttrb)
    {
        SecCertificateRef certificateRef = (SecCertificateRef)[certificateAttrb objectForKey:kSecValueRef];
        if (attributes)
        {
            *attributes = certificateAttrb;
        }
        FDCertificate *certificate = [[[FDCertificate alloc] initWithCertificate:certificateRef andAttributes:certificateAttrb] autorelease];
        return certificate;
    }
    else
    {
        return nil;
    }
}

- (SecIdentityRef)certificateForKey:(NSString *)certificateKey
{
    OSStatus err;
    CFArrayRef latestCertificates;
    
    err = SecItemCopyMatching(
                       (CFDictionaryRef) [NSDictionary dictionaryWithObjectsAndKeys:
                                          (id) kSecClassCertificate,  kSecClass,
                                          (CFDataRef)[certificateKey dataUsingEncoding:NSUTF8StringEncoding], kSecAttrSubjectKeyID,
                                          kSecMatchLimitAll,          kSecMatchLimit,
                                          kCFBooleanTrue,             kSecReturnRef,
                                          nil
                                          ],
                       (CFTypeRef *) &latestCertificates
                       );
    
    NSArray *certificates = (NSArray *)latestCertificates;
    if ([certificates count] > 0)
    {
        SecIdentityRef identity = (SecIdentityRef)[certificates objectAtIndex:0];
        return identity;
    }
    else
    {
        return nil;
    }
}

- (void)deleteIdentityForPersistenceData:(NSData *)persistenceData
{
    OSStatus    err;
    err = SecItemDelete((CFDictionaryRef) [NSDictionary dictionaryWithObjectsAndKeys:
                                           persistenceData, kSecValuePersistentRef,
                                           nil
                                           ]
                        );
    assert(err == noErr);
}

- (void)deleteCertificateForPersistenceData:(NSData *)persistenceData
{
    OSStatus    err;
    err = SecItemDelete((CFDictionaryRef) [NSDictionary dictionaryWithObjectsAndKeys:
                                           persistenceData, kSecValuePersistentRef,
                                           nil
                                           ]
                        );
    assert(err == noErr);
}


#pragma mark - Singleton

static CertificateManager *sharedManager = nil;

+ (id)sharedManager
{
    if (sharedManager == nil) {
        sharedManager = [[super allocWithZone:NULL] init];
    }
    return sharedManager;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [[self sharedManager] retain];
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain
{
    return self;
}

- (NSUInteger)retainCount
{
    return NSUIntegerMax;  //denotes an object that cannot be released
}

- (oneway void)release
{
    //do nothing
}

- (id)autorelease
{
    return self;
}

@end
