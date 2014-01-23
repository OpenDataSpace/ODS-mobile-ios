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
//  CMISAtomEntryWriter.m
//

#import "CMISAtomEntryWriter.h"
#import "Utility.h"
#import "GTMNSString+XML.h"
#import "NSData+Base64.h"

// Note that the base64 encoding will alloc this twice at a given point, so don't make it too high
NSUInteger const kBase64EncodeChunkSize = 524288;

@interface CMISAtomEntryWriter ()
- (void)addEntryStartElements;
- (void)addContent;
- (void)addEntryEndElements;
- (void)appendFileWithString:(NSString *)string;
- (void)appendFileWithData:(NSData *)data;

@property (nonatomic, retain) NSString *internalFilePath;
@property (nonatomic, retain) NSString *filePath;
@property (nonatomic, retain) NSString *filename;
@end

@implementation CMISAtomEntryWriter
@synthesize internalFilePath = _internalFilePath;
@synthesize filePath = _filePath;
@synthesize filename = _filename;

- (void)dealloc
{
    [_internalFilePath release];
    [_filePath release];
    [_filename release];
    [super dealloc];
}

+ (NSString *)generateAtomEntryXmlForFilePath:(NSString *)filePath uploadFilename:(NSString *)filename
{
    CMISAtomEntryWriter *entryWriter = [[[CMISAtomEntryWriter alloc] init] autorelease];
    [entryWriter setFilePath:filePath];
    [entryWriter setFilename:filename];

    [entryWriter addEntryStartElements];
    [entryWriter addContent];
    [entryWriter addEntryEndElements];
    
    return entryWriter.internalFilePath;
}

- (void)addEntryStartElements
{
    NSString *atomEntryXmlStart = [NSString stringWithFormat:@""
                                   "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>"
                                   "<entry xmlns=\"http://www.w3.org/2005/Atom\" xmlns:app=\"http://www.w3.org/2007/app\" xmlns:cmisra=\"http://docs.oasis-open.org/ns/cmis/restatom/200908/\">"];
    
    [self appendFileWithString:atomEntryXmlStart];
}

- (void)addContent
{
    NSString *contentXMLStart = [NSString stringWithFormat:@""
                                 "<cmisra:content>"
                                 "<cmisra:mediatype>%@</cmisra:mediatype>"
                                 "<cmisra:base64>",
                                 mimeTypeForFilename(self.filename)];
    
    [self appendFileWithString:contentXMLStart];
    
   /* NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:self.filePath];   //TODO:we only create an empty file here.
    if (fileHandle)
    {
        // Get the total file length
        [fileHandle seekToEndOfFile];
        unsigned long long fileLength = [fileHandle offsetInFile];
        
        // Set file offset to start of file
        unsigned long long currentOffset = 0ULL;
        
        // Read the data and append it to the file
        while (currentOffset < fileLength)
        {
            @autoreleasepool
            {
                [fileHandle seekToFileOffset:currentOffset];
                NSData *chunkOfData = [fileHandle readDataOfLength:kBase64EncodeChunkSize];
                [self appendFileWithString:[chunkOfData base64EncodedString]];
                currentOffset += chunkOfData.length;
            }
        }
        
        // Release the file handle
        [fileHandle closeFile];
    }
    else
    {
        AlfrescoLogDebug(@"Could not create a file handle for %@", self.filePath);
    }
    */
    [self appendFileWithString:@"</cmisra:base64></cmisra:content>"];
}

- (void)addEntryEndElements
{
    NSString *atomEntryXmlEnd = [NSString stringWithFormat:@""
                                 "<cmisra:object xmlns:cmis=\"http://docs.oasis-open.org/ns/cmis/core/200908/\">"
                                 "<cmis:properties>"
                                 "<cmis:propertyId propertyDefinitionId=\"cmis:objectTypeId\"><cmis:value>cmis:document</cmis:value></cmis:propertyId>"
                                 "</cmis:properties>"
                                 "</cmisra:object>"
                                 "<title>%@</title>"
                                 "</entry>",
                                 [self.filename gtm_stringBySanitizingAndEscapingForXML]];

    [self appendFileWithString:atomEntryXmlEnd];
}

- (void)appendFileWithString:(NSString *)string
{
    [self appendFileWithData:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)appendFileWithData:(NSData *)data
{
    if (self.internalFilePath == nil)
    {
        // Store the file in the temporary folder
        NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
        [formatter setDateFormat:@"yyyy-MM-dd'T'HH-mm-ss-Z'"];
        NSString *tempFilename = [NSString stringWithFormat:@"%@-%@", self.filename, [formatter stringFromDate:[NSDate date]]];
        [self setInternalFilePath:[NSTemporaryDirectory() stringByAppendingPathComponent:tempFilename]];
        
        BOOL fileCreated = [[NSFileManager defaultManager] createFileAtPath:self.internalFilePath
                                                                   contents:data
                                                                 attributes:nil];
        if (!fileCreated)
        {
            AlfrescoLogDebug(@"CMISUploadFileHTTPRequest ERROR: could not create file %@", self.internalFilePath);
        }
    }
    else
    {
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:self.internalFilePath];
        
        if (fileHandle)
        {
            [fileHandle seekToEndOfFile];
            [fileHandle writeData:data];
        }
        
        // Always clean up after the file is written to
        [fileHandle closeFile];
    }
}

@end
