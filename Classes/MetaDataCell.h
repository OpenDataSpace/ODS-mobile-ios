//
//  MetaDataCellView.h
//  FreshDocs
//
//  Created by Gi Hyun Lee on 7/18/11.
//  Copyright 2011 Zia Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface MetaDataCell : UIView {
    UILabel *metadataLabel;
    UILabel *metaDataValueText;
}

@property (nonatomic, retain) IBOutlet UILabel *metadataLabel;
@property (nonatomic, retain) IBOutlet UILabel *metaDataValueText;

@end
