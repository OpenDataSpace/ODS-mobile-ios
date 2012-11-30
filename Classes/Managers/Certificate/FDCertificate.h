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
//  FDCertificate.h
//
// Encapsulates data extration from identities and certificates
// that use a Core Fundation API and provides a clean Objective-C API
// to access certificate information
// Some functionality is specific to PKCS12 certificates and so this class
// is only used to handle those certificates.

#import <Foundation/Foundation.h>

@interface FDCertificate : NSObject
@property (readonly) SecIdentityRef identityRef;
@property (readonly) SecCertificateRef certificateRef;
@property (readonly) NSString *summary;
@property (readonly) NSDate *expiresDate;

/*
 Initializes with an identity and a dictionary of attributes
 From the identity we retrieve a certificate that is used in the DI
 */
- (id)initWithIdentity:(SecIdentityRef)identity andAttributes:(NSDictionary *)attributes;
/*
 Initializes with a certificate and a dictionary of attributes
 This is the designated initialized
 */
- (id)initWithCertificate:(SecCertificateRef)certificate andAttributes:(NSDictionary *)attributes;


@end
