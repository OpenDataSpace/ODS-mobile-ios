//
//  LogoManager.m
//  FreshDocs
//
//  Created by bdt on 3/19/14.
//
//

#import "LogoManager.h"
#import "RepositoryItem.h"
#import "FileUtils.h"
#import "CMISServiceManager.h"
#import "AccountManager.h"
#import "CMISDownloadFileHTTPRequest.h"
#import "LogoServiceRequest.h"
#import "LinkRelationService.h"
#import "NSURL+HTTPURLUtils.h"

/* logo file name we would use */
NSString * const kLogoAboutZiaLogo_500 = @"aboutLogo-500.png";
NSString * const kLogoAboutZiaLogo = @"aboutLogo.png";
NSString * const kLogoAboutZiaLotoBottom = @"aboutLogoBottom.png";
NSString * const kLogoZiaLogo_60 = @"Logo-60.png";
NSString * const kLogoZiaLogo_144 = @"Logo-144.png";
NSString * const kLogoZiaLogo_240 = @"Logo-240.png";
NSString * const kLogoZiaLogoCP_130 = @"LogoCP-130.png";
NSString * const kLogoZiaLogoCP_260 = @"LogoCP-260.png";
NSString * const kLogoNoDocumentSelected = @"no-document-selected.png";
NSString * const kLogoTabAboutLogo = @"tabAboutLogo.png";
NSString * const KLogoAboutMore = @"about-more.png";

NSString * const kNotificationUpdateLogos = @"NOTIFICATION_UPDATE_LOGOS";
NSString * const kLogoConfigurationFile = @"LogosMetadata.plist";
NSString * const kRepositoryConfigrationFile = @"RepositoryConfigration.plist";
NSString * const kLogoDefaultAccountUUID = @"LogoDefaultAccountUUID";

static CGFloat const updateLogoTimeInterval = 300;  //5 mins  5*60

#define SCREEN_SCALE    [[UIScreen mainScreen] scale]

@interface LogoManager() {
    NSString                    *currentAccountUUID_;
}
@property (nonatomic, strong) NSMutableDictionary *logoFiles;
@property (nonatomic, strong) NSMutableDictionary *brandingReposInfo;

@property (nonatomic, strong) NSTimer   *checkLogoTimer;
@property (nonatomic, strong) ASINetworkQueue *downloadQueue;
@end

@implementation LogoManager
@synthesize logoFiles = _logoFiles;
@synthesize brandingReposInfo = _brandingReposInfo;
@synthesize checkLogoTimer = _checkLogoTimer;
@synthesize downloadQueue = _downloadQueue;

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

- (void) readLogosInformation {
    /* Initial logos information */
    NSString *logosStorePath = [FileUtils pathToConfigFile:kLogoConfigurationFile];
    NSData *serializedLogosData = [NSData dataWithContentsOfFile:logosStorePath];
    if (serializedLogosData && serializedLogosData.length > 0)
    {
        NSMutableDictionary *deserializedDict = [NSKeyedUnarchiver unarchiveObjectWithData:serializedLogosData];
        [self setLogoFiles:deserializedDict];
    }else {
        [self setLogoFiles:[NSMutableDictionary dictionary]];
    }
}

- (void) readBrandingRepositoryInformation {
    /* Initial repository information */
    NSString *brandingReposStorePath = [FileUtils pathToConfigFile:kLogoConfigurationFile];
    NSData *serializedBrandingReposData = [NSData dataWithContentsOfFile:brandingReposStorePath];
    if (serializedBrandingReposData && serializedBrandingReposData.length > 0)
    {
        [self setBrandingReposInfo:[NSKeyedUnarchiver unarchiveObjectWithData:serializedBrandingReposData]];
    }else {
        [self setBrandingReposInfo:[NSMutableDictionary dictionary]];
    }
}

//init
- (id) init {
    if (self = [super init]) {
        _downloadQueue = [ASINetworkQueue queue];
        [_downloadQueue setMaxConcurrentOperationCount:2];
        [self readLogosInformation];
        [self readBrandingRepositoryInformation];
        
        currentAccountUUID_ = [[NSUserDefaults standardUserDefaults] valueForKey:kLogoDefaultAccountUUID];
        
        _checkLogoTimer = [NSTimer scheduledTimerWithTimeInterval:updateLogoTimeInterval
                                                           target:self
                                                         selector:@selector(updateLogoTimerHandler)
                                                         userInfo:nil
                                                          repeats:YES];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountsListChanged:) name:kNotificationAccountListUpdated object:nil];
        
        if ([_logoFiles count] > 0) {
            NSArray *logoItemKeys = [_logoFiles allKeys];
            for (NSString *key in logoItemKeys) {
                LogoItem *item = [_logoFiles objectForKey:key];
                if ([item logoImage] == nil) {
                    [self downlaodLogoWithItem:item];
                }
            }
        }
    }
    
    return self;
}

