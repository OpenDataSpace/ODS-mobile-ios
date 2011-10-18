//
//  Utility.h
//  Alfresco
//
//  Created by Michael Muller on 10/14/09.
//  Copyright 2009 Zia Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

//
//  !!!: Lets deprecated this and break it out into different classes
//	!!!: User Preference Profiles? so one can quickly switch locations
//

#define IS_IPAD ([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)

UIImage* imageForFilename(NSString* filename);
NSString* createStringByEscapingAmpersandsInsideTagsOfString(NSString *input, NSString *startTag, NSString *endTag);

void startSpinner(void);
void stopSpinner(void);

NSString* userPrefUsername(void);
NSString* userPrefPassword(void);
NSString* userPrefHostname(void);
NSString* userPrefPort(void);
NSString* serviceDocumentURIString(void);
BOOL userPrefShowHiddenFiles(void);
BOOL userPrefEnableAmpersandHack(void);
BOOL userPrefShowCompanyHome(void);
NSString* userPrefProtocol(void);
BOOL userPrefFullTextSearch(void);
BOOL isIPad(void);
NSString* formatDateTime(NSString *isoDate);

