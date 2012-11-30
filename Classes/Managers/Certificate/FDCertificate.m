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
//  FDCertificate.m
//
//

#import "FDCertificate.h"


@interface FDCertificate ()
{
    BOOL verifiedDate;
}
@property (readonly) NSDictionary *attributes;

@end

@implementation FDCertificate
@synthesize identityRef = _identityRef;
@synthesize certificateRef = _certificateRef;
@synthesize attributes = _attributes;
@synthesize hasExpired = _hasExpired;

- (void)dealloc
{
    CFRelease(_identityRef);
    CFRelease(_certificateRef);
    [_attributes release];
    [super dealloc];
}

- (id)initWithIdentity:(SecIdentityRef)identityRef andAttributes:(NSDictionary *)attributes
{
    SecCertificateRef certificateRef;
    OSStatus err;
    err = SecIdentityCopyCertificate(identityRef, &certificateRef);
    if (err != errSecSuccess)
    {
        return nil;
    }
    
    self = [self initWithCertificate:certificateRef andAttributes:attributes];
    if (self) {
        _identityRef = identityRef;
        CFRetain(identityRef);
    }
    CFRelease(certificateRef);
    return self;
}

- (id)initWithCertificate:(SecCertificateRef)certificateRef andAttributes:(NSDictionary *)attributes
{
    self = [super init];
    if (self) {
        _certificateRef = certificateRef;
        CFRetain(certificateRef);
        _attributes = [attributes retain];
    }
    return self;
}

- (NSString *)summary
{
    NSString *summary = (NSString *)SecCertificateCopySubjectSummary(self.certificateRef);
    return [summary autorelease];
}


- (NSDate *)expiresDate
{
    return nil;
}

- (BOOL)hasExpired
{
    if (!verifiedDate)
    {
        _hasExpired = [self verifyCertificateDate];
        verifiedDate = YES;
    }
    return _hasExpired;
}

// Source: https://developer.apple.com/library/mac/#documentation/security/conceptual/CertKeyTrustProgGuide/iPhone_Tasks/iPhone_Tasks.html
- (BOOL)verifyCertificateDate
{
    SecPolicyRef myPolicy = SecPolicyCreateBasicX509();
    
    SecCertificateRef certArray[1] = { self.certificateRef };
    CFArrayRef myCerts = CFArrayCreate(
                                       NULL, (void *)certArray,
                                       1, NULL);
    NSArray *certificates = [NSArray arrayWithObject:(id)self.certificateRef];
    SecTrustRef myTrust;
    OSStatus status = SecTrustCreateWithCertificates(
                                                     certificates,
                                                     myPolicy,
                                                     &myTrust);
    
    SecTrustResultType trustResult;
    if (status == noErr)
    {
        status = SecTrustEvaluate(myTrust, &trustResult);
    }
    else
    {
        trustResult = kSecTrustResultRecoverableTrustFailure;
    }
    
    if (myPolicy)
        CFRelease(myPolicy);
    if (myCerts)
        CFRelease(myCerts);
    if (myTrust)
        CFRelease(myTrust);
    // Assuming that any trustResult but kSecTrustResultProceed
    // means that the certificate is expired
    return trustResult != kSecTrustResultProceed;
}

@end
