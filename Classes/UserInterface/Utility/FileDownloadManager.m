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
//  FileDownloadManager.m
//
// We store a binary plist to the Documents folder
// The top container is a NSDictionary that will hold the objectId as the key
// and the download metadata as the object.
// We will name the stored file as the objectId md5 hash so we could walk the documents folder
// and ask for a specific metadata information and handle gracefully the legacy downloads
// by returning nil for that specific file

#import "FileDownloadManager.h"

@implementation FileDownloadManager

NSString * const MetadataFileName = @"DownloadMetadata.plist";

#pragma mark - Singleton methods

+ (FileDownloadManager *)sharedInstance
{
    static dispatch_once_t predicate = 0;
    __strong static id sharedObject = nil;
    dispatch_once(&predicate, ^{
        sharedObject = [[self alloc] init];
    });
    return sharedObject;
}

- (id)init
{
    if (self = [super init])
    {
        self.overwriteExistingDownloads = NO;
        self.metadataConfigFileName = MetadataFileName;
    }
    return self;
}

@end
