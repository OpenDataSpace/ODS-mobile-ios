//
//  FavoritesUploadManager.h
//  FreshDocs
//
//  Created by Mohamad Saeedi on 21/08/2012.
//  Copyright (c) 2012 . All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UploadsAbstractManager.h"

@interface FavoritesUploadManager : UploadsAbstractManager


// Static selector to access this class singleton instance
+ (id)sharedManager;

@end
