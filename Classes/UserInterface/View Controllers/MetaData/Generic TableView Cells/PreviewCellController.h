//
//  PreviewCellController.h
//  FreshDocs
//
//  Created by bdt on 3/10/14.
//
//

#import <Foundation/Foundation.h>
#import "IFCellController.h"
#import "IFCellModel.h"

@interface PreviewCellController : NSObject <IFCellController> {
    NSURL   *thumbnailURL_;
}

- (id) initWithThumbnailURL:(NSURL*) url;
@end
