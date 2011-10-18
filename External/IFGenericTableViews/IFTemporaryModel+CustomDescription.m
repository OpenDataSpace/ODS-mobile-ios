//
//  IFTemporaryModel+CustomDescription.m
//  Denver311
//
//  Created by Gi Hyun Lee on 8/12/10.
//  Copyright 2010 Zia Consulting. All rights reserved.
//

static int const kMAX_RECURSION_DEPTH = 5;

#import "IFTemporaryModel+CustomDescription.h"
#import "TopicUtils.h"

// ============================================================================
// = Hidden private methods
// ============================================================================

@interface IFTemporaryModel (PrivateHelperMethods)
- (NSString *)trimString:(NSString *)aString;
- (BOOL)addStringToArray:(NSMutableArray *)stringArray withStringValue:(NSString *)string;
- (BOOL)hasAtleastOneAttributeValue:(IFTemporaryModel *)tModel withRecursionDepth:(int)rDepth;

- (NSString *)incidentLocationComplexTypeDescription;
- (NSString *)addressComplexTypeDescription:(IFTemporaryModel *)addressModel;
- (NSString *)contactInfoComplexTypeDescription;
@end

@implementation IFTemporaryModel (PrivateHelperMethods)

- (NSString *)trimString:(NSString *)aString
{
	if (nil == aString) 
		return [NSString string];
	
	return [aString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

- (BOOL)addStringToArray:(NSMutableArray *)stringArray withStringValue:(NSString *)string
{
	NSString *trimmed = [self trimString:string];
	if (0 == [trimmed length]) {
		return FALSE;
	}
	
	[stringArray addObject:trimmed];
	return TRUE;
}

- (BOOL)hasAtleastOneAttributeValue:(IFTemporaryModel *)tModel withRecursionDepth:(int)rDepth
{
	if (nil == tModel) {
		return NO;
	}
	
	if (rDepth > kMAX_RECURSION_DEPTH) {
		NSLog(@"WARNING: hasAtleastOneAttributeValue: Max Recursion Depth Encountered");
		return NO;
	}
	
	NSDictionary *attribute = [tModel dictionary];
	NSArray *attributeArray = [TopicUtils getAttributeArrayFrom:attribute];
	for (NSDictionary *childAttr in attributeArray) {
		if ([TopicUtils isComplexAttribute:childAttr]) {
			IFTemporaryModel *subModel = (IFTemporaryModel *)[tModel objectForKey:[TopicUtils getIdFrom:childAttr]];
			if ([self hasAtleastOneAttributeValue:subModel withRecursionDepth:(++rDepth)]) {
				return YES;
			}
		} else {
			// do not count the address state attribute since there is no way to "clear" the value
			if ([kSRAttrAddressStateKey caseInsensitiveCompare:[childAttr objectForKey:kSRAttributeKeyName]] == NSOrderedSame) continue;
			
			NSString *value = [self trimString:[tModel objectForKey:[TopicUtils getIdFrom:childAttr]]];
			if (0 < [value length]) {
				return YES;
			}
		}
	}
	
	return NO;
}

- (NSString *)incidentLocationComplexTypeDescription
{
	NSArray *subAttributeArray = [TopicUtils getAttributeArrayFrom:[self dictionary]];
	IFTemporaryModel *addressSubModel = [self objectForKey:[TopicUtils resolveAttributeIdForAttributeKey:kSRAttrAddressKey 
																						inAttributeArray:subAttributeArray]];
	return [self addressComplexTypeDescription:addressSubModel];
}

- (NSString *)addressComplexTypeDescription:(IFTemporaryModel *)addressModel
{
	NSArray *subAttributeArray = [TopicUtils getAttributeArrayFrom:[addressModel dictionary]];
	
	NSMutableArray *valuesToJoin = [NSMutableArray array];
	[self addStringToArray:valuesToJoin withStringValue:[addressModel objectForKey:[TopicUtils resolveAttributeIdForAttributeKey:kSRAttrAddressLine1Key 
																												inAttributeArray:subAttributeArray]]];
	[self addStringToArray:valuesToJoin withStringValue:[addressModel objectForKey:[TopicUtils resolveAttributeIdForAttributeKey:kSRAttrAddressLine2Key 
																												inAttributeArray:subAttributeArray]]];
	[self addStringToArray:valuesToJoin withStringValue:[addressModel objectForKey:[TopicUtils resolveAttributeIdForAttributeKey:kSRAttrAddressCityKey 
																												inAttributeArray:subAttributeArray]]];
	[self addStringToArray:valuesToJoin withStringValue:[addressModel objectForKey:[TopicUtils resolveAttributeIdForAttributeKey:kSRAttrAddressStateKey 
																												inAttributeArray:subAttributeArray]]];
	
	NSString *value = [valuesToJoin componentsJoinedByString:@", "];
	NSString *postalCode = [self trimString:[addressModel objectForKey:[TopicUtils resolveAttributeIdForAttributeKey:kSRAttrAddressPostalCodeKey 
																									inAttributeArray:subAttributeArray]]];
	if (0 < [postalCode length]) {
		return [NSString stringWithFormat:@"%@ %@", value, postalCode];
	}
	
	return value;
}

- (NSString *)contactInfoComplexTypeDescription
{
	NSArray *subAttributeArray = [TopicUtils getAttributeArrayFrom:[self dictionary]];
	
	NSMutableArray *valuesToJoin = [NSMutableArray array];
	NSString *fullName = [NSString stringWithFormat:@"%@ %@", 
						  [self trimString:[self objectForKey:[TopicUtils resolveAttributeIdForAttributeKey:kSRAttrContactFirstNameKey 
																						   inAttributeArray:subAttributeArray]]],
						  [self trimString:[self objectForKey:[TopicUtils resolveAttributeIdForAttributeKey:kSRAttrContactLastNameKey 
																						   inAttributeArray:subAttributeArray]]] 
						  ];
	[self addStringToArray:valuesToJoin withStringValue:[self trimString:fullName]];
	[self addStringToArray:valuesToJoin withStringValue:[self objectForKey:[TopicUtils resolveAttributeIdForAttributeKey:kSRAttrContactPhoneKey 
																										inAttributeArray:subAttributeArray]]];
	[self addStringToArray:valuesToJoin withStringValue:[self objectForKey:[TopicUtils resolveAttributeIdForAttributeKey:kSRAttrContactEmailKey 
																										inAttributeArray:subAttributeArray]]];
	
	IFTemporaryModel *addressSubModel = (IFTemporaryModel *)[self objectForKey:[TopicUtils resolveAttributeIdForAttributeKey:kSRAttrAddressKey 
																						inAttributeArray:subAttributeArray]];
	if (nil != addressSubModel) {
		[self addStringToArray:valuesToJoin withStringValue:[self addressComplexTypeDescription:addressSubModel]];
	}
	
	return [valuesToJoin componentsJoinedByString:@", "];
}

@end

// ============================================================================
// = Implementation of CustomDescription Category
// ============================================================================

@implementation  IFTemporaryModel (CustomDescription)

- (BOOL)isCustomDescriptionAvailable
{
	if ([TopicUtils isComplexAttribute:[self dictionary]]) {
		NSString *presentationType = [[self dictionary] objectForKey:kSRAttributePresentationTypeKeyName];
		if ((presentationType != nil) 
			&& (([kSRPresentationTypeIncidentLocation caseInsensitiveCompare:presentationType] == NSOrderedSame) 
				|| ([kSRPresentationTypePhoneContact caseInsensitiveCompare:presentationType] == NSOrderedSame)
				|| ([kSRPresentationTypeFullContact caseInsensitiveCompare:presentationType] == NSOrderedSame))) {
			
			if ([self hasAtleastOneAttributeValue:self withRecursionDepth:0]) {
//				return (0 < [[self trimString:[self description]] length]);
				return YES;
			}
		}
	}
	
	return NO;
}

- (NSString *)description
{
	NSString *output = nil;
	if ([self isCustomDescriptionAvailable]) {
		NSString *presentationType = [[self dictionary] objectForKey:kSRAttributePresentationTypeKeyName];
		if (nil != presentationType) {		
			if ([kSRPresentationTypeIncidentLocation caseInsensitiveCompare:presentationType] == NSOrderedSame) {
				output = [self incidentLocationComplexTypeDescription];
			}
			else if (([kSRPresentationTypePhoneContact caseInsensitiveCompare:presentationType] == NSOrderedSame)
					 || ([kSRPresentationTypeFullContact caseInsensitiveCompare:presentationType] == NSOrderedSame)) {
				output = [self contactInfoComplexTypeDescription];
			}
		}
	}
	
	if (nil == output)
		output = [super description];
	
	return output;
}

@end
