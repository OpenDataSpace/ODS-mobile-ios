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
// DocumentPickerSelection 
//
#import "DocumentPickerSelection.h"
#import "AccountInfo.h"
#import "RepositoryInfo.h"
#import "RepositoryItem.h"

@interface DocumentPickerSelection()

@property (nonatomic, retain) NSMutableDictionary *selectedAccountsDict;
@property (nonatomic, retain) NSMutableDictionary *selectedRepositoriesDict;
@property (nonatomic, retain) NSMutableDictionary *selectedSitesDict;
@property (nonatomic, retain) NSMutableDictionary *selectedFoldersDict;
@property (nonatomic, retain) NSMutableDictionary *selectedDocumentsDict;

@end


@implementation DocumentPickerSelection

@synthesize isAccountSelectionEnabled = _isAccountSelectionEnabled;
@synthesize isRepositorySelectionEnabled = _isRepositorySelectionEnabled;
@synthesize isSiteSelectionEnabled = _isSiteSelectionEnabled;
@synthesize isFolderSelectionEnabled = _isFolderSelectionEnabled;
@synthesize isDocumentSelectionEnabled = _isDocumentSelectionEnabled;
@synthesize isMultiSelectionEnabled = _isMultiSelectionEnabled;
@synthesize selectedAccountsDict = _selectedAccountsDict;
@synthesize selectedRepositoriesDict = _selectedRepositoriesDict;
@synthesize selectedSitesDict = _selectedSitesDict;
@synthesize selectedFoldersDict = _selectedFoldersDict;
@synthesize selectedDocumentsDict = _selectedDocumentsDict;
@synthesize selectiontextPrefix = _selectiontextPrefix;


- (void)dealloc
{
    [_selectedAccountsDict release];
    [_selectedRepositoriesDict release];
    [_selectedSitesDict release];
    [_selectedFoldersDict release];
    [_selectedDocumentsDict release];
    [_selectiontextPrefix release];
    [super dealloc];
}

- (id)init
{
    self = [super init];
    if (self)
    {
        // Default settings
        _isAccountSelectionEnabled = NO;
        _isRepositorySelectionEnabled = NO;
        _isSiteSelectionEnabled = NO;
        _isFolderSelectionEnabled = NO;
        _isDocumentSelectionEnabled = YES;

        _isMultiSelectionEnabled = YES;
    }
    return self;
}

#pragma mark Getters and Setters

- (NSArray *)selectedAccounts
{
    return self.selectedAccountsDict.allValues;
}

- (NSArray *)selectedRepositories
{
    return self.selectedRepositoriesDict.allValues;
}

- (NSArray *)selectedSites
{
    return self.selectedSitesDict.allValues;
}

- (NSArray *)selectedFolders
{
    return self.selectedFoldersDict.allValues;
}

- (NSArray *)selectedDocuments
{
    return self.selectedDocumentsDict.allValues;
}

#pragma mark addXXX methods

- (void)addAccount:(AccountInfo *)accountInfo
{
    if (self.selectedAccountsDict == nil)
    {
        self.selectedAccountsDict = [NSMutableDictionary dictionary];
    }
    [self.selectedAccountsDict setObject:accountInfo forKey:accountInfo.uuid];
}

- (void)addRepository:(RepositoryInfo *)repositoryInfo
{
    if (self.selectedRepositoriesDict == nil)
    {
        self.selectedRepositoriesDict = [NSMutableDictionary dictionary];
    }
    [self.selectedRepositoriesDict setObject:repositoryInfo forKey:repositoryInfo.repositoryId];
}

- (void)addSite:(RepositoryItem *)site
{
    if (self.selectedSitesDict == nil)
    {
        self.selectedSitesDict = [NSMutableDictionary dictionary];
    }
    [self.selectedSitesDict setObject:site forKey:site.guid];
}

- (void)addFolder:(RepositoryItem *)folder
{
    if (self.selectedFoldersDict == nil)
    {
        self.selectedFoldersDict = [NSMutableDictionary dictionary];
    }
    [self.selectedFoldersDict setObject:folder forKey:folder.guid];
}

- (void)addDocument:(RepositoryItem *)document
{
    if (self.selectedDocumentsDict == nil)
    {
        self.selectedDocumentsDict = [NSMutableDictionary dictionary];
    }
    [self.selectedDocumentsDict setObject:document forKey:document.guid];
}

#pragma mark removeXXX methods

- (void)removeAccount:(AccountInfo *)accountInfo
{
    [self.selectedAccountsDict removeObjectForKey:accountInfo.uuid];
}

- (void)removeRepository:(RepositoryInfo *)repositoryInfo
{
    [self.selectedRepositoriesDict removeObjectForKey:repositoryInfo.repositoryId];
}

- (void)removeSite:(RepositoryItem *)site
{
    [self.selectedSitesDict removeObjectForKey:site.guid];
}

- (void)removeFolder:(RepositoryItem *)folder
{
    [self.selectedFoldersDict removeObjectForKey:folder.guid];
}

- (void)removeDocument:(RepositoryItem *)document
{
    [self.selectedDocumentsDict removeObjectForKey:document.guid];
}

#pragma mark containsXXX methods

- (BOOL)containsAccount:(AccountInfo *)account
{
    return [self.selectedAccountsDict objectForKey:account.uuid] != nil;
}

- (BOOL)containsRepository:(RepositoryInfo *)repositoryInfo
{
    return [self.selectedRepositoriesDict objectForKey:repositoryInfo.repositoryId] != nil;
}

- (BOOL)containsSite:(RepositoryItem *)site
{
    return [self.selectedSitesDict objectForKey:site.guid] != nil;
}

- (BOOL)containsFolder:(RepositoryItem *)folder
{
    return [self.selectedFoldersDict objectForKey:folder.guid] != nil;
}

- (BOOL)containsDocument:(RepositoryItem *)document
{
    return [self.selectedDocumentsDict objectForKey:document.guid] != nil;
}


@end