//set current active account uui
- (void) setCurrentActiveAccount:(NSString*) uuid {
    currentAccountUUID_ = [uuid copy];
    [[NSUserDefaults standardUserDefaults] setObject:currentAccountUUID_ forKey:kLogoDefaultAccountUUID];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

//get logo image by name
- (UIImage*) getLogoImageByName:(NSString*) logoName {
    NSString *fileName =  logoName;
    NSString *fileExtension = [logoName pathExtension];
    if (fileExtension == nil || [fileExtension length] < 2) {
        fileExtension = @"png";
    }
    
    if (SCREEN_SCALE > 2.0) {//example: logo.png  ====> logo@3x.png logo@2x.png
        fileName = [[logoName stringByDeletingPathExtension] stringByAppendingString:@"@3x."];
        fileName = [fileName stringByAppendingString:fileExtension];
    }else if (SCREEN_SCALE > 1.0) {
        fileName = [[logoName stringByDeletingPathExtension] stringByAppendingString:@"@2x."];
        fileName = [fileName stringByAppendingString:fileExtension];
    }else {
        fileName = [[logoName stringByDeletingPathExtension] stringByAppendingString:@"."];
        fileName = [fileName stringByAppendingString:fileExtension];
    }
    
    LogoItem *item = [self logoItemWithAccountUUID:currentAccountUUID_ fileName:fileName];
    if (item && item.logoImage != nil) {
        return item.logoImage;
    }
    
    return [UIImage imageNamed:logoName];
}

//check logs for account
- (BOOL) isExistLogosForAccount:(NSString*) uuid {
    return [_brandingReposInfo objectForKey:uuid] == nil?NO:YES;
}

//set logo infor for account
- (void) setLogoInfo:(NSArray*) allItems accountUUID:(NSString*) uuid configRepo:(RepositoryInfo*) configRepo {
    if (configRepo) {
        BrandingRepositoryInfo *brandingRepoInfo = [_brandingReposInfo objectForKey:uuid];
        if (brandingRepoInfo == nil) {
            [_brandingReposInfo setObject:[BrandingRepositoryInfo brandingRepositoryInfoWithInfo:configRepo] forKey:uuid];
            [self saveBrandingRepoInfos];
        }else if (![configRepo.latestChangeLogToken isEqualToString:[brandingRepoInfo latestChangeLogToken]]) {
            [brandingRepoInfo setLatestChangeLogToken:configRepo.latestChangeLogToken];
            [brandingRepoInfo setLatestUpdatedDate:[NSDate date]];
            [self saveBrandingRepoInfos];
        }
        
        RepositoryItem *child = nil;
        
        for(child in allItems) {
            if(![child isFolder] && [self isIOSLogos:child.title]) {
                [self addLogoItemWithRepositoryItem:child accountUUID:uuid];
            }
        }
    }
}

//check configration repository latest change token
- (BOOL) isNeedUpdateLogosWithRepository:(RepositoryInfo*) repoInfo accountUUID:(NSString*) accountUUID {
    if (currentAccountUUID_ == nil) {
        return YES;
    }
    
    if ([accountUUID isEqualToString:currentAccountUUID_]) {
        BrandingRepositoryInfo *brandingRepoInfo = [_brandingReposInfo objectForKey:accountUUID];
        if (brandingRepoInfo == nil) {
            return YES;
        }else if (![repoInfo.latestChangeLogToken isEqualToString:[brandingRepoInfo latestChangeLogToken]]) {
            [self saveBrandingRepoInfos];
            return  YES;
        }
    }
    
    return NO;
}
//delete branding data for account
- (void) deleteBrandingDataForAccountUUID:(NSString*) acctUUID {
    BrandingRepositoryInfo *brandingRepoInfo = [_brandingReposInfo objectForKey:acctUUID];
    if (brandingRepoInfo != nil) {
        [_brandingReposInfo removeObjectForKey:acctUUID];
        [self saveBrandingRepoInfos];
        
        NSArray *logoItemKeys = [_logoFiles allKeys];
        for (NSString *key in logoItemKeys) {
            if ([key hasPrefix:acctUUID]) {
                [_logoFiles removeObjectForKey:key];
            }
        }
        [self saveLogoItems];
    }
}

- (void) saveLogoItems {
    NSString *logosStorePath = [FileUtils pathToConfigFile:kLogoConfigurationFile];
    [NSKeyedArchiver archiveRootObject:_logoFiles toFile:logosStorePath];
}

- (void) saveBrandingRepoInfos {
    NSString *reposStorePath = [FileUtils pathToConfigFile:kRepositoryConfigrationFile];
    [NSKeyedArchiver archiveRootObject:_brandingReposInfo toFile:reposStorePath];
}

- (BOOL) isIOSLogos:(NSString*) docName {
    if ([docName hasPrefix:[kLogoAboutZiaLogo_500 stringByDeletingPathExtension]]
        || [docName hasPrefix:[kLogoAboutZiaLogo stringByDeletingPathExtension]]
        || [docName hasPrefix:[kLogoAboutZiaLotoBottom stringByDeletingPathExtension]]
        || [docName hasPrefix:[kLogoZiaLogo_60 stringByDeletingPathExtension]]
        || [docName hasPrefix:[kLogoZiaLogo_144 stringByDeletingPathExtension]]
        || [docName hasPrefix:[kLogoZiaLogo_240 stringByDeletingPathExtension]]
        || [docName hasPrefix:[kLogoZiaLogoCP_130 stringByDeletingPathExtension]]
        || [docName hasPrefix:[kLogoZiaLogoCP_260 stringByDeletingPathExtension]]
        || [docName hasPrefix:[kLogoNoDocumentSelected stringByDeletingPathExtension]]
        || [docName hasPrefix:[kLogoTabAboutLogo stringByDeletingPathExtension]]
        || [docName hasPrefix:[KLogoAboutMore stringByDeletingPathExtension]]) {
        return YES;
    }
    return NO;
}

#pragma mark -
#pragma mark Private Method
//broadcast notification update logos
- (void) broadcastUpdateLogosNotification:(NSString*) accountUUID {
    if (currentAccountUUID_ && [accountUUID isEqualToString:currentAccountUUID_]) {  //send notification
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationUpdateLogos object:nil]; //may placeholder viewcontroller had been created. we have to update the logo for it.
    }
}

