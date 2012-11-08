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
//  CertificateManager.h
//
//
// Manages the access and persistence operations of certificates
// and identities.
// It uses the C functions provided by apple to search, import and store certificates
// This is a singleton since there is no need to have multiple CertificateManager instances
// storing and accessing certificate/identity items.
// All operations are available to manage identities or certificates

typedef enum {
    ImportCertificateStatusCancelled,
    ImportCertificateStatusFailed,
    ImportCertificateStatusSucceeded
} ImportCertificateStatus;

#import <Foundation/Foundation.h>

@interface CertificateManager : NSObject

/*
 Validates a certificate or a PKCS12 file. It will import them in memory and validate
 for a wrong file or passcode (only for PKCS12)
 */
- (ImportCertificateStatus)validatePKCS12:(NSData *)pkcs12Data withPasscode:(NSString *)passcode;
- (ImportCertificateStatus)validateCertificate:(NSData *)certificateData;

/*
 Imports the certificate or identity (PKC12) data into the keychain. 
 If a reference to a status is provided it will be modified with the result status.
 Returns the persistence data for either certificate and (first)identity
 */
- (NSData *)importCertificateData:(NSData *)certificateData importStatus:(ImportCertificateStatus *)status;
- (NSData *)importIdentityData:(NSData *)identityData withPasscode:(NSString *)passcode importStatus:(ImportCertificateStatus *)status;;

/*
 Retrieves the identity or certificate from the keychain.
 The persistenceData returned in the import should be stored since is used by the methods
 If a dictionary reference is provided the certificate/identity attributes will be provided
 Returns either the SecIdentityRef or SecCertificateRef
 */
- (SecIdentityRef)identityForPersistenceData:(NSData *)persistenceData returnAttributes:(NSDictionary **)attributes;
- (SecCertificateRef)certificateForPersistenceData:(NSData *)persistenceData returnAttributes:(NSDictionary **)attributes;

/*
 Deletes the identity or certificate from the keychain with the persistenceData as the key
 The persistenceData returned in the import should be stored since is used by the methods
 */
- (void)deleteIdentityForPersistenceData:(NSData *)persistenceData;
- (void)deleteCertificateForPersistenceData:(NSData *)persistenceData;

/*
 Shared instance of the CertificateManager uses the keychain
 as the store to save and retrieve certificates and identities
 */
+ (id)sharedManager;

@end
