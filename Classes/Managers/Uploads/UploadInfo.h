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
//  UploadInfo.h
//

#import <Foundation/Foundation.h>
#import "UploadHelper.h"
@class RepositoryItem;
@class CMISUploadFileRequest;

typedef enum 
{
    UploadInfoStatusInactive,
    UploadInfoStatusActive,  
    UploadInfoStatusUploading,
    UploadInfoStatusUploaded,
    UploadInfoStatusFailed
} UploadInfoStatus;

typedef enum 
{
    UploadFormTypePhoto,
    UploadFormTypeVideo,
    UploadFormTypeAudio,
    UploadFormTypeDocument,
    UploadFormTypeLibrary,
    UploadFormTypeMultipleDocuments,
    UploadFormTypeCreateDocument
} UploadFormType;

@interface UploadInfo : NSObject

@property (nonatomic, copy) NSString *uuid;
@property (nonatomic, retain) NSURL *uploadFileURL;
@property (nonatomic, copy) NSString *filename;
@property (nonatomic, copy) NSString *extension;
@property (nonatomic, copy) NSString *upLinkRelation;
@property (nonatomic, copy) NSString *cmisObjectId;
@property (nonatomic, retain) RepositoryItem *repositoryItem;
@property (nonatomic, retain) NSDate *uploadDate;
@property (nonatomic, retain) NSArray *tags;
@property (nonatomic, assign) UploadInfoStatus uploadStatus;
@property (nonatomic, assign) UploadFormType uploadType;
@property (nonatomic, retain) CMISUploadFileRequest *uploadRequest;
@property (nonatomic, retain) NSError *error;
@property (nonatomic, copy) NSString *folderName;
@property (nonatomic, copy) NSString *selectedAccountUUID;
@property (nonatomic, copy) NSString *tenantID;
@property (nonatomic, assign) BOOL uploadFileIsTemporary;

- (NSString *)completeFileName;
- (NSURL *)uploadURL;
- (id<UploadHelper>)uploadHelper;
- (void)setFilenameWithDate:(NSDate *)date andExistingDocuments:(NSArray *)existingDocuments;
- (NSString *)typeDescriptionWithPlural:(BOOL)plural;
+ (NSString *)typeDescription:(UploadFormType)type plural:(BOOL)plural;
- (void)removeTemporaryUploadFile;

@end