/* get logo item from list */
- (LogoItem*) logoItemWithAccountUUID:(NSString*) acctUUID fileName:(NSString*) fileName {
    NSString *uuidPredicate = [NSString stringWithFormat:@"%@_%@", acctUUID, fileName];
    
    return [_logoFiles objectForKey:uuidPredicate];
}

/* save logo item with repository item and account uuid */
- (void) addLogoItemWithRepositoryItem:(RepositoryItem*) repoItem accountUUID:(NSString*) acctUUID {
    BOOL bNeedDownlaod = YES;
    LogoItem *item = [self logoItemWithAccountUUID:acctUUID fileName:repoItem.title];
    if (item) { //exist item, we would check if need to update
        if (![repoItem.lastModifiedDate isEqualToCaseInsensitiveString:item.lastModifiedDate]) {
            [item setUrlString:repoItem.contentLocation];
            [item setLastModifiedDate:repoItem.lastModifiedDate];
            [item setLogoImage:nil];
        }
        
        if (item.logoImage != nil) {
            bNeedDownlaod = NO;
        }
        
    }else {  //new item
        item = [LogoItem logoItemWithAccountUUID:acctUUID repositoryItem:repoItem];
        [_logoFiles setObject:item forKey:[NSString stringWithFormat:@"%@_%@", acctUUID, item.fileName]];
    }
    
    if (bNeedDownlaod) {
        [self downlaodLogoWithItem:item];
    }
}

- (void) downlaodLogoWithItem:(LogoItem *)item {
    AccountInfo *acctInfo = [[AccountManager sharedManager] accountInfoForUUID:[item accountUUID]];
    CMISDownloadFileHTTPRequest *request = [[CMISDownloadFileHTTPRequest alloc] initWithURL:[item logoURL] accountUUID:[item accountUUID]];
    [request setDelegate:self];
    [request setUserInfo:[NSDictionary dictionaryWithObject:item forKey:@"LogoItem"]];
    [request setUsername:acctInfo.username];
    [request setPassword:acctInfo.password];
    
    [_downloadQueue addOperation:request];
    [_downloadQueue go];
}

