//
//  SavedDocument.h
//  Alfresco
//
//  Created by Michael Muller on 10/7/09.
//  Copyright 2009 Zia Consulting. All rights reserved.
//

@interface SavedDocument : UIViewController {

}

+ (BOOL) isSaved: (NSString *) filename;
+ (BOOL) save: (NSString *) filename;
+ (void) unsave: (NSString *) filename;
+ (NSArray *) list;
+ (NSString *) mimeTypeForFilename: (NSString *) filename;
+ (NSString *) pathToTempFile: (NSString *) filename;
+ (NSString *) pathToSavedFile: (NSString *) filename;
+ (NSString *) sizeOfSavedFile: (NSString *) filename;

+ (NSString *)stringForLongFileSize:(long)size;
+ (NSString *)stringForUnsignedLongLongFileSize:(unsigned long long)size;

@end
