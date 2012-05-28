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
 *
 * ***** END LICENSE BLOCK ***** */
//
//  PreviewManager.h
//

#import <Foundation/Foundation.h>
#import "ASIHTTPRequest+Utils.h"
#import "ASINetworkQueue.h"
#import "DownloadInfo.h"
#import "RepositoryItem.h"

@class PreviewManager;

@protocol PreviewManagerDelegate <NSObject>
@optional
- (void)previewManager:(PreviewManager *)manager willStartDownloading:(DownloadInfo *)info toPath:(NSString *)destPath;
- (void)previewManager:(PreviewManager *)manager downloadProgress:(DownloadInfo *)info withProgress:(CGFloat)progress;
- (void)previewManager:(PreviewManager *)manager didFinishDownloading:(DownloadInfo *)info toPath:(NSString *)destPath;
- (void)previewManager:(PreviewManager *)manager downloadFailed:(DownloadInfo *)info withError:(NSError *)error;

@end

@interface PreviewManager : NSObject <ASIHTTPRequestDelegate>
{
}

@property (nonatomic, assign) id<PreviewManagerDelegate> delegate;
@property (nonatomic, retain, readonly) NSString *lastPreviewedGuid;

+ (PreviewManager *)sharedManager;

- (DownloadInfo *)downloadInfoForItem:(RepositoryItem *)item;

- (void)previewItem:(RepositoryItem *)item delegate:(id<PreviewManagerDelegate>)aDelegate accountUUID:(NSString *)anAccountUUID tenantID:(NSString *)aTenantID;
- (void)cancelDownload;

@end
