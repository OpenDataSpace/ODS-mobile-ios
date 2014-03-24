//
//  LogoManager.m
//  FreshDocs
//
//  Created by bdt on 3/19/14.
//
//

#import "LogoManager.h"
#import "RepositoryItem.h"

/* logo file name we would use */
NSString * const kLogoAboutZiaLogo_500 = @"aboutZiaLogo-500.png";
NSString * const kLogoAboutZiaLogo = @"aboutZiaLogo.png";
NSString * const kLogoAboutZiaLotoBottom = @"aboutZiaLogoBottom.png";
NSString * const kLogoZiaLogo_60 = @"ZiaLogo-60.png";
NSString * const kLogoZiaLogo_144 = @"ZiaLogo-144.png";
NSString * const kLogoZiaLogo_240 = @"ZiaLogo-240.png";
NSString * const kLogoZiaLogoCP_130 = @"ZiaLogoCP-130.png";
NSString * const kLogoZiaLogoCP_260 = @"ZiaLogoCP-260.png";
NSString * const kLogoNoDocumentSelected = @"no-document-selected.png";
NSString * const kLogoTabAboutLogo = @"tabAboutLogo.png";

NSString * const kNotificationUpdateLogos = @"NOTIFICATION_UPDATE_LOGOS";

#define IS_RETINA_SCREEN (([[UIScreen mainScreen] scale] > 1.0)?YES:NO)  //if the retina screen, scale will be 2.0 

@interface LogoManager() {
    NSMutableDictionary         *logoFiles_;
    NSString                    *currentAccountUUID_;
}
@end

@implementation LogoManager

+ (LogoManager*) shareManager {
    dispatch_once_t predicate = 0;
    static LogoManager *instanceLogoManager = nil;
    if (instanceLogoManager == nil) {
        dispatch_once(&predicate, ^{
            instanceLogoManager = [[self alloc] init];
        });
    }
    [[UIScreen mainScreen] scale];
    return instanceLogoManager;
}

//init
- (id) init {
    if (self = [super init]) {
        logoFiles_ = [NSMutableDictionary dictionary];
        currentAccountUUID_ = nil;
    }
    
    return self;
}

//set current active account uui
- (void) setCurrentActiveAccount:(NSString*) uuid {
    currentAccountUUID_ = nil;
    currentAccountUUID_ = [uuid copy];
}

//get logo url by name
- (NSURL*) getLogoURLByName:(NSString*) logoName {
    NSMutableDictionary *filesDict = [logoFiles_ objectForKey:currentAccountUUID_];
    NSString *fileName =  logoName;
    
    if (IS_RETINA_SCREEN) {//example: logo.png  ====>  logo@2x.png
        fileName = [[logoName stringByDeletingPathExtension] stringByAppendingString:@"@2x."];
        fileName = [fileName stringByAppendingString:[logoName pathExtension]];
    }
    
    if (filesDict) {
        RepositoryItem *item = [filesDict objectForKey:fileName];
        if (item && [item.title isEqualToString:fileName]) {
            return [NSURL URLWithString:[item contentLocation]];
        }
    }
    
    return nil;
}

//check logs for account
- (BOOL) isExistLogosForAccount:(NSString*) uuid {
    return (([logoFiles_ objectForKey:uuid] == nil)? NO:YES);
}

//set logo infor for account
- (void) setLogoInfo:(NSArray*) allItems accountUUID:(NSString*) uuid {
    NSMutableDictionary *filesDict = [NSMutableDictionary dictionary];
    
    RepositoryItem *child;
    
    for(child in allItems) {
        if(![child isFolder]) {
            [filesDict setObject:child forKey:child.title];
        }
    }
    
    if ([filesDict count] > 0) { //make sure to get files
        [logoFiles_ setObject:filesDict forKey:uuid];
        [self broadcastUpdateLogosNotification:uuid];
    }
}

#pragma mark -
#pragma mark Private Method
//broadcast notification update logos
- (void) broadcastUpdateLogosNotification:(NSString*) accountUUID {
    if (currentAccountUUID_ && [accountUUID isEqualToString:currentAccountUUID_]) {  //send notification
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationUpdateLogos object:nil]; //may placeholder viewcontroller had been created. we have to update the logo for it.
    }
}

@end
