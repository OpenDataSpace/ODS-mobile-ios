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
#import <Foundation/Foundation.h>

@class AccountInfo;
@class RepositoryInfo;
@class RepositoryItem;


@interface DocumentPickerSelection : NSObject

// Following properties control which type can be selected using the document picker

@property BOOL isAccountSelectionEnabled;
@property BOOL isRepositorySelectionEnabled;
@property BOOL isSiteSelectionEnabled;
@property BOOL isFolderSelectionEnabled;
@property BOOL isDocumentSelectionEnabled;

// Enabled or disables multi-select
// Changing it only has influence when it is set before the corresponding table is actually created
@property BOOL isMultiSelectionEnabled;

// Long-named property that, when set, prevents going back in the hierarchy to repositories
// once one document (or more) has been picked. By default enabled.
@property BOOL isStopAtSitesWhenDocumentsPickedEnabled;

// Results of selection something through the document picker
@property (readonly) NSArray *selectedAccounts; // Array of AccountInfo objects
@property (readonly) NSArray *selectedRepositories; // Array of RepositoryInfo objects
@property (readonly) NSArray *selectedSites; // Array of RepositoryItem objects
@property (readonly) NSArray *selectedFolders; // Array of RepositoryItem objects
@property (readonly) NSArray *selectedDocuments; // Array of RepositoryItem objects

// Allows to customize selection text. The string will be used as prefix, eg 'Attach' -> 'Attach x documents'
@property (nonatomic, retain) NSString *selectiontextPrefix;

// Methods to add, remove and check if present
- (void)addAccount:(AccountInfo *)accountInfo;
- (void)removeAccount:(AccountInfo *)accountInfo;
- (BOOL)containsAccount:(AccountInfo *)account;
- (void)clearAccounts;

- (void)addRepository:(RepositoryInfo *)repositoryInfo;
- (void)removeRepository:(RepositoryInfo *)repositoryInfo;
- (BOOL)containsRepository:(RepositoryInfo *)repositoryInfo;
- (void)clearRepositories;

- (void)addSite:(RepositoryItem *)site;
- (void)removeSite:(RepositoryItem *)site;
- (BOOL)containsSite:(RepositoryItem *)site;
- (void)clearSites;

- (void)addFolder:(RepositoryItem *)folder;
- (void)removeFolder:(RepositoryItem *)folder;
- (BOOL)containsFolder:(RepositoryItem *)folder;
- (void)clearFolders;

- (void)addDocument:(RepositoryItem *)document;
- (void)addDocuments:(NSArray *)documents;
- (void)removeDocument:(RepositoryItem *)document;
- (BOOL)containsDocument:(RepositoryItem *)document;
- (void)clearDocuments;

- (void)clearAll;



@end
