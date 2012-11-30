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
@property (readonly) NSDictionary *attributes;

@end

@implementation FDCertificate
@synthesize identityRef = _identityRef;
@synthesize certificateRef = _certificateRef;
@synthesize attributes = _attributes;

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

@end
