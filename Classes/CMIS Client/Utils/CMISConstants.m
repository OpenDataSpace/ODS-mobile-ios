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
//  CMISConstants.m
//
//  Constants used to acces CMIS properties

#import "CMISConstants.h"

@implementation CMISConstants

NSString * const kCMISPropertyDefinitionIdPropertyName = @"propertyDefinitionId";
NSString * const kCMISLastModifiedPropertyName = @"cmis:lastModifiedBy";
NSString * const kCMISLastModificationDatePropertyName = @"cmis:lastModificationDate";
NSString * const kCMISBaseTypeIdPropertyName = @"cmis:baseTypeId";
NSString * const kCMISObjectIdPropertyName = @"cmis:objectId";
NSString * const kCMISContentStreamLengthPropertyName = @"cmis:contentStreamLength";
NSString * const kCMISVersionSeriesIdPropertyName = @"cmis:versionSeriesId";
NSString * const kCMISChangeTokenPropertyName = @"cmis:changeToken";
/**
 * Alfresco proprietary content model extensions
 * TODO: Should these be externalised somehow (they're relatively benign)
 */
NSString * const kCMISAlfrescoAspectNamePrefix = @"P:";
NSString * const kCMISMDMExpiresAfterPropertyName = @"dp:offlineExpiresAfter";

@end