- (void) updateLogoTimerHandler {
    AlfrescoLogDebug(@"updateLogoTimerHandler");
    if (currentAccountUUID_) {
        AccountManager *manager = [AccountManager sharedManager];
        AccountInfo *accountInfo = [manager accountInfoForUUID:currentAccountUUID_];
        LogoServiceRequest *request = [LogoServiceRequest httpGETRequestForAccountUUID:[accountInfo uuid] tenantID:nil];
        [request setSuppressAllErrors:YES];
        [request setDelegate:self];
        [request startAsynchronous];
    }
}

- (FolderDescendantsRequest*) logosRequest:(RepositoryInfo*) configRepo {
    
    NSString *folder = [configRepo rootFolderHref];
    NSString *folderDescendants = [folder stringByReplacingOccurrencesOfString:@"children" withString:@"descendants"];
    //NSString *folderDescendantsUrl = [folderDescendants stringByAppendingString:@"&depth=-1"];
    NSDictionary *defaultParamsDictionary = [[LinkRelationService shared] defaultOptionalArgumentsForFolderChildrenCollection];
    [defaultParamsDictionary setValue:@"-1" forKey:@"depth"];
    NSURL *folderChildrenCollectionURL = [[NSURL URLWithString:folderDescendants] URLByAppendingParameterDictionary:defaultParamsDictionary];
    
    AlfrescoLogDebug(@"logos request url:%@", folderChildrenCollectionURL);
    
    FolderDescendantsRequest *newRequest = [FolderDescendantsRequest requestWithURL:folderChildrenCollectionURL accountUUID:configRepo.accountUuid];
    [newRequest setRequestMethod:@"GET"];
    [newRequest setShouldContinueWhenAppEntersBackground:YES];
    
    return newRequest;
}

- (void) requestFinished:(ASIHTTPRequest *)request {
    if (request.responseStatusCode == 200 && [request isKindOfClass:[CMISDownloadFileHTTPRequest class]]) {
        LogoItem *item = [[request userInfo] objectForKey:@"LogoItem"];
        UIImage *image = [UIImage imageWithData:request.rawResponseData];
        if (image && item) {
            [item setLogoImage:image];
            [self saveLogoItems];
            AlfrescoLogDebug(@"logo file :%@", item.fileName);
            [self broadcastUpdateLogosNotification:currentAccountUUID_];
        } AlfrescoLogDebug(@"logo file 22 :%@", item.fileName);
    }else if ([request isKindOfClass:[LogoServiceRequest class]]) {
        LogoServiceRequest *logoServiceReq = (LogoServiceRequest*) request;
        //check if we should load logos from server
        if ([logoServiceReq confRepositoryInfo] && [[logoServiceReq confRepositoryInfo] latestChangeLogToken]) {
            if ([[LogoManager shareManager] isNeedUpdateLogosWithRepository:[logoServiceReq confRepositoryInfo] accountUUID:logoServiceReq.accountUUID]) {
                FolderDescendantsRequest *logoRequest = [self logosRequest:[logoServiceReq confRepositoryInfo]];
                [logoRequest setUserInfo:[NSDictionary dictionaryWithObject:logoServiceReq.confRepositoryInfo forKey:@"configRepo"]];
                [logoRequest setDelegate:self];
                [logoRequest startAsynchronous];
            }
        }
    }else if ([request isKindOfClass:[FolderDescendantsRequest class]]) {
        FolderDescendantsRequest *logoRequest = (FolderDescendantsRequest *)request;
        RepositoryInfo *confRepositoryInfo = [[logoRequest userInfo] objectForKey:@"configRepo"];
        [self setLogoInfo:logoRequest.folderDescendants accountUUID:logoRequest.accountUUID configRepo:confRepositoryInfo];
    }
}

- (void) requestFailed:(ASIHTTPRequest *)request {
    AlfrescoLogDebug(@"%@", request.error);
}

#pragma mark - Account Deleted Notification
- (void)accountsListChanged:(NSNotification *)notification {
    NSString *accountUUID = [notification.userInfo objectForKey:@"uuid"];
    NSString *changeType = [notification.userInfo objectForKey:@"type"];
    
    if (changeType == kAccountUpdateNotificationDelete) {
        [self deleteBrandingDataForAccountUUID:accountUUID];
    }
}

@end
